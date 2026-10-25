%% 1. Configure one reviewed condition (edit here, or supply study in the workspace).
% This script coordinates existing owners; it is not a model dispatcher.
% Initialize the reviewed OCE src path explicitly before running this study.
% Recovery requires OCE PR #146's exact-identity contract (including legacy rejection).
if ~exist('study','var')
    study=struct('experimentRoot',"",'summaryFile',"",'experimentId',"", ...
        'subexperimentId',"",'sampleId',"",'mode',"QH",'period_us',"", ...
        'repetitions',["1","2","3"],'conditionId',"",'condition',struct(), ...
        'scanAxisIndex',1,'direction',"left",'estimator',"kf_ridge",'curve',"raw", ...
        'frequencySelection',"all",'frequency_Hz',[], ...
        'physical',struct('density_kgpm3',NaN,'thickness_m',NaN), ...
        'review',struct('mode',"A0",'thicknessPolicy',"explicit_constant_current_thickness", ...
            'thicknessSource',"",'thicknessJustification',"", ...
            'densityReference',"",'modelSupportReference',""), ...
        'fitOptions',struct(),'existingNativeResult',[],'existingAssembly',[], ...
        'resultFile',"",'reuseOnly',true,'saveResult',false, ...
        'showFigure',true,'graphicRequestedFrequency_Hz',[], ...
        'displayLabel',"",'displaySubtitle',"", ...
        'exportFigure',false,'figureFolder',"",'figureName',"");
end

%% 2. Recover, select and prepare original observations through the maintained owners.
projectRoot=fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);startup;addpath(fullfile(projectRoot,'studies'));
if ~isfield(study,'estimator'),study.estimator="kf_ridge";end
assert(study.estimator=="kf_ridge",'The reviewed Plate study uses k-f observations.');
inputs=prepareOceStudyObservations(study);
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
%% 3. Review physical inputs explicitly; one scalar policy for both acquisition modes.
physical=study.physical;review=study.review;fitOptions=study.fitOptions;
assert(review.mode=="A0"&&review.thicknessPolicy=="explicit_constant_current_thickness");
for name=["density_kgpm3","thickness_m"]
    validateattributes(physical.(name),{'double'},{'scalar','finite','real','positive'});
end
for name=["thicknessSource","thicknessJustification","densityReference","modelSupportReference"]
    assert(isscalar(string(review.(name)))&&strlength(strtrim(string(review.(name))))>0, ...
        'Physical inputs need explicit sources and justification.');
end
% OCT values remain observations; the study never silently selects another thickness.

%% 4. Reuse only an identical request; otherwise call the maintained Plate owner once.
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
if study.saveResult
    assert(strlength(study.resultFile)>0&&~isfile(study.resultFile),'lamb:study:OutputExists','Do not overwrite a historical result.');
    currentProvenance=oceStudyProvenance(inputHashes.path,projectRoot);
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

%% 5. Sample graphic bins independently and render the unchanged native result.
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
    provenance=struct('label',study.displayLabel,'displayLabel',study.displayLabel, ...
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
