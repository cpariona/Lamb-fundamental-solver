function tests=test_oce_inversion_batch_contract()
%TEST_OCE_INVERSION_BATCH_CONTRACT Relative output, dry-run and model boundary.
tests=functiontests(localfunctions);
end

function testDefaultPathsAndRepeatResolution(testCase)
root=tempname;mkdir(root);cleanup=onCleanup(@()rmdir(root,'s'));
study=baseCase(root,"Stretch_1p00000");
one=resolveOceInversionPaths(study,"RayleighLamb");
verifyEqual(testCase,one.summaryFile,fullfile(root,"Results","Stretch_1p00000","summary.mat"));
verifyEqual(testCase,one.resultFile,fullfile(root,"Results","Stretch_1p00000", ...
    "Inversions","RayleighLamb","Pulse_320.01us_initial_axis1_left","inversion.mat"));
% Changing only subexperiment must not retain a stale auto-computed path.
one.subexperimentId="Stretch_1p10000";
two=resolveOceInversionPaths(one,"RayleighLamb");
verifyEqual(testCase,two.summaryFile,fullfile(root,"Results","Stretch_1p10000","summary.mat"));
verifySubstring(testCase,two.resultFile,"Stretch_1p10000");
verifyTrue(testCase,contains(two.resultFile,fullfile("Inversions","RayleighLamb")));
end

function testExplicitRelativeOverridesAndUnsafePaths(testCase)
root=tempname;mkdir(root);cleanup=onCleanup(@()rmdir(root,'s'));
study=baseCase(root,"Stretch_1p00000");
study.summaryRelativeFile=fullfile("Results","Reviewed","summary.mat");
study.outputRelativeFolder=fullfile("Studies","agent01","Plate");
one=resolveOceInversionPaths(study,"Plate");
verifyEqual(testCase,one.summaryFile,fullfile(root,study.summaryRelativeFile));
verifyEqual(testCase,one.resultFile,fullfile(root,study.outputRelativeFolder,"inversion.mat"));
for unsafe=["../outside","C:/outside","/outside","a/../b"]
    bad=study;bad.outputRelativeFolder=unsafe;
    verifyError(testCase,@()resolveOceInversionPaths(bad,"Plate"), ...
        'lamb:study:UnsafeOutputPath');
end
end

function testReadOnlyBatchPlansAndCollisionPreflight(testCase)
root=tempname;mkdir(root);cleanup=onCleanup(@()rmdir(root,'s'));
c=baseCase(root,"Stretch_1p00000");
plan=struct('experimentRoot',string(root),'oceRepositoryRoot',"unused_in_dry_run", ...
    'cases',c,'execute',false);
report=runOceInversionBatch(plan,"RayleighLamb");
verifyFalse(testCase,report.executed);
verifyEqual(testCase,report.report.status,"planned");
verifyFalse(testCase,isfolder(fileparts(report.report.resultFile(1))));
plan.cases=repmat(c,2,1);
verifyError(testCase,@()runOceInversionBatch(plan,"RayleighLamb"), ...
    'lamb:batch:DuplicateOutput');
plan.cases(2).outputTag="second_review";
report=runOceInversionBatch(plan,"RayleighLamb");
verifyEqual(testCase,height(report.report),2);
verifyEqual(testCase,numel(unique(report.report.resultFile)),2);
plate=runOceInversionBatch(plan,"Plate");
verifyTrue(testCase,all(contains(plate.report.resultFile,"Plate")));
end

function testLegacyRelativeSummarySurvivesBatchExecutionResolution(testCase)
root=tempname;mkdir(root);cleanup=onCleanup(@()rmdir(root,'s'));
c=baseCase(root,"Stretch_1p00000");
c.summaryFile=fullfile("Results","Reviewed","alternative_summary.mat");
plan=struct('experimentRoot',string(root),'oceRepositoryRoot',"unused", ...
    'cases',c,'execute',false);
