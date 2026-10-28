function tests=test_oce_inversion_batch_contract()
%TEST_OCE_INVERSION_BATCH_CONTRACT Relative output, dry-run and model boundary.
tests=functiontests(localfunctions);
end

function testManualFullBandRequiresExplicitApproval(testCase)
study=struct('excitationMode',"Pulse",'fitFrequencySelection',"all");
verifyError(testCase,@()prepareOceInversionObservations(study), ...
    'lamb:study:BandReview');
study.fullBandReviewed=false;
verifyError(testCase,@()prepareOceInversionObservations(study), ...
    'lamb:study:BandReview');
end

function testRecordedConditionIdentityDoesNotCollideUnderSanitization(testCase)
keys = "strain_percent";
plus = struct('strain_percent',"1.5e+01");
minus = struct('strain_percent',"1.5e-01");
left = oceInversionConditionId(keys,plus);
right = oceInversionConditionId(keys,minus);
verifyNotEqual(testCase,left,right);
verifyEqual(testCase,left,oceInversionConditionId(keys,plus));
verifyTrue(testCase,~isempty(regexp(char(left),'^[A-Za-z0-9_.-]+$','once')));
verifyNotEqual(testCase,oceInversionConditionId(keys,struct('strain_percent',1)), ...
    oceInversionConditionId(keys,struct('strain_percent',"1")));
% Human-readable labels are compact but the fingerprint uses exact doubles.
precise=struct('strain_percent',3.442622950819671);
close=struct('strain_percent',3.442622950819672);
first=oceInversionConditionId(keys,precise);
second=oceInversionConditionId(keys,close);
verifyNotEmpty(testCase,regexp(char(first),'^Strain_3_44pct_[0-9a-f]{8}$','once'));
verifyNotEmpty(testCase,regexp(char(second),'^Strain_3_44pct_[0-9a-f]{8}$','once'));
verifyNotEqual(testCase,first,second);
verifyEqual(testCase,first,oceInversionConditionId(keys,precise));
% Numeric text is also shortened for display; its original type and literal
% remain part of the fingerprint and are not converted for fitting.
textual=oceInversionConditionId(keys,struct('strain_percent',"3.442622950819671"));
verifyNotEmpty(testCase,regexp(char(textual),'^Strain_3_44pct_[0-9a-f]{8}$','once'));
verifyNotEqual(testCase,textual,first);
% Scientific-notation text is numerically 34.426..., not 3.4426%.
scientific=oceInversionConditionId(keys, ...
    struct('strain_percent',"3.44262295081967196e+01"));
verifyEqual(testCase,scientific,"Strain_34_43pct_3f36dc51");
asDouble=oceInversionConditionId(keys, ...
    struct('strain_percent',34.42622950819672));
verifyTrue(testCase,startsWith(asDouble,"Strain_34_43pct_"));
verifyNotEqual(testCase,asDouble,scientific);
for raw=[0,20,10.5,10.50]
    label=oceInversionConditionId(keys,struct('strain_percent',raw));
    shown=string(sprintf('%.2f',raw));
    shown=regexprep(regexprep(shown,'0+$',''),'\.$','');
    expected="Strain_"+replace(shown,".","_")+"pct_";
    verifyTrue(testCase,startsWith(label,expected));
end
verifyError(testCase,@()oceInversionConditionId(keys,struct('other',"1")), ...
    'lamb:study:ConditionIdentity');
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

function testBatchExternalInversionLayoutAndSingleCompatibility(testCase)
parent=tempname;mkdir(parent);cleanup=onCleanup(@()rmdir(parent,'s'));
container=fullfile(parent,"MyResearchData");mkdir(container);
experimentsRoot=fullfile(container,"OCE_Experiments");mkdir(experimentsRoot);
root=fullfile(experimentsRoot,"Experiment_A");mkdir(root);
caseStudy=baseCase(root,"Stretch_1p00000");
% Manual single remains inside its original OCE Results tree.
single=resolveOceInversionPaths(caseStudy,"Plate");
verifyEqual(testCase,single.resultFile,fullfile(root,"Results", ...
    "Stretch_1p00000","Inversions","Plate", ...
    "Pulse_320.01us_initial_axis1_left","inversion.mat"));

plan=struct('experimentRoot',string(root),'oceRepositoryRoot',"unused", ...
    'cases',caseStudy,'execute',false);
