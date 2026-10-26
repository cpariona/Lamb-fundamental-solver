%% 1. USER CONFIGURATION
% Run each MATLAB Editor section in order. Change options here and rerun
% downstream sections; never average, repair or overwrite original OCE data.
oce_repository_root = ""; % Full local OCE_Workflow repository root
study = struct();
study.experimentRoot = ""; % Original experiment root
study.summaryFile = "";    % Full path to persisted experiment summary .mat
study.experimentId = "";
study.subexperimentId = "";
study.sampleId = "";
study.mode = "Pulse";      % "Pulse" | "QH"
study.period_us = "";      % Literal Pulse period, "" for QH
study.repetitions = ["1","2","3"];
study.conditionId = "";
study.condition = struct(); % e.g. struct('strain_percent', exactRecordedDouble)
study.scanAxisIndex = 1;
study.direction = "left";  % "left" | "right" along one principal scan axis
study.estimator = "kf_ridge";
study.curve = "raw";       % "raw" | "smoothed"
study.frequencySelection = "all"; % "all" | "interval" | "explicit"
study.frequency_Hz = [];  % Hz: [low high] or physical requested frequencies

% Reviewed physical inputs in SI units. Current FULL thickness and density
% must be justified independently; measured OCT thickness is not overwritten.
study.physical = struct('density_kgpm3', NaN, 'thickness_m', NaN);
study.review = struct( ...
    'mode', "A0", 'thicknessPolicy', "explicit_constant_current_thickness", ...
    'thicknessSource', "", 'thicknessJustification', "", ...
    'densityReference', "", 'modelSupportReference', "");
study.fitOptions = struct(); % Native Plate A0 options (not RL optimizer settings)

% Conservative defaults: review data/physics before enabling a fit.
study.reuseOnly = true;      % false explicitly enables native fitting
study.saveResult = false;
study.showFigure = false;
study.exportFigure = false;
study.resultFile = "";
study.existingNativeResult = [];
study.existingAssembly = [];
study.graphicRequestedFrequency_Hz = []; % Pulse presentation only
study.displayLabel = "";
study.displaySubtitle = "";
study.figureFolder = "";
study.figureName = "";

%% 2. INITIALIZE LAMB AND OCE (MATLAB Editor Run Section)
% MATLAB may run sections from Temp; resolve the real open Editor file.
workflow_file = string(matlab.desktop.editor.getActiveFilename);
[~, active_name, active_ext] = fileparts(char(workflow_file));
if ismissing(workflow_file) || strlength(workflow_file) == 0 || ...
        ~strcmpi(string(active_name) + string(active_ext), "run_ae_plate_oce_inversion.m")
    error('lamb:workflow:EditorFile', ...
        'Open run_ae_plate_oce_inversion.m in MATLAB Editor and run this section.');
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

%% 3. RECOVER AND REVIEW ORIGINAL OBSERVATIONS (no fitting)
% Source/condition/repetition identities and original rows are retained.
if ~isfield(study,'estimator'),study.estimator="kf_ridge";end
assert(study.estimator=="kf_ridge",'The reviewed Plate study uses k-f observations.');
inputs=prepareOceInversionObservations(study);
assembly=inputs.assembly;observationReview=inputs.observationReview;
frequencySelectionMapping=inputs.frequencySelectionMapping;
graphicSamplingMapping=inputs.graphicSamplingMapping;
sourceMetadata=inputs.sourceMetadata;sourceFiles=inputs.sourceResultFiles;
inputHashes=inputs.inputHashes;
experimental=assembly.experimental;
frequency=experimental.frequency_Hz;validMask=experimental.validMask;
sourceIndex=observationReview.sourceIndex;bins=observationReview.sourceBinIndex;
repetitionId=observationReview.repetitionId;ridge=observationReview.ridgeValid;
interpolated=observationReview.interpolated;extrapolated=observationReview.extrapolated;
graphicRequested=zeros(0,1);
if study.mode=="Pulse"&&study.showFigure
    graphicRequested=unique(graphicSamplingMapping.requestedFrequency_Hz,'stable');
end
disp(sourceMetadata);
disp(observationReview);
fprintf('Selected %d of %d original observations.\n', nnz(validMask), numel(validMask));
%% 4. REVIEW CURRENT PLATE PHYSICAL INPUTS
physical=study.physical;review=study.review;fitOptions=study.fitOptions;
assert(review.mode=="A0"&&review.thicknessPolicy=="explicit_constant_current_thickness");
for name=["density_kgpm3","thickness_m"]
    validateattributes(physical.(name),{'double'},{'scalar','finite','real','positive'});
end
for name=["thicknessSource","thicknessJustification","densityReference","modelSupportReference"]
    assert(isscalar(string(review.(name)))&&strlength(strtrim(string(review.(name))))>0, ...
        'Physical inputs need explicit sources and justification.');
end
% OCT values remain observations; the workflow never silently selects thickness.

%% 5. RUN OR REUSE THE NATIVE PLATE A0 FIT (explicit opt-in)
existing=study.existingNativeResult;existingAssembly=study.existingAssembly;
if isempty(existing)&&strlength(study.resultFile)>0&&isfile(study.resultFile)
    saved=load(study.resultFile,'nativeResult','assembly');
    existing=saved.nativeResult;existingAssembly=saved.assembly;
