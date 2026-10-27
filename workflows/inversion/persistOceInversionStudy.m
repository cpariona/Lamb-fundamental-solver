function studyRecord = persistOceInversionStudy(study, inputs, nativeResult, physics, review, reused, projectRoot, family)
%PERSISTOCEINVERSIONSTUDY Save full reviewed request with current source hashes.
studyRecord=struct();
if ~study.saveResult,return;end
assert(~isfile(study.resultFile), ...
    'lamb:study:OutputExists','Refusing to overwrite an existing inversion MAT.');
studyRecord=oceInversionProvenance(inputs.inputHashes.path,projectRoot);
assert(isequal(studyRecord.inputFiles,inputs.inputHashes), ...
    'lamb:study:InputsChanged','A source input changed since OCE recovery.');
% Portable manifest is relative to the experiment root. Keep unmodified
% native OCE lineage in assembly; it may contain producer-supplied references.
studyRecord.inputFiles.path=relativeSourcePaths( ...
    studyRecord.inputFiles.path,study.experimentRoot);
studyRecord.pathBase="experimentRoot";
studyRecord.code.Lamb=rmfield(studyRecord.code.Lamb,'root');
studyRecord.code.OCE=rmfield(studyRecord.code.OCE,'root');
names={'experimentId','subexperimentId','sampleId','excitationMode','period_us', ...
    'repetitions','conditionId','condition','scanAxisIndex','direction','estimator', ...
    'curve','fitFrequencySelection','fitFrequency_Hz','plotTargetFrequency_Hz'};
selection=struct();
for k=1:numel(names)
    name=names{k};
    if isfield(study,name),selection.(name)=study.(name);end
end
selection.summaryRelativeFile=study.resolvedSummaryRelativeFile;
selection.outputRelativeFolder=study.resolvedOutputRelativeFolder;
if isfield(study,'thicknessPolicy'),selection.thicknessPolicy=study.thicknessPolicy;end
if isfield(study,'thicknessReferenceSourceIndex')
    selection.thicknessReferenceSourceIndex=study.thicknessReferenceSourceIndex;
end
if study.excitationMode=="Pulse"&&study.showFigure
    selection.plotTargetFrequency_Hz= ...
        unique(inputs.graphicSamplingMapping.requestedFrequency_Hz,'stable');
end
studyRecord.selection=selection;
studyRecord.numericallyReused=reused;
studyRecord.modelFamily=string(family);
studyRecord.maskPolicy="source_quality_and_frequency";
if isfield(study,'observationMask')&&~isempty(study.observationMask)
    studyRecord.maskPolicy="explicit_observation_mask";
end
assembly=inputs.assembly;observationReview=inputs.observationReview;
frequencySelectionMapping=inputs.frequencySelectionMapping;
graphicSamplingMapping=inputs.graphicSamplingMapping;
if family=="RayleighLamb"
    fitConfig=physics;
else
    physical=physics;
end
folder=fileparts(study.resultFile);
if ~isfolder(folder),mkdir(folder);end
if family=="RayleighLamb"
    save(study.resultFile,'studyRecord','nativeResult','assembly','fitConfig','review', ...
        'observationReview','frequencySelectionMapping','graphicSamplingMapping','-v7.3');
else
    save(study.resultFile,'studyRecord','nativeResult','assembly','physical','review', ...
        'observationReview','frequencySelectionMapping','graphicSamplingMapping','-v7.3');
end
end

function relative=relativeSourcePaths(paths,root)
% Relativize input hashes only after verifying the on-disk source bytes.
root=replace(string(root),char(92),"/");
if endsWith(root,"/"),root=extractBefore(root,strlength(root));end
relative=replace(string(paths),char(92),"/");
prefix=root+"/";
for i=1:numel(relative)
    assert(startsWith(lower(relative(i)),lower(prefix)), ...
        'lamb:study:ExternalInputPath', ...
        'A source used for the inversion lies outside the experiment root.');
    relative(i)=extractAfter(relative(i),strlength(prefix));
    assert(strlength(relative(i))>0 && ...
        ~any(ismember(split(relative(i),"/"),["..","."])), ...
        'lamb:study:ExternalInputPath','Source reference cannot escape the experiment.');
end
end