reviewed=runOceInversionBatch(plan,"RayleighLamb");
first=reviewed.cases{1};
verifyEqual(testCase,string(first.resolvedSummaryRelativeFile),string(c.summaryFile));
reused=resolveOceInversionPaths(first,"RayleighLamb");
verifyEqual(testCase,reused.summaryFile,first.summaryFile);
verifyEqual(testCase,string(reused.resolvedSummaryRelativeFile),string(c.summaryFile));
first.subexperimentId="Stretch_1p10000";
changed=resolveOceInversionPaths(first,"RayleighLamb");
verifyEqual(testCase,changed.summaryFile, ...
    fullfile(root,"Results","Stretch_1p10000","summary.mat"));
end

function testPortableInversionManifestAndUntouchedNativePayload(testCase)
root=tempname;mkdir(root);cleanup=onCleanup(@()rmdir(root,'s'));
source=fullfile(root,"Results","Stretch_1p00000","summary.mat");
mkdir(fileparts(source));values=(1:5)';save(source,'values');
projectRoot=testRepositoryRoot(mfilename('fullpath'));
hashes=oceInversionProvenance(source,projectRoot);
study=resolveOceInversionPaths(baseCase(root,"Stretch_1p00000"),"Plate");
study.saveResult=true;study.showFigure=false;
inputs=struct('inputHashes',hashes.inputFiles,'assembly', ...
    struct('experimental',struct('frequency_Hz',1000,'Cp_mps',3, ...
    'validMask',true),'sourceResultFiles',string(source)), ...
    'observationReview',table(),'frequencySelectionMapping',table(), ...
    'graphicSamplingMapping',table());
nativeResult=struct('experimental',inputs.assembly.experimental, ...
    'sourceReference',string(source));
physical=struct('density_kgpm3',1050,'thickness_m',.0005);
review=struct('modelBranch',"A0");
record=persistOceInversionStudy(study,inputs,nativeResult,physical, ...
    review,false,projectRoot,"Plate");
verifyEqual(testCase,replace(record.inputFiles.path,char(92),"/"), ...
    "Results/Stretch_1p00000/summary.mat");
verifyEqual(testCase,record.pathBase,"experimentRoot");
verifyFalse(testCase,isfield(record.selection,'experimentRoot'));
verifyFalse(testCase,isfield(record.code.Lamb,'root'));
verifyFalse(testCase,isfield(record.code.OCE,'root'));
saved=load(study.resultFile,'studyRecord','nativeResult');
verifyEqual(testCase,saved.studyRecord,record);
verifyEqual(testCase,saved.nativeResult,nativeResult);
end

function testFailedBatchPersistsReviewedCaseWithoutMachinePaths(testCase)
root=tempname;mkdir(root);cleanup=onCleanup(@()rmdir(root,'s'));
c=baseCase(root,"Stretch_1p00000");
c.condition=struct('strain_percent',0);
c.physical=struct('density_kgpm3',1050,'thickness_m',.0005);
plan=struct('experimentRoot',string(root), ...
    'oceRepositoryRoot',"missing_OCE_checkout",'cases',c, ...
    'execute',true,'exportFigure',false,'saveResult',true, ...
    'continueOnError',true);
report=runOceInversionBatch(plan,"Plate");
verifyEqual(testCase,report.report.status,"failed");
verifyTrue(testCase,isfile(report.report.failureRecordFile));
saved=load(report.report.failureRecordFile,'failureRecord');
verifyEqual(testCase,saved.failureRecord.errorId,"lamb:study:OceRepository");
verifyEqual(testCase,saved.failureRecord.request.fitFrequency_Hz,c.fitFrequency_Hz);
verifyFalse(testCase,isfield(saved.failureRecord.request,'experimentRoot'));
verifyFalse(testCase,contains(string(saved.failureRecord.errorMessage),string(root)));
verifyError(testCase,@()runOceInversionBatch(plan,"Plate"), ...
    'lamb:study:OutputExists');
end

function testUnreviewedAllFrequenciesAreNotAutomated(testCase)
root=tempname;mkdir(root);cleanup=onCleanup(@()rmdir(root,'s'));
c=baseCase(root,"Stretch_1p00000");
c.fitFrequencySelection="all";c.fitFrequency_Hz=[];
plan=struct('experimentRoot',string(root),'oceRepositoryRoot',"unused", ...
    'cases',c,'execute',false);
