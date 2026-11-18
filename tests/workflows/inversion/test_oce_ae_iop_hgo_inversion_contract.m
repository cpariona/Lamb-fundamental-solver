function tests=test_oce_ae_iop_hgo_inversion_contract()
%TEST_OCE_AE_IOP_HGO_INVERSION_CONTRACT AE IOP/HGO atlasA0 OCE workflow boundary.
% Synthetic functional checks of the SI-to-native boundary, planning, review,
% native reuse, persistence and rendering. They do not exercise the MATLAB
% Editor or validate the biomechanical model against experimental data.
tests=functiontests(localfunctions);
end

function testCanonicalSiInputsTranslateOnlyAtTheNativeBoundary(testCase)
fit=buildOceAeIopHgoFitConfig(validAe());
verifyEqual(testCase,fit.branchName,"atlasA0");
verifyEqual(testCase,fit.freeParams,"mu");
verifyEqual(testCase,fit.fixedParams,struct('R',7.8e-3,'thickness',0.5e-3, ...
    'IOP',15*133.322,'k1',25e3,'k2',100,'rho',1070,'rhoF',1000, ...
    'fluidBulkModulus',2.2e9));
verifyEqual(testCase,fit.initialGuess,struct('mu',150e3));
verifyEqual(testCase,fit.bounds,struct('mu',[100e3 200e3]));
verifyEqual(testCase,fit.solverOptions, ...
    lamb.fitting.acoustoelastic_iop_hgo.aeDefaultFitOptions("Fast"));
% Several free parameters keep their reviewed order and units.
ae=validAe();ae.freeParams=["iop_Pa","mu_Pa"];
ae.fixedPhysical=rmfield(ae.fixedPhysical,'iop_Pa');
ae.initialGuess.iop_Pa=2000;ae.bounds.iop_Pa=[1000 4000];
fit=buildOceAeIopHgoFitConfig(ae);
verifyEqual(testCase,fit.freeParams,["IOP";"mu"]);
verifyEqual(testCase,fit.initialGuess.IOP,2000);
end

function testInvalidOrInferredAeInputsAreRejected(testCase)
base=validAe();
bad=base;bad.branchName="S0";
verifyError(testCase,@()buildOceAeIopHgoFitConfig(bad),'lamb:study:AEBranch');
bad.branchName="A0";
verifyError(testCase,@()buildOceAeIopHgoFitConfig(bad),'lamb:study:AEBranch');
bad=base;bad.executionProfile="";
verifyError(testCase,@()buildOceAeIopHgoFitConfig(bad),'lamb:study:AEConfiguration');
% Legacy native names cannot replace or accompany the canonical vocabulary.
bad=base;bad.fixedPhysical.R=bad.fixedPhysical.radius_m;
bad.fixedPhysical=rmfield(bad.fixedPhysical,'radius_m');
verifyError(testCase,@()buildOceAeIopHgoFitConfig(bad),'lamb:study:AEConfiguration');
% No missing physical value is filled from native defaults.
bad=base;bad.fixedPhysical=rmfield(bad.fixedPhysical,'thickness_m');
verifyError(testCase,@()buildOceAeIopHgoFitConfig(bad),'lamb:study:AEConfiguration');
bad=base;bad.freeParams=strings(0,1);
verifyError(testCase,@()buildOceAeIopHgoFitConfig(bad),'lamb:study:AEConfiguration');
% Geometry is reviewed, never fitted.
bad=base;bad.freeParams="thickness_m";
verifyError(testCase,@()buildOceAeIopHgoFitConfig(bad),'lamb:study:AEConfiguration');
bad=base;bad.initialGuess.mu_Pa=300e3;
verifyError(testCase,@()buildOceAeIopHgoFitConfig(bad),'lamb:study:AEConfiguration');
% NaN placeholders are unapproved inputs.
bad=base;bad.fixedPhysical.radius_m=NaN;
failed=false;
try
    buildOceAeIopHgoFitConfig(bad);
