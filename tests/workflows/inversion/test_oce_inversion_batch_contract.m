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
report=run_rl_oce_inversion_batch(plan);
verifyFalse(testCase,report.executed);
verifyEqual(testCase,report.report.status,"planned");
verifyFalse(testCase,isfolder(fileparts(report.report.resultFile(1))));
plan.cases=repmat(c,2,1);
verifyError(testCase,@()run_rl_oce_inversion_batch(plan), ...
    'lamb:batch:DuplicateOutput');
plan.cases(2).outputTag="second_review";
report=run_rl_oce_inversion_batch(plan);
verifyEqual(testCase,height(report.report),2);
verifyEqual(testCase,numel(unique(report.report.resultFile)),2);
plate=run_ae_plate_oce_inversion_batch(plan);
verifyTrue(testCase,all(contains(plate.report.resultFile,"Plate")));
end

function testReviewedPlateReferenceIsOneDirectionMatchedMeasurement(testCase)
source=baseCase("unused","Stretch_1p00000");
source.estimator="kf_ridge";
source.thicknessPolicy="oce_reference_acquisition";
source.thicknessReferenceSourceIndex=2;
source.physical=struct('density_kgpm3',1050,'thickness_m',NaN);
source.review=struct('mode',"A0",'thicknessPolicy', ...
    "explicit_constant_current_thickness",'thicknessSource',"", ...
    'thicknessJustification',"",'densityReference',"Reviewed density", ...
    'modelSupportReference',"Exploratory A0 assumption");
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
    'mode',"Pulse",'period_us',"320.01",'conditionId',"initial", ...
    'scanAxisIndex',1,'direction',"left",'summaryFile',"", ...
    'outputRelativeFolder',"",'outputTag',"", ...
    'frequencySelection',"interval",'frequency_Hz',[500 2000]);
end