verifyError(testCase,@()runOceInversionBatch(plan,"RayleighLamb"), ...
    'lamb:batch:BandReview');
plan.cases.fullBandReviewed=true;
planned=runOceInversionBatch(plan,"RayleighLamb");
verifyEqual(testCase,planned.report.status,"planned");
end

function testRlSharedFitDoesNotRequirePlateOptions(testCase)
p=lamb.models.rayleigh_lamb.rlDefaultParams();
study=struct('existingNativeResult',[],'existingAssembly',[], ...
    'resultFile',string(tempname)+".mat",'reuseOnly',true,'excitationMode',"Pulse", ...
    'estimator',"kf_ridge");
config=struct('branchName',"A0",'freeParams',"mu", ...
    'fixedParams',struct('rho',p.rho,'thickness',p.thickness,'nu',p.nu), ...
    'initialGuess',struct('mu',p.mu),'bounds',struct('mu',[20e3 200e3]));
experimental=struct('frequency_Hz',[1000;2000], ...
    'Cp_mps',[3;4],'validMask',true(2,1));
assembly=struct('experimental',experimental);
verifyError(testCase,@()fitOceInversionNative(study,assembly, ...
    experimental,config,struct(),strings(0,1),"RayleighLamb"), ...
    'lamb:study:RequestMismatch');
end

function testPlateUsesAllSelectedMeasuredThicknessRows(testCase)
source=baseCase("unused","Stretch_1p00000");
source.estimator="kf_ridge";
source.thicknessPolicy="oce_directional_per_acquisition";
source.physical=struct('density_kgpm3',1050,'thickness_m',NaN);
source.review=struct('modelBranch',"A0",'thicknessPolicy', ...
    "oce_directional_per_acquisition",'thicknessSource',"", ...
    'thicknessJustification',"",'densitySource',"Reviewed density", ...
    'modelAssumptionsJustification',"Exploratory A0 assumption");
data=struct('frequency_Hz',[1000;2000;3000;4000], ...
    'Cp_mps',[3;4;5;6],'validMask',logical([1;1;0;1]), ...
    'conditionId',"state1",'directionId',"axis1:left");
h=[.405;.406;NaN;.408]*1e-3;
assembly=struct('experimental',data,'measuredThickness_m',h);
obs=table([1;2;3;4],'VariableNames',{'sourceIndex'});
[exp,physical,review]=reviewOceInversionPhysics(source,assembly,obs,"Plate");
verifyEqual(testCase,exp.observationThickness_m,h);
verifyEqual(testCase,physical.thickness_m,h(1));
verifyEqual(testCase,review.thicknessPolicy,"oce_directional_per_acquisition");
native=lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion( ...
    exp,physical);
verifyEqual(testCase,native.experimental.observationThickness_m,h);
verifyEqual(testCase,native.wavenumberThickness(data.validMask), ...
    pi*data.frequency_Hz(data.validMask).*h(data.validMask)./ ...
    data.Cp_mps(data.validMask),'RelTol',1e-12);
assembly.measuredThickness_m(2)=NaN;
verifyError(testCase,@()reviewOceInversionPhysics(source,assembly,obs,"Plate"), ...
    'lamb:study:MissingThickness');
end

function testReviewedPlateReferenceIsOneDirectionMatchedMeasurement(testCase)
source=baseCase("unused","Stretch_1p00000");
source.estimator="kf_ridge";
source.thicknessPolicy="oce_reference_acquisition";
source.thicknessReferenceSourceIndex=2;
source.physical=struct('density_kgpm3',1050,'thickness_m',NaN);
source.review=struct('modelBranch',"A0",'thicknessPolicy', ...
    "explicit_constant_current_thickness",'thicknessSource',"", ...
    'thicknessJustification',"",'densitySource',"Reviewed density", ...
    'modelAssumptionsJustification',"Exploratory A0 assumption");
assembly=struct('experimental',struct('frequency_Hz',[1000;2000;3000], ...
    'Cp_mps',[3;4;5],'validMask',true(3,1), ...
    'conditionId',"state1",'directionId',"scan_axis_1:left"), ...
    'measuredThickness_m',[.405;.406;.407]*1e-3);
