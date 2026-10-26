function result = executeOceInversionStudy(study, family, oceRepositoryRoot)
%EXECUTEOCEINVERSIONSTUDY Noninteractive, review-first RL or Plate study.
% Caller supplies all original condition/scan/estimator/band/model decisions.
% No frequency-band optimization, source-data edits or automatic refitting.
projectRoot=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(projectRoot);
startup;
addpath(fullfile(projectRoot,'workflows','inversion'),'-end');
assert(isfile(fullfile(oceRepositoryRoot,'src','+oce','+results', ...
    'recoverSummaryObservations.m')), ...
    'lamb:study:OceRepository','Supply a maintained OCE repository root.');
addpath(fullfile(oceRepositoryRoot,'src'),'-end');
family=string(family);
study=resolveOceInversionPaths(study,family);
% Fail before fitting if requested outputs already exist.
if study.saveResult
    assert(~isfile(study.resultFile),'lamb:study:OutputExists', ...
        'The result MAT already exists.');
end
if study.exportFigure
    assert(study.showFigure,'lamb:study:FigureExport','Enable figure generation for export.');
    assert(~isfile(fullfile(study.figureFolder,study.figureName+".fig"))&& ...
        ~isfile(fullfile(study.figureFolder,study.figureName+".tif")), ...
        'lamb:study:OutputExists','The figure destination already exists.');
end
inputs=prepareOceInversionObservations(study);
if family=="Plate"
    study.sourceMetadata=inputs.sourceMetadata;
end
[experimental,physics,review]=reviewOceInversionPhysics( ...
    study,inputs.assembly,inputs.observationReview,family);
inputs.assembly.experimental=experimental;
[nativeResult,reused,physics]=fitOceInversionNative(study,inputs.assembly, ...
    experimental,physics,review,inputs.sourceResultFiles,family);
studyRecord=persistOceInversionStudy( ...
    study,inputs,nativeResult,physics,review,reused,projectRoot,family);
[fig,figureEvidence,figurePaths]=renderOceInversionStudy( ...
    study,inputs,nativeResult,review,family);
result=struct('study',study,'experimental',experimental, ...
    'assembly',inputs.assembly,'observationReview',inputs.observationReview, ...
    'physics',physics,'review',review,'nativeResult',nativeResult, ...
    'reusedResult',reused,'studyRecord',studyRecord, ...
    'figure',fig,'figureEvidence',figureEvidence,'figurePaths',figurePaths);
end
