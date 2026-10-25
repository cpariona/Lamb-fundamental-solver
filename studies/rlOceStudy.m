%% 1. Configure one reviewed condition (edit here, or supply study in the workspace).
% Initialize OCE PR #146's exact-identity recovery explicitly. No GUI is needed.
% Parameter values/bounds and physical support belong to this RL request.
if ~exist('study','var')
    study=struct('experimentRoot',"",'summaryFile',"",'experimentId',"", ...
        'subexperimentId',"",'sampleId',"",'mode',"QH",'period_us',"", ...
        'repetitions',["1","2","3"],'conditionId',"",'condition',struct(), ...
        'scanAxisIndex',1,'direction',"left",'estimator',"kf_ridge",'curve',"raw", ...
        'frequencySelection',"all",'frequency_Hz',[],'observationMask',[], ...
        'fitConfig',struct('branchName',"A0",'freeParams',"mu", ...
            'fixedParams',struct('rho',NaN,'thickness',NaN,'nu',NaN), ...
            'initialGuess',struct('mu',NaN),'bounds',struct('mu',[NaN NaN])), ...
        'review',struct('mode',"A0",'thicknessSource',"",'thicknessJustification',"", ...
            'densityReference',"",'parameterJustification',"",'modelSupportReference',""), ...
        'existingNativeResult',[],'existingAssembly',[],'resultFile',"", ...
        'reuseOnly',true,'saveResult',false,'showFigure',true, ...
        'graphicRequestedFrequency_Hz',[],'displayLabel',"",'displaySubtitle',"", ...
        'exportFigure',false,'figureFolder',"",'figureName',"");
end

%% 2. Recover, select and prepare original observations through the maintained owners.
projectRoot=fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);startup;addpath(fullfile(projectRoot,'studies'));
inputs=prepareOceStudyObservations(study);
assembly=inputs.assembly;observationReview=inputs.observationReview;
frequencySelectionMapping=inputs.frequencySelectionMapping;
graphicSamplingMapping=inputs.graphicSamplingMapping;
sourceMetadata=inputs.sourceMetadata;sourceFiles=inputs.sourceResultFiles;
inputHashes=inputs.inputHashes;experimental=assembly.experimental;

%% 3. Review the effective request and the fixed mask before any fitting.
% Keep DC, invalid/excluded rows and all repetitions in their original order.
% observationReview retains original source flags, bins and frequency mappings.
assert(isequal(experimental.validMask,observationReview.validMask));

%% 4. Review RL physics/configuration; do not import Plate coverage or equations.
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

%% 5. Reuse an identical native request/configuration; fit only with explicit opt-in.
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

%% 6. Persist the native result and current provenance without overwriting history.
if study.saveResult
    assert(strlength(study.resultFile)>0&&~isfile(study.resultFile),'lamb:study:OutputExists','Do not overwrite a historical result.');
    studyRecord=oceStudyProvenance(inputHashes.path,projectRoot);
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

%% 7. Render the retained native prediction/residuals; export editable FIG and 300-dpi TIF.
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
    provenance=struct('label',study.displayLabel,'displayLabel',study.displayLabel, ...
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