obs=table([1;2;3],'VariableNames',{'sourceIndex'});
[exp,physical,review]=reviewOceInversionPhysics(source,assembly,obs,"Plate");
verifyEqual(testCase,physical.thickness_m,assembly.measuredThickness_m(2));
verifyEqual(testCase,exp,assembly.experimental);
verifyEqual(testCase,review.thicknessPolicy,"explicit_constant_current_thickness");
verifySubstring(testCase,review.thicknessSource,"source index 2");
source.thicknessReferenceSourceIndex=4;
verifyError(testCase,@()reviewOceInversionPhysics(source,assembly,obs,"Plate"), ...
    'lamb:study:ThicknessReference');
end

function c=baseCase(root,sub)
c=struct('experimentRoot',string(root),'subexperimentId',string(sub), ...
    'excitationMode',"Pulse",'period_us',"320.01",'conditionId',"initial", ...
    'scanAxisIndex',1,'direction',"left",'summaryFile',"", ...
    'outputRelativeFolder',"",'outputTag',"", ...
    'fitFrequencySelection',"interval",'fitFrequency_Hz',[500 2000]);
end

function testWindowsTrailingDotAliasesAreRejected(testCase)
root=tempname;mkdir(root);cleanup=onCleanup(@()rmdir(root,'s'));
c=baseCase(root,"Stretch_1p00000");
c.outputTag="review.";
verifyError(testCase,@()resolveOceInversionPaths(c,"Plate"), ...
    'lamb:study:UnsafeOutputPath');
c.outputTag="review";c.outputRelativeFolder="Results/review./Plate";
verifyError(testCase,@()resolveOceInversionPaths(c,"Plate"), ...
    'lamb:study:UnsafeOutputPath');
end

function testExportFailureRetainsFitAndContinuesBatch(testCase)
[root,oceRoot,cleanup]=presentationFailureFixture(); %#ok<ASGLU>
c=baseCase(root,"Stretch_1p00000");
c.excitationMode="QH";c.period_us="";
c.physical=struct('density_kgpm3',1050,'thickness_m',.0005);
c.review=struct('modelBranch',"A0");
c.condition=struct('strain_percent',0);
c.sampleId="fixture";
second=c;second.conditionId="next";
plan=struct('experimentRoot',string(root),'oceRepositoryRoot',string(oceRoot), ...
    'cases',[c,second],'execute',true,'exportFigure',true,'saveResult',true, ...
    'continueOnError',true);
batch=runOceInversionBatch(plan,"Plate");
verifyEqual(testCase,batch.report.status,["partial";"completed"]);
verifyEqual(testCase,batch.report.selectedObservations,[2;2]);
verifyEqual(testCase,batch.report.nativeRMSE,[12;12]);
verifyEqual(testCase,batch.results{1}.completedThrough,"persistence");
verifyTrue(testCase,isfile(batch.report.resultFile(1)));
saved=load(batch.report.resultFile(1),'nativeResult');
verifyEqual(testCase,batch.results{1}.nativeResult,saved.nativeResult);
failure=load(batch.report.failureRecordFile(1),'failureRecord');
verifyEqual(testCase,failure.failureRecord.completedThrough,"persistence");
verifyEqual(testCase,failure.failureRecord.nativeResultRelativeFile, ...
    fullfile(batch.cases{1}.resolvedOutputRelativeFolder,"inversion.mat"));
verifyEqual(testCase,failure.failureRecord.errorId,"lamb:test:ExportFailure");
verifyError(testCase,@()runOceInversionBatch(plan,"Plate"), ...
    'lamb:study:OutputExists');
% The ordinary one-output API and stop-on-error batch still throw the error.
single=batch.cases{1};single.outputTag="single";
verifyError(testCase,@()executeOceInversionStudy(single,"Plate",oceRoot), ...
    'lamb:test:ExportFailure');
plan.cases=c;plan.cases.outputTag="stop";plan.continueOnError=false;
verifyError(testCase,@()runOceInversionBatch(plan,"Plate"), ...
    'lamb:test:ExportFailure');
end