for family=["RayleighLamb","Plate"]
    batch=runOceInversionBatch(plan,family);
    expected=fullfile(container,"OCE_Inversions","Experiment_A", ...
        "Stretch_1p00000",family, ...
        "Pulse_320.01us_initial_axis1_left","inversion.mat");
    verifyEqual(testCase,batch.report.resultFile(1),string(expected));
    verifyEqual(testCase,batch.cases{1}.resolvedOutputBase,"inversionsRoot");
    verifyFalse(testCase,isfolder(fullfile(container,"OCE_Inversions")), ...
        'Dry-run must not create inversion directories.');
end
% Never infer a default from an experiment outside OCE_Experiments.
standalone=fullfile(parent,"StandaloneExperiment");mkdir(standalone);
nonstandard=plan;nonstandard.experimentRoot=string(standalone);
verifyError(testCase,@()runOceInversionBatch(nonstandard,"Plate"), ...
    'lamb:batch:InversionsRoot');
nonstandard.inversionsRoot=fullfile(parent,"Reviewed_Inversions");
explicit=runOceInversionBatch(nonstandard,"Plate");
verifyEqual(testCase,explicit.report.resultFile(1),string(fullfile( ...
    parent,"Reviewed_Inversions","StandaloneExperiment","Stretch_1p00000", ...
    "Plate","Pulse_320.01us_initial_axis1_left","inversion.mat")));
% A supplied root changes only output storage; OCE inputs stay unchanged.
plan.inversionsRoot=fullfile(parent,"Reviewed_Inversions");
plan.cases.outputTag="band_1";
custom=runOceInversionBatch(plan,"Plate");
verifyEqual(testCase,custom.cases{1}.summaryFile, ...
    fullfile(root,"Results","Stretch_1p00000","summary.mat"));
verifyEqual(testCase,custom.report.resultFile(1),string(fullfile( ...
    parent,"Reviewed_Inversions","Experiment_A", ...
    "Stretch_1p00000","Plate","band_1","inversion.mat")));

plan.cases.outputRelativeFolder=fullfile("Experiment_A","reviewed","Plate","custom");
overridden=runOceInversionBatch(plan,"Plate");
verifyEqual(testCase,overridden.report.resultFile(1),string(fullfile( ...
    parent,"Reviewed_Inversions","Experiment_A","reviewed", ...
    "Plate","custom","inversion.mat")));
plan.cases.outputRelativeFolder="../unsafe";
verifyError(testCase,@()runOceInversionBatch(plan,"Plate"), ...
    'lamb:study:UnsafeOutputPath');

plan.inversionsRoot="relative/path";
verifyError(testCase,@()runOceInversionBatch(plan,"Plate"), ...
    'lamb:study:InversionsRoot');
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
    'cases',c,'execute',false, ...
    'inversionsRoot',fullfile(root,"DryRun_Inversions"));
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
    'cases',c,'execute',false, ...
    'inversionsRoot',fullfile(root,"DryRun_Inversions"));
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
projectRoot=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
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
review=struct('modelBranch',"A0", ...
    'modelAssumptionsJustification',"Synthetic A0 review");
study.fullBandReviewed=true;
record=persistOceInversionStudy(study,inputs,nativeResult,physical, ...
    review,false,projectRoot,"Plate");
verifyEqual(testCase,replace(record.inputFiles.path,char(92),"/"), ...
    "Results/Stretch_1p00000/summary.mat");
verifyEqual(testCase,record.pathBase,"experimentRoot");
verifyTrue(testCase,record.selection.fullBandReviewed);
% A second invocation must reuse the saved MAT without changing its bytes.
original=load(study.resultFile,'studyRecord','nativeResult');
savedTime=dir(study.resultFile);
reusedRecord=persistOceInversionStudy(study,inputs,nativeResult,physical, ...
    review,true,projectRoot,"Plate");
verifyEqual(testCase,reusedRecord,record);
verifyEqual(testCase,load(study.resultFile,'studyRecord','nativeResult'),original);
verifyEqual(testCase,dir(study.resultFile).bytes,savedTime.bytes);
verifyError(testCase,@()persistOceInversionStudy(study,inputs,nativeResult,physical, ...
    review,false,projectRoot,"Plate"),'lamb:study:OutputExists');
changedNative=nativeResult;changedNative.unreviewedValue=42;
verifyError(testCase,@()persistOceInversionStudy(study,inputs,changedNative,physical, ...
    review,true,projectRoot,"Plate"),'lamb:study:HistoricalNativeMismatch');