catch
    failed=true;
end
verifyTrue(testCase,failed);
end

function testPlanningIsReadOnlyAndSeparatesOutputs(testCase)
root=tempname;mkdir(root);cleanup=onCleanup(@()rmdir(root,'s'));
plan=struct('experimentRoot',string(root),'oceRepositoryRoot',"unused", ...
    'cases',planCase(root),'execute',false, ...
    'inversionsRoot',fullfile(root,"DryRun_Inversions"));
batch=runOceInversionBatch(plan,"AcoustoelasticIOPHGO");
verifyFalse(testCase,batch.executed);
verifyEqual(testCase,batch.report.status,"planned");
verifyTrue(testCase,all(cellfun(@isempty,batch.results)));
verifyTrue(testCase,contains(batch.report.resultFile(1),"AcoustoelasticIOPHGO"));
verifyFalse(testCase,isfolder(plan.inversionsRoot),'Planning must write nothing.');
bad=plan;bad.cases.ae.branchName="S0";
verifyError(testCase,@()runOceInversionBatch(bad,"AcoustoelasticIOPHGO"), ...
    'lamb:study:AEBranch');
end

function testBatchReportsNativePhaseSpeedMetricWithoutPlateAcceptance(testCase)
root=tempname;mkdir(root);oldPath=path;
cleanup=onCleanup(@()cleanupFixture(oldPath,root));
mock=fullfile(root,'mock');mkdir(mock);
fid=fopen(fullfile(mock,'executeOceInversionStudy.m'),'w');
fprintf(fid,'%s\n', ...
    'function [result,executionError,recovery]=executeOceInversionStudy(study,family,root,recovery)', ...
    'if nargin<4,recovery=[];end', ...
    'executionError=[];', ...
    'native=struct(''validMask'',[true;true;false],''metrics'',struct(''RMSE'',1.25));', ...
    'result=struct(''nativeResult'',native,''completedThrough'',"presentation");', ...
    'end');
fclose(fid);
addpath(mock,'-begin');
plan=struct('experimentRoot',string(root),'oceRepositoryRoot',"unused", ...
    'cases',planCase(root),'execute',true,'saveResult',false, ...
    'exportFigure',false,'inversionsRoot',fullfile(root,"Inversions"));
batch=runOceInversionBatch(plan,"AcoustoelasticIOPHGO");
verifyEqual(testCase,batch.report.status,"completed");
verifyEqual(testCase,batch.report.selectedObservations,2);
verifyEqual(testCase,batch.report.nativeRMSE,1.25);
verifyEqual(testCase,batch.report.nativeRMSEUnit,"m/s");
verifyTrue(testCase,isnan(batch.report.plateNumericalAccepted));
end

