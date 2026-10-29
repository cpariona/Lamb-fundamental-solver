function [result, executionError, recovery] = executeOceInversionStudy(study, family, oceRepositoryRoot, recovery)
%EXECUTEOCEINVERSIONSTUDY Noninteractive, review-first RL or Plate study.
% Caller supplies all original condition/scan/estimator/band/model decisions.
% No frequency-band optimization, source-data edits or automatic refitting.
% An optional second output retains a completed fit if persistence or
% presentation fails. One-output callers retain the throwing behavior.
% A fourth argument or third output enables caller-scoped shared OCE recovery.
shareRecovery=nargin>3 || nargout>2;
if nargin<4,recovery=[];end
executionError=[];
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
    assert(study.reuseOnly || ~isfile(study.resultFile),'lamb:study:OutputExists', ...
        'The result MAT already exists.');
end
if study.exportFigure
    assert(study.showFigure,'lamb:study:FigureExport','Enable figure generation for export.');
    assert(~isfile(fullfile(study.figureFolder,study.figureName+".fig"))&& ...
        ~isfile(fullfile(study.figureFolder,study.figureName+".tif")), ...
        'lamb:study:OutputExists','The figure destination already exists.');
end
if shareRecovery
    [inputs,recovery]=prepareOceInversionObservations(study,recovery);
else
    inputs=prepareOceInversionObservations(study);
end
[experimental,physics,review]=reviewOceInversionPhysics( ...
    study,inputs.assembly,inputs.observationReview,family);
inputs.assembly.experimental=experimental;
[nativeResult,reused,physics]=fitOceInversionNative(study,inputs.assembly, ...
    experimental,physics,review,inputs.sourceResultFiles,family);
result=struct('study',study,'experimental',experimental, ...
    'assembly',inputs.assembly,'observationReview',inputs.observationReview, ...
    'physics',physics,'review',review,'nativeResult',nativeResult, ...
    'reusedResult',reused,'studyRecord',struct(), ...
    'figure',[],'figureEvidence',struct(),'figurePaths',struct(), ...
    'completedThrough',"fit");
try
    result.studyRecord=persistOceInversionStudy( ...
        study,inputs,nativeResult,physics,review,reused,projectRoot,family);
    result.completedThrough="persistence";
    [result.figure,result.figureEvidence,result.figurePaths]=renderOceInversionStudy( ...
        study,inputs,nativeResult,review,family);
    result.completedThrough="presentation";
catch exception
    if nargout<2,rethrow(exception);end
    executionError=exception;
end
end