% Native data are reusable, but new scientific claims cannot be attached to
% the original MAT or to a new figure pointing to that MAT.
changedReview=review;
changedReview.modelAssumptionsJustification="Different experimental hypothesis";
verifyError(testCase,@()persistOceInversionStudy(study,inputs,nativeResult,physical, ...
    changedReview,true,projectRoot,"Plate"), ...
    'lamb:study:ScientificReviewMismatch');
study.showFigure=true;
verifyError(testCase,@()renderOceInversionStudy(study,struct(), ...
    nativeResult,changedReview,"Plate"),'lamb:study:ScientificReviewMismatch');
verifyEqual(testCase,load(study.resultFile,'studyRecord','nativeResult'),original);
verifyEqual(testCase,dir(study.resultFile).bytes,savedTime.bytes);
% Different historic field names are accepted only when their meanings agree.
legacyReview=struct('modelBranch',"A0", ...
    'modelSupportReference',review.modelAssumptionsJustification);
assertOceInversionReviewMatch(legacyReview,review);
study.showFigure=false;
verifyFalse(testCase,isfield(record.selection,'experimentRoot'));
verifyFalse(testCase,isfield(record.code.Lamb,'root'));
verifyFalse(testCase,isfield(record.code.OCE,'root'));
saved=load(study.resultFile,'studyRecord','nativeResult');
verifyEqual(testCase,saved.studyRecord,record);
verifyEqual(testCase,saved.nativeResult,nativeResult);
% Simulate an archived selection schema without editing any experiment data.
studyRecord=saved.studyRecord;
sel=studyRecord.selection;
sel.mode=sel.excitationMode;sel=rmfield(sel,'excitationMode');
sel.frequencySelection=sel.fitFrequencySelection;
sel.frequency_Hz=sel.fitFrequency_Hz;
sel=rmfield(sel,{'fitFrequencySelection','fitFrequency_Hz'});
studyRecord.selection=sel;
save(study.resultFile,'studyRecord','-append');
adapted=persistOceInversionStudy(study,inputs,nativeResult,physical, ...
    review,true,projectRoot,"Plate");
verifyEqual(testCase,adapted.selection.excitationMode,record.selection.excitationMode);
verifyEqual(testCase,adapted.selection.fitFrequencySelection,record.selection.fitFrequencySelection);
verifyEqual(testCase,adapted.selection.fitFrequency_Hz,record.selection.fitFrequency_Hz);
archived=load(study.resultFile,'studyRecord');
verifyTrue(testCase,isfield(archived.studyRecord.selection,'mode'));
verifyFalse(testCase,isfield(archived.studyRecord.selection,'excitationMode'));
end

function testFailedBatchPersistsReviewedCaseWithoutMachinePaths(testCase)
root=tempname;mkdir(root);cleanup=onCleanup(@()rmdir(root,'s'));
c=baseCase(root,"Stretch_1p00000");
c.condition=struct('strain_percent',0);
c.physical=struct('density_kgpm3',1050,'thickness_m',.0005);
plan=struct('experimentRoot',string(root), ...
    'oceRepositoryRoot',"missing_OCE_checkout",'cases',c, ...
    'execute',true,'exportFigure',false,'saveResult',true, ...
    'continueOnError',true,'inversionsRoot',fullfile(root,'OCE_Inversions'));
report=runOceInversionBatch(plan,"Plate");
verifyEqual(testCase,report.report.status,"failed");
verifyTrue(testCase,isfile(report.report.failureRecordFile));
saved=load(report.report.failureRecordFile,'failureRecord');
verifyEqual(testCase,saved.failureRecord.errorId,"lamb:study:OceRepository");
verifyEqual(testCase,saved.failureRecord.nativeResultBase,"inversionsRoot");
verifyFalse(testCase,isfield(saved.failureRecord.request,'inversionsRoot'));
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
    'cases',c,'execute',false, ...
    'inversionsRoot',fullfile(root,"DryRun_Inversions"));
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

function testRlReviewIsRepeatableWithoutDerivedInputFields(testCase)
p=lamb.models.rayleigh_lamb.rlDefaultParams();
source=baseCase("unused","synthetic");
source.thicknessPolicy="oce_directional_per_acquisition";
source.fitConfig=struct('branchName',"A0",'freeParams',"mu_Pa", ...
    'fixedParams',struct('density_kgpm3',p.rho,'thickness_m',NaN,'poisson_ratio',p.nu), ...
    'initialGuess',struct('mu_Pa',p.mu),'bounds',struct('mu_Pa',[20e3 200e3]));