function testPersistenceFailureRetainsNativeWithoutClaimingSavedMat(testCase)
[root,oceRoot,cleanup]=presentationFailureFixture(); %#ok<ASGLU>
c=baseCase(root,"Stretch_1p00000");c.excitationMode="QH";c.period_us="";
c.conditionId="persistence_failure";
c.physical=struct('density_kgpm3',1050,'thickness_m',.0005);
c.review=struct('modelBranch',"A0");
plan=struct('experimentRoot',string(root),'oceRepositoryRoot',string(oceRoot), ...
    'cases',c,'execute',true,'exportFigure',false,'saveResult',true, ...
    'continueOnError',true);
batch=runOceInversionBatch(plan,"Plate");
verifyEqual(testCase,batch.report.status,"partial");
verifyEqual(testCase,batch.results{1}.completedThrough,"fit");
verifyEqual(testCase,batch.report.nativeRMSE,12);
verifyFalse(testCase,isfile(batch.report.resultFile));
saved=load(batch.report.failureRecordFile,'failureRecord');
verifyEqual(testCase,saved.failureRecord.completedThrough,"fit");
verifyEqual(testCase,saved.failureRecord.nativeResultRelativeFile,"");
verifyEqual(testCase,saved.failureRecord.errorId,"lamb:study:InputsChanged");
end

function [root,oceRoot,cleanup]=presentationFailureFixture()
% Replace external/scientific collaborators only; exercise actual workflow
% execution, provenance persistence, error reporting and continuation.
root=tempname;mkdir(root);mock=fullfile(root,'mocks');mkdir(mock);
oceRoot=fullfile(root,'oce');
oceFolder=fullfile(oceRoot,'src','+oce','+results');mkdir(oceFolder);
writeFixtureFunction(fullfile(oceFolder,'recoverSummaryObservations.m'), ...
    ["function value=recoverSummaryObservations(varargin)","value=[];","end"]);
writeFixtureFunction(fullfile(mock,'prepareOceInversionObservations.m'),[ ...
    "function inputs=prepareOceInversionObservations(study)", ...
    "hashes=oceInversionProvenance(study.summaryFile,fileparts(which('startup')));", ...
    "data=struct('frequency_Hz',[1000;2000],'Cp_mps',[3;4],'validMask',true(2,1));", ...
    "inputs=struct('inputHashes',hashes.inputFiles,'assembly',struct('experimental',data), ...", ...
    "'observationReview',table(),'frequencySelectionMapping',table(), ...", ...
    "'graphicSamplingMapping',table(),'sourceResultFiles',string(study.summaryFile));", ...
    "if study.conditionId==""persistence_failure"",inputs.inputHashes.sha256(:)=""changed"";end", ...
    "end"]);
writeFixtureFunction(fullfile(mock,'reviewOceInversionPhysics.m'),[ ...
    "function [data,physics,review]=reviewOceInversionPhysics(study,assembly,varargin)", ...
    "data=assembly.experimental;physics=study.physical;review=study.review;", "end"]);
writeFixtureFunction(fullfile(mock,'fitOceInversionNative.m'),[ ...
    "function [native,reused,physics]=fitOceInversionNative(study,assembly,data,physics,varargin)", ...
    "native=struct('validMask',data.validMask,'regressionRMSE_Pa',12,'accepted',false);", ...
    "reused=false;", "end"]);
writeFixtureFunction(fullfile(mock,'renderOceInversionStudy.m'),[ ...
    "function [fig,evidence,paths]=renderOceInversionStudy(study,varargin)", ...
    "if study.conditionId==""initial"",error('lamb:test:ExportFailure','Injected export failure');end", ...
    "fig=[];evidence=struct();paths=struct();", "end"]);
folder=fullfile(root,'Results','Stretch_1p00000');mkdir(folder);
value=1;save(fullfile(folder,'summary.mat'),'value');
oldPath=path;addpath(mock,'-begin');
cleanup=onCleanup(@()cleanupPresentationFixture(oldPath,root));
end

function writeFixtureFunction(file,lines)
fid=fopen(file,'w');cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',lines);
end

function cleanupPresentationFixture(oldPath,root)
path(oldPath);
rmdir(root,'s');
end