function testReviewKeepsFullAxisAndFixedMaskAndEnforcesAnchor(testCase)
anchor=anchorHz();
f=[anchor/2;2*anchor;3*anchor];
experimental=struct('frequency_Hz',f,'Cp_mps',[3;4;5],'validMask',logical([0;1;1]));
assembly=struct('experimental',experimental);
obs=table((1:3)','VariableNames',{'sourceIndex'});
study=reviewStudy();
[out,physics,review]=reviewOceInversionPhysics(study,assembly,obs,"AcoustoelasticIOPHGO");
% The unsupported excluded row is retained in place, not trimmed or repaired.
verifyEqual(testCase,out,experimental);
verifyEqual(testCase,physics.researcher,study.ae);
verifyEqual(testCase,physics.native.branchName,"atlasA0");
verifyEqual(testCase,review.modelBranch,"A0");
verifyEqual(testCase,review.thicknessPolicy,"explicit_constant_current_thickness");
% Re-running the review section does not feed derived values back.
[again,physicsAgain,reviewAgain]=reviewOceInversionPhysics(study,assembly,obs,"AcoustoelasticIOPHGO");
verifyEqual(testCase,again,out);
verifyEqual(testCase,physicsAgain,physics);
verifyEqual(testCase,reviewAgain,review);

selectedBelow=assembly;selectedBelow.experimental.validMask(1)=true;
verifyError(testCase,@()reviewOceInversionPhysics(study,selectedBelow,obs, ...
    "AcoustoelasticIOPHGO"),'lamb:fitting:AEObjectiveOutsideSupportedRange');
excludedDc=assembly;excludedDc.experimental.frequency_Hz(1)=0;
[withDc,dcPhysics,dcReview]=reviewOceInversionPhysics(study,excludedDc,obs, ...
    "AcoustoelasticIOPHGO");
verifyEqual(testCase,withDc,excludedDc.experimental);
verifyEqual(testCase,dcPhysics,physics);
verifyEqual(testCase,dcReview,review);
for invalidHz=[0 -1 NaN Inf]
    selectedInvalid=excludedDc;
    selectedInvalid.experimental.frequency_Hz(1)=invalidHz;
    selectedInvalid.experimental.validMask(1)=true;
    verifyError(testCase,@()reviewOceInversionPhysics(study,selectedInvalid,obs, ...
        "AcoustoelasticIOPHGO"),'lamb:fitting:AEInvalidSelectedObservation');
end
for policy=["oce_median_per_case","oce_directional_per_acquisition"]
    other=study;other.thicknessPolicy=policy;
    verifyError(testCase,@()reviewOceInversionPhysics(other,assembly,obs, ...
        "AcoustoelasticIOPHGO"),'lamb:study:ThicknessPolicy');
end
for name=["thicknessSource","radiusSource","iopSource","fluidSource", ...
        "fitParameterJustification","modelAssumptionsJustification"]
    other=study;other.review.(name)="";
    verifyError(testCase,@()reviewOceInversionPhysics(other,assembly,obs, ...
        "AcoustoelasticIOPHGO"),'lamb:study:PhysicalReview');
end
other=study;other.review.modelBranch="S0";
verifyError(testCase,@()reviewOceInversionPhysics(other,assembly,obs, ...
    "AcoustoelasticIOPHGO"),'lamb:study:DuplicatedReviewChoice');
end

function testNativeReuseNeedsTheExactRequest(testCase)
anchor=anchorHz();
f=[1.5;2;3;4]*anchor;
experimental=struct('frequency_Hz',f,'Cp_mps',[3;4;5;6],'validMask',logical([1;1;0;1]));
files="synthetic/PhaseSpeed.mat";
assembly=struct('experimental',experimental,'sourceResultFiles',files);
obs=table((1:4)','VariableNames',{'sourceIndex'});
[experimental,physics,review]=reviewOceInversionPhysics(reviewStudy(),assembly, ...
    obs,"AcoustoelasticIOPHGO");
% Build the saved request without a forward solve.
problem=lamb.fitting.acoustoelastic_iop_hgo.aeBuildFitProblem(experimental,physics.native);
existing=struct('modelFamily',"acoustoelastic_iop_hgo", ...
    'problem',rmfield(problem,{'evaluateModel','residualFunction','objectiveFunction'}), ...
    'validMask',experimental.validMask,'frequency_Hz',f,'Cp_exp_mps',experimental.Cp_mps);
study=struct('existingNativeResult',existing,'existingAssembly',assembly, ...
    'resultFile',string(tempname)+".mat",'reuseOnly',true,'excitationMode',"Pulse");
[native,reused]=fitOceInversionNative(study,assembly,experimental,physics,review, ...
    files,"AcoustoelasticIOPHGO");
verifyTrue(testCase,reused);
verifyEqual(testCase,native,existing);
changed=experimental;changed.validMask(2)=false;
verifyError(testCase,@()fitOceInversionNative(study,assembly,changed,physics,review, ...
    files,"AcoustoelasticIOPHGO"),'lamb:study:RequestMismatch');
changed=experimental;changed.frequency_Hz(3)=5*anchor;
verifyError(testCase,@()fitOceInversionNative(study,assembly,changed,physics,review, ...
    files,"AcoustoelasticIOPHGO"),'lamb:study:RequestMismatch');
changedPhysics=physics;changedPhysics.native.initialGuess.mu=151e3;
verifyError(testCase,@()fitOceInversionNative(study,assembly,experimental,changedPhysics, ...
    review,files,"AcoustoelasticIOPHGO"),'lamb:study:RequestMismatch');
end

function testNativeFitPersistenceReuseAndFigureRetainTheOriginalRows(testCase)
family="AcoustoelasticIOPHGO";
root=tempname;mkdir(root);cleanup=onCleanup(@()rmdir(root,'s'));
projectRoot=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
source=fullfile(root,"Results","Stretch_1p00000","summary.mat");
mkdir(fileparts(source));values=(1:5)';save(source,'values');
hashes=oceInversionProvenance(source,projectRoot);

truth=struct('R',7.8e-3,'thickness',0.5e-3,'IOP',15*133.322,'mu',158e3, ...
    'k1',25e3,'k2',100,'rho',1070,'rhoF',1000,'fluidBulkModulus',2.2e9);
options=lamb.fitting.acoustoelastic_iop_hgo.aeDefaultFitOptions("Fast");
f=logspace(log10(400),log10(8000),8)';
[cp,raw]=lamb.fitting.acoustoelastic_iop_hgo.aeEvaluateFitModel(truth,f,"atlasA0",options);
assumeTrue(testCase,all(raw.validMask),'The synthetic atlasA0 curve must be valid.');
mask=true(size(f));mask(end)=false; % excluded original row remains on the axis
experimental=struct('frequency_Hz',f,'Cp_mps',cp,'validMask',mask);
files=string(source);
assembly=struct('experimental',experimental,'sourceResultFiles',files);
observationReview=table((1:numel(f))',repmat("1",numel(f),1), ...
    'VariableNames',{'sourceIndex','repetitionId'});
study=struct('experimentRoot',string(root),'subexperimentId',"Stretch_1p00000", ...
    'experimentId',"synthetic",'sampleId',"001",'excitationMode',"QH",'period_us',"", ...
    'repetitions',"1",'conditionId',"state1",'condition',struct('strain_percent',0), ...
    'scanAxisIndex',1,'direction',"left",'estimator',"kf_ridge",'curve',"raw", ...
    'fitFrequencySelection',"interval",'fitFrequency_Hz',[400 8000], ...
    'fullBandReviewed',false,'plotTargetFrequency_Hz',[],'summaryFile',"", ...
    'displayLabel',"",'displaySubtitle',"",'outputTag',"", ...
    'saveResult',true,'showFigure',true,'exportFigure',false,'figureVisible',false, ...
    'reuseOnly',false,'existingNativeResult',[],'existingAssembly',[], ...
    'ae',validAe(),'review',validReview());
study=resolveOceInversionPaths(study,family);
verifyTrue(testCase,contains(study.resultFile,family));

[experimental,physics,review]=reviewOceInversionPhysics(study,assembly, ...
    observationReview,family);
assembly.experimental=experimental;
[native,reused]=fitOceInversionNative(study,assembly,experimental,physics,review, ...
    files,family);
verifyFalse(testCase,reused);
verifyEqual(testCase,native.validMask,mask);
verifyEqual(testCase,native.frequency_Hz,f);
verifyEqual(testCase,native.Cp_exp_mps,cp);
verifyEqual(testCase,native.branchName,"atlasA0");
verifyLessThan(testCase,abs(native.bestParams.mu-truth.mu)/truth.mu,0.05);

inputs=struct('inputHashes',hashes.inputFiles,'assembly',assembly, ...
    'observationReview',observationReview,'frequencySelectionMapping',table(), ...
    'graphicSamplingMapping',table(),'sourceResultFiles',files, ...
    'sourceMetadata',table("Synthetic phantom",'VariableNames',{'material'}));
record=persistOceInversionStudy(study,inputs,native,physics,review,false, ...
    projectRoot,family);
verifyEqual(testCase,record.modelFamily,family);
saved=load(study.resultFile);
verifyFalse(testCase,isfield(saved,'physical'));
verifyEqual(testCase,saved.nativeResult,native);
% Researcher SI inputs and the native request are both retained.
verifyEqual(testCase,saved.fitConfig.researcher.fixedPhysical.thickness_m,0.5e-3);
verifyEqual(testCase,saved.fitConfig.native.fixedParams.thickness,0.5e-3);

reuse=study;reuse.reuseOnly=true;
[again,reusedAgain]=fitOceInversionNative(reuse,assembly,experimental,physics,review, ...
    files,family);
verifyTrue(testCase,reusedAgain);
verifyEqual(testCase,again,native);
% Optional QH assembly identity fields must match exactly, including presence.
altered=assembly;altered.physicalFrequency_Hz=f;
mismatch=reuse;mismatch.existingNativeResult=native;mismatch.existingAssembly=altered;
verifyError(testCase,@()fitOceInversionNative(mismatch,assembly,experimental,physics, ...
    review,files,family),'lamb:study:RequestMismatch');

[fig,evidence]=renderOceInversionStudy(study,inputs,native,review,family);
verifyEmpty(testCase,fig);
verifyEqual(testCase,evidence.observations.selected,mask);
verifyEqual(testCase,evidence.observations.frequency_Hz,f);
verifyEqual(testCase,evidence.nativeParameters,native.allParams);
provenance=struct('label',"Synthetic",'material',"Synthetic phantom", ...
    'sourceReference',"memory",'modelAssumptionsJustification',"Synthetic");
notAtlas=native;notAtlas.branchName="S0";
verifyError(testCase,@()plotAeIopHgoFitDiagnostics(notAtlas,provenance,'Visible','off'), ...
    'lamb:visualization:UnsupportedResult');
end

function anchor=anchorHz()
options=lamb.fitting.acoustoelastic_iop_hgo.aeDefaultFitOptions("Fast");
anchor=options.atlasInitializationMinFrequency_Hz;
end

function ae=validAe()
ae=struct('branchName',"atlasA0",'executionProfile',"Fast",'freeParams',"mu_Pa", ...
    'fixedPhysical',struct('radius_m',7.8e-3,'thickness_m',0.5e-3, ...
        'iop_Pa',15*133.322,'k1_Pa',25e3,'k2',100,'density_kgpm3',1070, ...
        'fluidDensity_kgpm3',1000,'fluidBulkModulus_Pa',2.2e9), ...
    'initialGuess',struct('mu_Pa',150e3),'bounds',struct('mu_Pa',[100e3 200e3]));
end

function review=validReview()
review=struct('thicknessSource',"Synthetic caliper", ...
    'thicknessJustification',"Synthetic current full thickness", ...
    'densitySource',"Synthetic density",'radiusSource',"Synthetic radius", ...
    'iopSource',"Synthetic IOP",'fluidSource',"Synthetic fluid", ...
    'fitParameterJustification',"Synthetic shear modulus", ...
    'modelAssumptionsJustification',"Synthetic AE hypothesis");
end

function study=reviewStudy()
study=struct('ae',validAe(),'review',validReview());
end

function c=planCase(root)
c=struct('experimentRoot',string(root),'subexperimentId',"Stretch_1p00000", ...
    'excitationMode',"Pulse",'period_us',"320.01",'conditionId',"initial", ...
    'scanAxisIndex',1,'direction',"left",'summaryFile',"", ...
    'outputRelativeFolder',"",'outputTag',"", ...
    'fitFrequencySelection',"interval",'fitFrequency_Hz',[500 2000], ...
    'ae',validAe(),'review',validReview());
end

function cleanupFixture(oldPath,root)
path(oldPath);
rmdir(root,'s');
end