end
reusedResult=false;
if ~isempty(existing)
    if isempty(fieldnames(fitOptions)),fitOptions=existing.options;end
    same=isequaln(existing.physical,physical)&&isequaln(existing.options,fitOptions);
    for name=string(fieldnames(experimental))'
        same=same&&isfield(existing.experimental,name)&&isequaln(existing.experimental.(name),experimental.(name));
    end
    same=same&&~isempty(existingAssembly);
    if ~isempty(existingAssembly)
        if isfield(existingAssembly,'sourceResultFiles')
            recordedFiles=string(existingAssembly.sourceResultFiles(:));
        else
            recordedFiles=string({existingAssembly.lineage.resultFile})';
        end
        same=same&&isequal(recordedFiles,sourceFiles);
    end
    if study.mode=="QH"
        % Coverage is owned by fitOceQhPrestressedPlate. Reuse its recorded physical inputs,
        % never reconstruct a second grouping implementation in this script.
        same=same&&~isempty(existingAssembly)&& ...
            isequaln(existingAssembly.physicalFrequency_Hz,assembly.physicalFrequency_Hz)&& ...
            isequaln(existingAssembly.requestedTargetFrequency_Hz,assembly.requestedTargetFrequency_Hz);
    else
        same=same&&~isfield(existing.experimental,'independentFrequencyGroupId');
    end
    if same,nativeResult=existing;reusedResult=true;end
end
assert(reusedResult||~study.reuseOnly,'lamb:study:RequestMismatch', ...
    'No identical reviewed result is available. Inspect observationReview and physical inputs before enabling a new fit.');
if ~reusedResult
    if study.mode=="QH"
        outcome=fitOceQhPrestressedPlate(assembly,physical,review,fitOptions);
        nativeResult=outcome.nativeResult;
    else
        nativeResult=lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(experimental,physical,fitOptions);
    end
end
assert(isequal(nativeResult.validMask,validMask));
%% 6. OPTIONAL PERSISTENCE (no overwrite)
if study.saveResult
    assert(strlength(study.resultFile)>0&&~isfile(study.resultFile),'lamb:study:OutputExists','Do not overwrite a historical result.');
    currentProvenance=oceInversionProvenance(inputHashes.path,projectRoot);
    assert(isequal(currentProvenance.inputFiles,inputHashes), ...
        'lamb:study:InputsChanged','An OCE input changed after recovery; do not persist this study.');
    % Small configuration only: arrays, physical inputs and reviews already have owners below.
    selectionFields={'experimentRoot','summaryFile','experimentId','subexperimentId','sampleId', ...
        'mode','period_us','repetitions','conditionId','condition','scanAxisIndex','direction', ...
        'estimator','curve','frequencySelection','frequency_Hz','graphicRequestedFrequency_Hz'};
    effectiveSelection=struct();
    for field=selectionFields,effectiveSelection.(field{1})=study.(field{1});end
    if study.mode=="Pulse"&&study.showFigure
        effectiveSelection.graphicRequestedFrequency_Hz=graphicRequested;
    end
    studyRecord=currentProvenance;
    studyRecord.selection=effectiveSelection;
    studyRecord.numericallyReused=reusedResult;
    save(study.resultFile,'studyRecord','nativeResult','assembly','physical','review', ...
        'observationReview','frequencySelectionMapping','graphicSamplingMapping','-v7.3');
end

fprintf('AE Plate: %d selected rows; reused=%d; alpha=%.15g Pa; gamma=%.15g Pa; RMSE=%.15g Pa; numerical accepted=%d\n', ...
    nnz(validMask),reusedResult,nativeResult.alpha_Pa,nativeResult.gamma_Pa,nativeResult.regressionRMSE_Pa,nativeResult.accepted);

%% 7. OPTIONAL VISUALIZATION (FIG and 300-dpi TIF)
graphicFrequency=[];graphicMask=validMask;
if study.showFigure
    if study.mode=="Pulse"
        graphicFrequency=unique(graphicSamplingMapping.observedFrequency_Hz( ...
            isfinite(graphicSamplingMapping.observedFrequency_Hz)));
        graphicMask=validMask&ismember([sourceIndex,bins], ...
            [graphicSamplingMapping.sourceIndex,graphicSamplingMapping.sourceBinIndex],'rows');
        assert(isequal(validMask&ismember(frequency,graphicFrequency),graphicMask), ...
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
        'repetitionId',repetitionId,'sourceMasks',struct('valid_mask',ridge, ...
        'interpolated_mask',interpolated,'extrapolated_mask',extrapolated));
    [fig,figureEvidence]=plotAePlateFitDiagnostics(nativeResult,provenance, ...
        'DisplayMode',"robust",'DisplayFrequency_Hz',graphicFrequency,'Visible','on');
    drawnow;
    if study.exportFigure
        assert(isfolder(study.figureFolder)&&strlength(study.figureName)>0);
        figurePaths=saveInverseFigure(fig,study.figureFolder,study.figureName);
    end
end