source.review=struct('thicknessSource',"OCE recorded", ...
    'thicknessJustification',"Reviewed geometry", ...
    'densitySource',"Synthetic", ...
    'fitParameterJustification',"Synthetic", ...
    'modelAssumptionsJustification',"Reviewed A0 hypothesis");
data=struct('frequency_Hz',[1000;2000], ...
    'Cp_mps',[3;4],'validMask',true(2,1));
assembly=struct('experimental',data,'measuredThickness_m',[.0005;.0006]);
obs=table([1;2],'VariableNames',{'sourceIndex'});
[experimental,physics,review]=reviewOceInversionPhysics(source,assembly,obs,"RayleighLamb");
source.fitConfig=physics; % Mirrors the manual section but retains editable review.
[second,physicalAgain,reviewAgain]=reviewOceInversionPhysics(source,assembly,obs,"RayleighLamb");
verifyEqual(testCase,second,experimental);
verifyEqual(testCase,physicalAgain,physics);
verifyEqual(testCase,reviewAgain,review);
verifyEqual(testCase,review.modelBranch,"A0");
end

function testPulseGraphicSelectionUsesSourceRowsNotSharedHz(testCase)
% Two acquisitions share 1000 Hz but have different original-bin grids.
observed=table([1;1;2;2],[1;2;1;2],[1000;2000;1000;2500], ...
    logical([1;0;1;1]), ...
    'VariableNames',{'sourceIndex','sourceBinIndex','frequency_Hz','validMask'});
mapping=table([1;2],[1;2],[1000;2500], ...
    'VariableNames',{'sourceIndex','sourceBinIndex','observedFrequency_Hz'});
before=observed;
selected=oceInversionGraphicRows(observed,mapping,height(observed));
verifyEqual(testCase,selected,logical([1;0;0;1]));
verifyEqual(testCase,observed,before);
verifyEqual(testCase,observed.validMask,before.validMask);
verifyError(testCase,@()oceInversionGraphicRows(observed,mapping,5), ...
    'lamb:study:GraphicMapping');
verifyError(testCase,@()oceInversionGraphicRows(observed, ...
    mapping(:,{'sourceIndex'}),height(observed)), ...
    'lamb:study:GraphicMapping');
end

function testNativePlateReuseNeedsExactObservations(testCase)
root=tempname;mkdir(root);cleanup=onCleanup(@()rmdir(root,'s'));
physical=struct('density_kgpm3',1050,'thickness_m',.001);
params=physical;params.alpha_Pa=300000;params.gamma_Pa=150000;
frequencies=[1000;2000;3000;4000];
model=lamb.models.acoustoelastic_prestressed_plate.aePlateSolveDispersion(frequencies,params);
experimental=struct('frequency_Hz',frequencies, ...
    'Cp_mps',model.phaseVelocity_mps,'validMask',true(4,1), ...
    'conditionId',"reviewed",'directionId',"axis1:left");
nativeResult=lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(experimental,physical);
assembly=struct('experimental',experimental, ...
    'sourceResultFiles',"synthetic/PhaseSpeed.mat");
filename=fullfile(root,'inversion.mat');
save(filename,'nativeResult','assembly');
study=struct('existingNativeResult',[],'existingAssembly',[], ...
    'resultFile',string(filename),'reuseOnly',true, ...
    'excitationMode',"Pulse",'fitOptions',struct());
[out,reused]=fitOceInversionNative(study,assembly,experimental,physical, ...
    struct(),"synthetic/PhaseSpeed.mat","Plate");
verifyTrue(testCase,reused);
verifyEqual(testCase,out,nativeResult);
changed=experimental;changed.validMask(1)=false;
verifyError(testCase,@()fitOceInversionNative(study,assembly,changed,physical, ...
    struct(),"synthetic/PhaseSpeed.mat","Plate"),'lamb:study:RequestMismatch');
end

function testBatchReuseDoesNotOverwriteSavedResult(testCase)
[root,oceRoot,cleanup]=presentationFailureFixture(); %#ok<ASGLU>
externalRoot=string(root)+"_batch_outputs";
mkdir(externalRoot);
externalCleanup=onCleanup(@()rmdir(externalRoot,'s')); %#ok<NASGU>
c=baseCase(root,"Stretch_1p00000");
c.excitationMode="QH";c.period_us="";
c.conditionId="reuse_saved";c.physical=struct('density_kgpm3',1050,'thickness_m',.0005);
c.review=struct();
plan=struct('experimentRoot',string(root),'oceRepositoryRoot',string(oceRoot), ...
    'cases',c,'execute',true,'exportFigure',false,'saveResult',true, ...
    'continueOnError',false,'reuseOnly',false, ...
    'inversionsRoot',externalRoot);
