%% 1. USER CONFIGURATION
% Run each MATLAB Editor section in order. Re-run downstream sections when
% changing an upstream selection. Original OCE observations are never edited.
% Supply literal IDs and exact numeric condition values from the acquisition log.
oce_repository_root = "";  % Full path to OCE_Workflow (not its src folder)
study = struct();
study.experimentRoot = "";  % Experiment root with original Data/ and Results/
study.summaryFile = "";     % Full path to persisted experiment summary .mat
study.experimentId = "";
study.subexperimentId = "";
study.sampleId = "";
study.mode = "Pulse";       % "Pulse" | "QH"
study.period_us = "";       % Literal saved Pulse period; "" for QH
study.repetitions = ["1","2","3"];
study.conditionId = "";     % Reviewed condition label; not inferred from folder
study.condition = struct(); % e.g. struct('strain_percent', exactRecordedDouble)
study.scanAxisIndex = 1;
study.direction = "left";   % "left" | "right" along scan axis
study.estimator = "kf_ridge"; % QH may use recorded "phase_gradient"
study.curve = "raw";        % k-f: "raw" | "smoothed"
study.frequencySelection = "all"; % "all" | "interval" | "explicit"
study.frequency_Hz = [];   % [low high] for interval; nominal Hz for explicit
study.observationMask = []; % [] retains documented source-quality selection

% Rayleigh-Lamb native physical configuration (SI units).
% Enter reviewed current full thickness (m), density (kg/m^3) and nu.
% These NaN placeholders must be replaced before the model-review section.
study.fitConfig = struct( ...
    'branchName', "A0", 'freeParams', "mu", ...
    'fixedParams', struct('rho', NaN, 'thickness', NaN, 'nu', NaN), ...
    'initialGuess', struct('mu', NaN), ...
    'bounds', struct('mu', [NaN NaN]));
study.review = struct( ...
    'mode', "A0", ...
    'thicknessSource', "", 'thicknessJustification', "", ...
    'densityReference', "", 'parameterJustification', "", ...
    'modelSupportReference', "");

% Keep fitting and file writes off until data and physics have been reviewed.
study.reuseOnly = true;      % false explicitly enables a new native fit
study.saveResult = false;
study.showFigure = false;
study.exportFigure = false;
study.resultFile = "";
study.existingNativeResult = [];
study.existingAssembly = [];
study.graphicRequestedFrequency_Hz = []; % Pulse plot only; not fitting mask
study.displayLabel = "";
study.displaySubtitle = "";
study.figureFolder = "";
study.figureName = "";

%% 2. INITIALIZE LAMB AND OCE (MATLAB Editor Run Section)
% Run Section may use a temporary MATLAB file; never use mfilename here.
workflow_file = string(matlab.desktop.editor.getActiveFilename);
[~, active_name, active_ext] = fileparts(char(workflow_file));
if ismissing(workflow_file) || strlength(workflow_file) == 0 || ...
        ~strcmpi(string(active_name) + string(active_ext), "run_rl_oce_inversion.m")
    error('lamb:workflow:EditorFile', ...
        'Open run_rl_oce_inversion.m in MATLAB Editor and run this section.');
end
projectRoot = fileparts(fileparts(fileparts(char(workflow_file))));
assert(isfile(fullfile(projectRoot, 'startup.m')), ...
    'lamb:workflow:RepositoryRoot', 'Lamb startup.m was not found.');
addpath(projectRoot);
startup;
addpath(fullfile(projectRoot, 'workflows', 'inversion'), '-end');
assert(strlength(string(oce_repository_root)) > 0 && ...
    isfile(fullfile(oce_repository_root, 'src', '+oce', '+results', ...
    'recoverSummaryObservations.m')), 'lamb:workflow:OceRepository', ...
    'Set oce_repository_root to the maintained local OCE_Workflow root.');
addpath(fullfile(oce_repository_root, 'src'), '-end');
assert(~isempty(which('oce.results.recoverSummaryObservations')), ...
    'lamb:workflow:OceRecovery', 'OCE recovery API is not accessible.');
assert(~isempty(which('prepareOceInversionObservations')), ...
    'lamb:workflow:PreparationPath', 'Workflow preparation is not accessible.');

%% 3. RECOVER ORIGINAL OBSERVATIONS (no fitting)
% Section 1 must contain a real summary path, exact IDs, and a nonempty
% condition. OCE owns all MAT/schema validation and source recovery.
inputs=prepareOceInversionObservations(study);
assembly=inputs.assembly;observationReview=inputs.observationReview;
frequencySelectionMapping=inputs.frequencySelectionMapping;
graphicSamplingMapping=inputs.graphicSamplingMapping;
sourceMetadata=inputs.sourceMetadata;sourceFiles=inputs.sourceResultFiles;
inputHashes=inputs.inputHashes;experimental=assembly.experimental;

%% 4. REVIEW OBSERVATIONS (no fitting)
% Keep DC, invalid/excluded rows and all repetitions in their original order.
% observationReview retains original source flags, bins and frequency mappings.
assert(isequal(experimental.validMask,observationReview.validMask));
disp(sourceMetadata);
disp(observationReview);
fprintf('Selected %d of %d original observations.\n', ...
    nnz(experimental.validMask), numel(experimental.validMask));

%% 5. REVIEW RAYLEIGH-LAMB PHYSICS AND CONFIGURATION
fitConfig=study.fitConfig;review=study.review;
assert(any(string(fitConfig.branchName)==["A0","S0"])&&review.mode==fitConfig.branchName);
for name=["thicknessSource","thicknessJustification","densityReference", ...
        "parameterJustification","modelSupportReference"]
    assert(isscalar(string(review.(name)))&&strlength(strtrim(string(review.(name))))>0, ...
        'RL physical inputs, free/fixed choices and model assumptions require explicit review.');
end
% Building a native problem validates/resolves defaults, but performs no forward
% solve or optimization. Compare its value fields, never function handles.
problem=lamb.fitting.rayleigh_lamb.rlBuildFitProblem(experimental,fitConfig);
effectiveProblem=rmfield(problem,{'evaluateModel','residualFunction','objectiveFunction'});

%% 6. RUN OR REUSE THE NATIVE INVERSE FIT (explicit opt-in)
existing=study.existingNativeResult;existingAssembly=study.existingAssembly;
if isempty(existing)&&strlength(study.resultFile)>0&&isfile(study.resultFile)
    saved=load(study.resultFile,'nativeResult','assembly');
    existing=saved.nativeResult;existingAssembly=saved.assembly;
end
reusedResult=false;
if ~isempty(existing)&&~isempty(existingAssembly)
    same=string(existing.modelFamily)=="rayleigh_lamb"&&isequaln(existing.problem,effectiveProblem);
    if isfield(existingAssembly,'sourceResultFiles')
        recordedFiles=string(existingAssembly.sourceResultFiles(:));
    else
        recordedFiles=string({existingAssembly.lineage.resultFile})';
    end
    same=same&&isequal(recordedFiles,sourceFiles);
    if study.mode=="QH"&&study.estimator=="kf_ridge"
        same=same&&isequaln(existingAssembly.physicalFrequency_Hz,assembly.physicalFrequency_Hz)&& ...
            isequaln(existingAssembly.requestedTargetFrequency_Hz,assembly.requestedTargetFrequency_Hz)&& ...
            isequal([existingAssembly.lineage.binIndex],[assembly.lineage.binIndex]);
    end
    if same,nativeResult=existing;reusedResult=true;end
end
assert(reusedResult||~study.reuseOnly,'lamb:study:RequestMismatch', ...
    'No identical reviewed RL result is available. Inspect the fixed mask/configuration before enabling a fit.');
if ~reusedResult
    nativeResult=lamb.fitting.rayleigh_lamb.rlFitDispersionData(experimental,fitConfig);
end
assert(isequal(nativeResult.validMask,experimental.validMask));
assert(isequaln(nativeResult.frequency_Hz,experimental.frequency_Hz)&& ...
    isequaln(nativeResult.Cp_exp_mps,experimental.Cp_mps));