plan.reuseOnly=true;
verifyError(testCase,@()runOceInversionBatch(plan,"Plate"), ...
    'lamb:study:MissingReuseResult');
preview=resolveOceInversionPaths(c,"Plate");
verifyFalse(testCase,isfile(fullfile(preview.figureFolder,"inversion_failure.mat")));
plan.reuseOnly=false;
first=runOceInversionBatch(plan,"Plate");
verifyEqual(testCase,first.report.status,"completed");
file=first.report.resultFile(1);
verifyFalse(testCase,startsWith(file,string(root)+filesep), ...
    'Batch MAT must be saved outside the source experiment.');
fid=fopen(file,'rb');before=fread(fid,inf,'*uint8');fclose(fid);
plan.reuseOnly=true;
second=runOceInversionBatch(plan,"Plate");
fid=fopen(file,'rb');after=fread(fid,inf,'*uint8');fclose(fid);
verifyEqual(testCase,second.report.status,"completed");
verifyTrue(testCase,second.results{1}.reusedResult);
verifyEqual(testCase,after,before);
verifyEqual(testCase,second.results{1}.studyRecord,first.results{1}.studyRecord);
verifyEqual(testCase,first.results{1}.studyRecord.selection.outputBase, ...
    "inversionsRoot");
verifyFalse(testCase,isfield(first.results{1}.studyRecord.selection,'inversionsRoot'));
end

function testPlateUsesAllSelectedMeasuredThicknessRows(testCase)
source=baseCase("unused","Stretch_1p00000");
source.estimator="kf_ridge";
source.thicknessPolicy="oce_directional_per_acquisition";
source.physical=struct('density_kgpm3',1050,'thickness_m',NaN);
source.review=struct('thicknessSource',"", ...
    'thicknessJustification',"",'densitySource',"Reviewed density", ...
    'modelAssumptionsJustification',"Exploratory A0 assumption");
data=struct('frequency_Hz',[1000;2000;3000;4000], ...
    'Cp_mps',[3;4;5;6],'validMask',logical([1;1;0;1]), ...
    'conditionId',"state1",'directionId',"axis1:left");
h=[.405;.406;NaN;.408]*1e-3;
assembly=struct('experimental',data,'measuredThickness_m',h);
obs=table([1;2;3;4],'VariableNames',{'sourceIndex'});
duplicate=source;duplicate.review.modelBranch="S0";
verifyError(testCase,@()reviewOceInversionPhysics(duplicate,assembly,obs,"Plate"), ...
    'lamb:study:DuplicatedReviewChoice');
duplicate=source;duplicate.review.thicknessPolicy="explicit_constant_current_thickness";
verifyError(testCase,@()reviewOceInversionPhysics(duplicate,assembly,obs,"Plate"), ...
    'lamb:study:DuplicatedReviewChoice');
[exp,physical,review]=reviewOceInversionPhysics(source,assembly,obs,"Plate");
% MATLAB Editor Section 4 can be run repeatedly with the same reviewed input.
[expAgain,physicalAgain,reviewAgain]=reviewOceInversionPhysics(source,assembly,obs,"Plate");
verifyEqual(testCase,expAgain,exp);
verifyEqual(testCase,physicalAgain,physical);
verifyEqual(testCase,reviewAgain,review);
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
source.review=struct('thicknessSource',"", ...
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
c.review=struct();
c.condition=struct('strain_percent',0);
c.sampleId="fixture";
second=c;second.conditionId="next";
plan=struct('experimentRoot',string(root),'oceRepositoryRoot',string(oceRoot), ...
    'cases',[c,second],'execute',true,'exportFigure',true,'saveResult',true, ...
    'continueOnError',true, ...
    'inversionsRoot',fullfile(root,'OCE_Inversions'));
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
verifyEqual(testCase,failure.failureRecord.nativeResultBase,"inversionsRoot");
verifyEqual(testCase,failure.failureRecord.request.resolvedOutputBase,"inversionsRoot");
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
c.review=struct();
plan=struct('experimentRoot',string(root),'oceRepositoryRoot',string(oceRoot), ...
    'cases',c,'execute',true,'exportFigure',false,'saveResult',true, ...
    'continueOnError',true,'inversionsRoot',fullfile(root,'OCE_Inversions'));
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
    "reused=study.reuseOnly && isfile(study.resultFile);", "end"]);
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