%% 7. OPTIONAL PERSISTENCE (no overwrite)
if study.saveResult
    assert(strlength(study.resultFile)>0&&~isfile(study.resultFile),'lamb:study:OutputExists','Do not overwrite a historical result.');
    studyRecord=oceInversionProvenance(inputHashes.path,projectRoot);
    assert(isequal(studyRecord.inputFiles,inputHashes), ...
        'lamb:study:InputsChanged','An OCE input changed after recovery; do not persist this study.');
    selectionFields={'experimentRoot','summaryFile','experimentId','subexperimentId','sampleId', ...
        'mode','period_us','repetitions','conditionId','condition','scanAxisIndex','direction', ...
        'estimator','curve','frequencySelection','frequency_Hz','graphicRequestedFrequency_Hz'};
    effectiveSelection=struct();
    for field=selectionFields,effectiveSelection.(field{1})=study.(field{1});end
    if study.mode=="Pulse"&&study.showFigure
        effectiveSelection.graphicRequestedFrequency_Hz=unique(graphicSamplingMapping.requestedFrequency_Hz,'stable');
    end
    studyRecord.selection=effectiveSelection;studyRecord.numericallyReused=reusedResult;
    studyRecord.maskPolicy="source_quality_and_frequency";
    if ~isempty(study.observationMask),studyRecord.maskPolicy="explicit_observation_mask";end
    save(study.resultFile,'studyRecord','nativeResult','assembly','fitConfig','review', ...
        'observationReview','frequencySelectionMapping','graphicSamplingMapping','-v7.3');
end
fprintf('RL %s: %d / %d selected rows; reused=%d; RMSE=%.15g m/s; optimizer exit=%d\n', ...
    nativeResult.branchName,nnz(nativeResult.validMask),numel(nativeResult.validMask), ...
    reusedResult,nativeResult.metrics.RMSE,nativeResult.optimizer.exitFlag);

%% 8. OPTIONAL VISUALIZATION (FIG and 300-dpi TIF)
if study.showFigure
    graphicFrequency=[];
    if study.mode=="Pulse"
        graphicFrequency=unique(graphicSamplingMapping.observedFrequency_Hz( ...
            isfinite(graphicSamplingMapping.observedFrequency_Hz)));
        graphicMask=experimental.validMask&ismember( ...
            [observationReview.sourceIndex,observationReview.sourceBinIndex], ...
            [graphicSamplingMapping.sourceIndex,graphicSamplingMapping.sourceBinIndex],'rows');
        assert(isequal(experimental.validMask&ismember(experimental.frequency_Hz,graphicFrequency),graphicMask), ...
            'Graphic frequencies collide across different source grids; review the selected original bins.');
    end
    reference=string(study.resultFile);if strlength(reference)==0,reference="Reviewed in-memory native request";end
    % Derive only presentation text from the reviewed source identity.
    % Never infer material, mechanical state or physical fit parameters here.
    plotLabel = string(study.displayLabel);
    if strlength(strtrim(plotLabel)) == 0
        plotLabel = string(study.sampleId) + " | " + ...
            string(study.subexperimentId) + " | axis " + ...
            string(study.scanAxisIndex) + " " + string(study.direction);
    end
    provenance=struct('label',plotLabel,'displayLabel',plotLabel, ...
        'displaySubtitle',study.displaySubtitle,'material',string(sourceMetadata.material(1)), ...
        'sourceReference',reference,'originalResultReferences',sourceFiles, ...
        'modelSupportReference',review.modelSupportReference,'physicalReview',review, ...
        'repetitionId',observationReview.repetitionId);
    [fig,figureEvidence]=plotRlFitDiagnostics(nativeResult,provenance, ...
        'DisplayFrequency_Hz',graphicFrequency,'Visible','on');
    drawnow;
    if study.exportFigure
        assert(isfolder(study.figureFolder)&&strlength(study.figureName)>0);
        figurePaths=saveInverseFigure(fig,study.figureFolder,study.figureName);
    end
end
