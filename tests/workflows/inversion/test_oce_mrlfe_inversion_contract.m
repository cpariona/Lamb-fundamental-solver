function tests=test_oce_mrlfe_inversion_contract()
%TEST_OCE_MRLFE_INVERSION_CONTRACT OCE mRLFE human/batch integration contract.
% Synthetic API tests. The native mRLFE fit is replaced by a recording double
% only where routing/reuse is checked; native validation uses the real builder.
tests=functiontests(localfunctions);
end

function testCanonicalSiTranslatesToNativeNamesOnlyAtBoundary(testCase)
config=reviewedConfig();config.fitOptions=struct('useStandardErrorWeights',false);
before=config;
native=translateOceMrlfeConfig(config);
verifyEqual(testCase,config,before);
verifyEqual(testCase,native.branchName,"A0Like");
verifyEqual(testCase,native.freeParams,"mu");
verifyEqual(testCase,native.fixedParams,struct('etaS',5,'rho',1050, ...
    'thickness',5e-4,'nu',.4999,'fluidDensity_kgm3',1000,'fluidSoundSpeed_mps',1500));
verifyEqual(testCase,native.initialGuess,struct('mu',15000));
verifyEqual(testCase,native.bounds,struct('mu',[1000 100000]));
verifyEqual(testCase,native.fitOptions,config.fitOptions);
verifyFalse(testCase,isfield(native,'solverOptions'),'Numerical options are not invented.');
% A free viscosity moves to the native name and out of the fixed set.
config.freeParams=["mu_Pa","etaS_Pas"];
config.fixedParams=rmfield(config.fixedParams,'etaS_Pas');
config.initialGuess.etaS_Pas=2;config.bounds.etaS_Pas=[0 10];
native=translateOceMrlfeConfig(config);
verifyEqual(testCase,native.freeParams,["mu";"etaS"]);
verifyFalse(testCase,isfield(native.fixedParams,'etaS'));
verifyEqual(testCase,native.bounds.etaS,[0 10]);
end

function testExplicitPhysicalInputsAndSupportDecisionsAreRequired(testCase)
for name=["density_kgpm3","thickness_m","poisson_ratio","etaS_Pas", ...
        "fluidDensity_kgpm3","fluidSoundSpeed_mps"]
    config=reviewedConfig();config.fixedParams=rmfield(config.fixedParams,name);
    verifyError(testCase,@()translateOceMrlfeConfig(config),'lamb:study:PhysicalInput');
    % A NaN placeholder is an unapproved input, never a default.
    config=reviewedConfig();config.fixedParams.(name)=NaN;
    verifyRejected(testCase,@()translateOceMrlfeConfig(config));
end
config=reviewedConfig();config.branchName="A0";
verifyError(testCase,@()translateOceMrlfeConfig(config),'lamb:study:ModelReview');
config=reviewedConfig();config.fixedParams.rho=1050; % legacy native name
verifyError(testCase,@()translateOceMrlfeConfig(config),'lamb:study:AmbiguousPhysicalInput');
config=reviewedConfig();config.fixedParams.mu_Pa=2e4; % fixed and free
verifyError(testCase,@()translateOceMrlfeConfig(config),'lamb:study:AmbiguousPhysicalInput');
config=reviewedConfig();config.initialGuess=struct();
verifyError(testCase,@()translateOceMrlfeConfig(config),'lamb:study:MrlfeConfig');
config=reviewedConfig();config.bounds.mu_Pa=[1000 100000 5];
verifyRejected(testCase,@()translateOceMrlfeConfig(config));
config=reviewedConfig();config.initialGuess.mu_Pa=5;
verifyError(testCase,@()translateOceMrlfeConfig(config),'lamb:study:MrlfeConfig');
% Thickness is one reviewed scalar and fluid properties are fixed.
for name=["thickness_m","fluidDensity_kgpm3","fluidSoundSpeed_mps"]
    config=reviewedConfig();config.freeParams=name;
    config.fixedParams=rmfield(config.fixedParams,name);
    config.fixedParams.mu_Pa=1e4;
    config.initialGuess=struct(char(name),1);config.bounds=struct(char(name),[.5 2]);
    verifyError(testCase,@()translateOceMrlfeConfig(config),'lamb:study:MrlfeConfig');
end
end

function testReviewPreflightsWithoutFittingAndKeepsRows(testCase)
mock=installNativeFitDouble(testCase);
[assembly,obs]=assemblyFixture([1000;2000;3000;4000],logical([1;1;0;1]),[]);
study=reviewStudy("explicit_constant");
[experimental,physics,review]=reviewOceInversionPhysics(study,assembly,obs,"mRLFE");
verifyEqual(testCase,experimental,assembly.experimental);
verifyFalse(testCase,isfield(experimental,'observationThickness_m'));
verifyEqual(testCase,physics,study.fitConfig);
verifyEqual(testCase,review.modelBranch,"A0Like");
verifyEqual(testCase,review.thicknessPolicy,"explicit_constant");
% Repeating the Editor review section is stable and does not require a fit.
[again,physicsAgain,reviewAgain]=reviewOceInversionPhysics(study,assembly,obs,"mRLFE");
verifyEqual(testCase,{again,physicsAgain,reviewAgain},{experimental,physics,review});
verifyEmpty(testCase,calls(mock));
% S0Like is an explicit branch choice, not inferred.
study.fitConfig.branchName="S0Like";
[~,~,review]=reviewOceInversionPhysics(study,assembly,obs,"mRLFE");
verifyEqual(testCase,review.modelBranch,"S0Like");
for text=["thicknessSource","thicknessJustification","densitySource","fluidSource", ...
        "fitParameterJustification","modelAssumptionsJustification"]
    bad=reviewStudy("explicit_constant");bad.review.(text)="";
    verifyError(testCase,@()reviewOceInversionPhysics(bad,assembly,obs,"mRLFE"), ...
        'lamb:study:PhysicalReview');
end
duplicate=reviewStudy("explicit_constant");duplicate.review.modelBranch="S0Like";
verifyError(testCase,@()reviewOceInversionPhysics(duplicate,assembly,obs,"mRLFE"), ...
    'lamb:study:DuplicatedReviewChoice');
end

function testScalarThicknessPolicyIsExplicitAndMedianCountsAcquisitions(testCase)
[assembly,obs]=assemblyFixture([1000;2000;3000;4000],true(4,1),[.4;.4;.6;.6]*1e-3);
obs.sourceIndex=[1;1;2;2];
% Per-acquisition geometry is unsupported by the native scalar-thickness model.
for policy=["oce_directional_per_acquisition",""]
    bad=reviewStudy(policy);
    verifyError(testCase,@()reviewOceInversionPhysics(bad,assembly,obs,"mRLFE"), ...
        'lamb:study:ThicknessPolicy');
end
study=reviewStudy("oce_median_per_case");
study.fitConfig.fixedParams.thickness_m=NaN; % placeholder replaced by the review
[experimental,physics,review]=reviewOceInversionPhysics(study,assembly,obs,"mRLFE");
verifyEqual(testCase,physics.fixedParams.thickness_m,.5e-3,'AbsTol',1e-15);
verifyFalse(testCase,isfield(experimental,'observationThickness_m'));
verifyEqual(testCase,review.thicknessPolicy,"oce_median_per_case");
verifySubstring(testCase,review.thicknessSource,"directional_mean_thickness_mm");
verifyEqual(testCase,study.fitConfig.fixedParams.thickness_m,NaN);
% A selected acquisition without thickness rejects the median request.
missing=assembly;missing.measuredThickness_m(3:4)=NaN;
verifyError(testCase,@()reviewOceInversionPhysics(study,missing,obs,"mRLFE"), ...
    'lamb:study:MissingThickness');
% explicit_constant needs the researcher's scalar.
constant=reviewStudy("explicit_constant");constant.fitConfig.fixedParams.thickness_m=NaN;
verifyRejected(testCase,@()reviewOceInversionPhysics(constant,assembly,obs,"mRLFE"));
end

function testInvalidSupportAndFullAxisArePreservedWithoutRepair(testCase)
mock=installNativeFitDouble(testCase);
study=reviewStudy("explicit_constant");
% Unsupported Poisson ratio: native support owner rejects it.
bad=study;bad.fitConfig.fixedParams.poisson_ratio=.45;
[assembly,obs]=assemblyFixture([1000;2000;3000;4000],true(4,1),[]);
verifyError(testCase,@()reviewOceInversionPhysics(bad,assembly,obs,"mRLFE"), ...
    'mrlfe:UnsupportedPoissonRatio');
% Excluded DC stays in the reviewed observations and is not evaluated.
[assembly,obs]=assemblyFixture([0;1000;2000;3000],logical([0;1;1;1]),[]);
before=assembly;
[retained,~,~]=reviewOceInversionPhysics(study,assembly,obs,"mRLFE");
verifyEqual(testCase,retained,assembly.experimental);
verifyEqual(testCase,assembly,before);
% Repetitions remain separate observations despite a unique solver grid.
[assembly,obs]=assemblyFixture([1000;1000;2000;2000],true(4,1),[]);
[retained,~,~]=reviewOceInversionPhysics(study,assembly,obs,"mRLFE");
verifyEqual(testCase,retained,assembly.experimental);
% Selected rows are retained in their original order.
[assembly,obs]=assemblyFixture([3000;2000;1000;4000],true(4,1),[]);
[retained,~,~]=reviewOceInversionPhysics(study,assembly,obs,"mRLFE");
verifyEqual(testCase,retained,assembly.experimental);
% A selected row that native normalization would deselect is rejected.
[assembly,obs]=assemblyFixture([1000;2000;3000;4000],true(4,1),[]);
assembly.experimental.Cp_mps(2)=NaN;
verifyRejected(testCase,@()reviewOceInversionPhysics(study,assembly,obs,"mRLFE"));
verifyEmpty(testCase,calls(mock));
end

function testNativeRoutingTranslationAndExactReuse(testCase)
mock=installNativeFitDouble(testCase);
[assembly,obs]=assemblyFixture([1000;2000;3000;4000],logical([1;1;0;1]),[]); %#ok<ASGLU>
config=reviewedConfig();
study=struct('existingNativeResult',[],'existingAssembly',[], ...
    'resultFile',string(tempname)+".mat",'reuseOnly',true,'excitationMode',"Pulse", ...
    'estimator',"kf_ridge");
experimental=assembly.experimental;
% reuseOnly rejects a changed request before any native fit.
verifyError(testCase,@()fitOceInversionNative(study,assembly,experimental,config, ...
    struct(),"synthetic/PhaseSpeed.mat","mRLFE"),'lamb:study:RequestMismatch');
verifyEmpty(testCase,calls(mock));
study.reuseOnly=false;
[native,reused,physics]=fitOceInversionNative(study,assembly,experimental,config, ...
    struct(),"synthetic/PhaseSpeed.mat","mRLFE");
verifyFalse(testCase,reused);
verifyEqual(testCase,physics,config);
recorded=calls(mock);
verifyEqual(testCase,numel(recorded),1);
verifyEqual(testCase,recorded{1},translateOceMrlfeConfig(config));
verifyEqual(testCase,string(native.modelFamily),"mrlfe");
verifyEqual(testCase,recorded{1}.fixedParams.rho,1050);
% Exact request: reused without another native call.
study.existingNativeResult=native;study.existingAssembly=assembly;study.reuseOnly=true;
[again,reused]=fitOceInversionNative(study,assembly,experimental,config, ...
    struct(),"synthetic/PhaseSpeed.mat","mRLFE");
verifyTrue(testCase,reused);verifyEqual(testCase,again,native);
% Each changed value field is a mismatch, never a silent new fit.
changed=config;changed.bounds.mu_Pa=[2000 100000];
verifyError(testCase,@()fitOceInversionNative(study,assembly,experimental,changed, ...
    struct(),"synthetic/PhaseSpeed.mat","mRLFE"),'lamb:study:RequestMismatch');
changed=config;changed.fixedParams.fluidSoundSpeed_mps=1501;
verifyError(testCase,@()fitOceInversionNative(study,assembly,experimental,changed, ...
    struct(),"synthetic/PhaseSpeed.mat","mRLFE"),'lamb:study:RequestMismatch');
changed=config;changed.branchName="S0Like";
verifyError(testCase,@()fitOceInversionNative(study,assembly,experimental,changed, ...
    struct(),"synthetic/PhaseSpeed.mat","mRLFE"),'lamb:study:RequestMismatch');
other=experimental;other.validMask(1)=false;
verifyError(testCase,@()fitOceInversionNative(study,assembly,other,config, ...
    struct(),"synthetic/PhaseSpeed.mat","mRLFE"),'lamb:study:RequestMismatch');
verifyError(testCase,@()fitOceInversionNative(study,assembly,experimental,config, ...
    struct(),"other/PhaseSpeed.mat","mRLFE"),'lamb:study:RequestMismatch');
% A result of another native family is not reusable for mRLFE.
foreign=native;foreign.modelFamily="rayleigh_lamb";study.existingNativeResult=foreign;
verifyError(testCase,@()fitOceInversionNative(study,assembly,experimental,config, ...
    struct(),"synthetic/PhaseSpeed.mat","mRLFE"),'lamb:study:RequestMismatch');
verifyEqual(testCase,numel(calls(mock)),1);
% QH reuse additionally compares the physical/requested target frequencies.
qh=study;qh.existingNativeResult=native;qh.excitationMode="QH";
qhAssembly=assembly;qhAssembly.physicalFrequency_Hz=[1000;2000;3000;4000];
qhAssembly.requestedTargetFrequency_Hz=[1000;2000;3000;4000];
qhAssembly.lineage=struct('binIndex',{1,2,3,4});
qh.existingAssembly=qhAssembly;
[~,reused]=fitOceInversionNative(qh,qhAssembly,experimental,config, ...
    struct(),"synthetic/PhaseSpeed.mat","mRLFE");
verifyTrue(testCase,reused);
moved=qhAssembly;moved.physicalFrequency_Hz(2)=2100;
verifyError(testCase,@()fitOceInversionNative(qh,moved,experimental,config, ...
    struct(),"synthetic/PhaseSpeed.mat","mRLFE"),'lamb:study:RequestMismatch');
end

function testBatchPlanningIsReadOnlyAndFamilyOutputsAreSeparate(testCase)
mock=installNativeFitDouble(testCase);
root=tempname;mkdir(root);cleanup=onCleanup(@()rmdir(root,'s')); %#ok<NASGU>
c=struct('experimentRoot',string(root),'subexperimentId',"Stretch_1p00000", ...
    'excitationMode',"QH",'period_us',"",'conditionId',"initial", ...
    'scanAxisIndex',1,'direction',"left",'summaryFile',"", ...
    'outputRelativeFolder',"",'outputTag',"", ...
    'fitFrequencySelection',"interval",'fitFrequency_Hz',[500 2000], ...
    'thicknessPolicy',"oce_median_per_case", ...
    'fitConfig',reviewedConfig(),'review',reviewText(),'observationMask',[]);
plan=struct('experimentRoot',string(root),'oceRepositoryRoot',"unused_in_dry_run", ...
    'cases',c,'execute',false,'inversionsRoot',fullfile(root,"DryRun_Inversions"));
% Neither OCE recovery nor a forward solve/fit is attempted when planning.
preview=runOceInversionBatch(plan,"mRLFE");
verifyFalse(testCase,preview.executed);
verifyEqual(testCase,preview.report.status,"planned");
verifyTrue(testCase,all(cellfun(@isempty,preview.results)));
verifyTrue(testCase,isnan(preview.report.nativeRMSE));
verifyEmpty(testCase,calls(mock));
verifyFalse(testCase,isfolder(plan.inversionsRoot));
folders=string(preview.report.resultFile);
verifySubstring(testCase,folders,fullfile("mRLFE","QH_initial_axis1_left"));
% Existing families keep their own destinations and the same case identity.
for family=["RayleighLamb","Plate"]
    other=runOceInversionBatch(plan,family);
    verifySubstring(testCase,string(other.report.resultFile),family);
    verifyNotEqual(testCase,string(other.report.resultFile),folders);
end
verifyError(testCase,@()runOceInversionBatch(plan,"mRLFE_other"),'lamb:batch:Model');
% Full-band approval and band review are enforced for the new family as well.
plan.cases.fitFrequencySelection="all";
verifyError(testCase,@()runOceInversionBatch(plan,"mRLFE"),'lamb:batch:BandReview');
single=resolveOceInversionPaths(c,"mRLFE");
verifyEqual(testCase,single.resultFile,fullfile(root,"Results","Stretch_1p00000", ...
    "Inversions","mRLFE","QH_initial_axis1_left","inversion.mat"));
end

function testRendererRoutesMrlfeToItsOwnPresentation(testCase)
source=string(fileread(which('renderOceInversionStudy')));
verifyTrue(testCase,contains(source,'plotMrlfeFitDiagnostics(nativeResult,provenance'));
verifyTrue(testCase,contains(source,'plotRlFitDiagnostics(nativeResult,provenance'));
% Persistence stores the canonical request for RL/mRLFE and PHYSICAL for Plate.
persist=string(fileread(which('persistOceInversionStudy')));
verifyTrue(testCase,contains(persist,'if family~="Plate"'));
fit=string(fileread(which('fitOceInversionNative')));
verifyTrue(testCase,contains(fit,'lamb.fitting.mrlfe.mrlfeFitDispersionData'));
end

function testModelLineIsOneCpPerUniqueSortedHzAndEvidenceIsUnchanged(testCase)
% Synthetic stored result: repeated, out-of-order rows with one gap and DC.
f=[3000;1000;2000;1000;3000;0;2000;4000];
cp=[3.1;1.1;2.1;1.2;3.2;.5;2.2;4.1];
fit=[3;1;2;1;3;.4;2;NaN];
mask=logical([1;1;1;1;1;0;1;0]);
raw=fit(mask)-cp(mask);
result=struct('modelFamily',"mrlfe",'branchName',"A0Like", ...
    'frequency_Hz',f,'Cp_exp_mps',cp,'Cp_fit_mps',fit,'validMask',mask, ...
    'residualInfo',struct('objectiveMask',mask,'rawResiduals_mps',raw), ...
    'allParams',struct('rho',1050,'thickness',5e-4,'nu',.4999,'etaS',5), ...
    'bestParams',struct('mu',15000),'freeParams',"mu",'metrics',struct('RMSE',.1), ...
    'lowerBounds',1000,'upperBounds',1e5,'optimizer',struct(),'identifiability',struct(), ...
    'problem',struct('fitOptions',struct('useStandardErrorWeights',false)));
before=result;
provenance=struct('label',"Synthetic",'material',"Synthetic",'sourceReference',"Synthetic", ...
    'modelAssumptionsJustification',"Synthetic review",'repetitionId',repmat("r",8,1));
[fig,evidence]=plotMrlfeFitDiagnostics(result,provenance,'Visible','off');
testCase.addTeardown(@()close(fig));
line=findobj(fig,'Tag','mrlfe_native_prediction');
verifyEqual(testCase,numel(line),1);
x=line.XData(:);
verifyEqual(testCase,x,[1;2;3],'AbsTol',1e-12); % kHz; positive, unique, ascending
verifyTrue(testCase,issorted(x,'strictascend'));
verifyEqual(testCase,line.YData(:),[1;2;3]);
% Every original row, mask, residual and the stored result remain unchanged.
verifyEqual(testCase,result,before);
verifyEqual(testCase,evidence.observations.frequency_Hz,f);
verifyEqual(testCase,evidence.observations.predictedCp_mps,fit);
verifyEqual(testCase,evidence.observations.selected,mask);
verifyEqual(testCase,evidence.observations.residual_mps(mask),raw);
verifyEqual(testCase,evidence.unavailablePredictionCount,1);
verifyEqual(testCase,height(evidence.observations),numel(f));
verifyEqual(testCase,fig.UserData.provenance.repetitionId,provenance.repetitionId);
end

function config=reviewedConfig()
config=struct('branchName',"A0Like",'freeParams',"mu_Pa", ...
    'fixedParams',struct('density_kgpm3',1050,'thickness_m',5e-4, ...
        'poisson_ratio',.4999,'etaS_Pas',5, ...
        'fluidDensity_kgpm3',1000,'fluidSoundSpeed_mps',1500), ...
    'initialGuess',struct('mu_Pa',15000),'bounds',struct('mu_Pa',[1000 100000]));
end

function review=reviewText()
review=struct('thicknessSource',"Synthetic thickness",'thicknessJustification', ...
    "Synthetic geometry review",'densitySource',"Synthetic density", ...
    'fluidSource',"Synthetic fluid",'fitParameterJustification',"Synthetic mu", ...
    'modelAssumptionsJustification',"Synthetic A0-like review");
end

function study=reviewStudy(policy)
study=struct('fitConfig',reviewedConfig(),'review',reviewText(), ...
    'thicknessPolicy',policy);
end

function [assembly,obs]=assemblyFixture(frequency,mask,thickness)
n=numel(frequency);
experimental=struct('frequency_Hz',frequency,'Cp_mps',2+(1:n)'*.5, ...
    'validMask',mask,'conditionId',"state1",'directionId',"axis1:left");
assembly=struct('experimental',experimental,'sourceResultFiles',"synthetic/PhaseSpeed.mat");
if ~isempty(thickness),assembly.measuredThickness_m=thickness;end
obs=table((1:n)',(1:n)','VariableNames',{'row','sourceIndex'});
end

function verifyRejected(testCase,fcn)
rejected=false;
try
    fcn();
catch
    rejected=true;
end
verifyTrue(testCase,rejected,'Expected the invalid request to be rejected.');
end

function mock=installNativeFitDouble(testCase)
% Shadow only the native fit: it records its received configuration and returns
% the value fields of the real native problem builder. No forward solve runs.
mock=tempname;folder=fullfile(mock,'+lamb','+fitting','+mrlfe');mkdir(folder);
lines=[ ...
    "function result=mrlfeFitDispersionData(experimental,fitConfig)"
    "stored=getappdata(0,'lambMrlfeWorkflowDoubleCalls');"
    "if isempty(stored),stored={};end"
    "setappdata(0,'lambMrlfeWorkflowDoubleCalls',[stored;{fitConfig}]);"
    "problem=lamb.fitting.mrlfe.mrlfeBuildFitProblem(experimental,fitConfig);"
    "result=struct('modelFamily',""mrlfe"",'branchName',problem.branchName, ..."
    "'frequency_Hz',problem.experimental.frequency_Hz,'Cp_exp_mps',problem.experimental.Cp_mps, ..."
    "'validMask',problem.experimental.validMask, ..."
    "'problem',rmfield(problem,{'evaluateModel','residualFunction','objectiveFunction'}));"
    "end"];
fid=fopen(fullfile(folder,'mrlfeFitDispersionData.m'),'w');
fprintf(fid,'%s\n',lines);fclose(fid);
oldPath=path;
rmappdata_safe();
addpath(mock,'-begin');
testCase.addTeardown(@()restoreDouble(oldPath,mock));
assert(contains(string(which('lamb.fitting.mrlfe.mrlfeFitDispersionData')),string(mock)), ...
    'The native fit double must shadow the maintained function in this test.');
end

function recorded=calls(~)
recorded=getappdata(0,'lambMrlfeWorkflowDoubleCalls');
if isempty(recorded),recorded={};end
end

function restoreDouble(oldPath,mock)
path(oldPath);rmappdata_safe();rmdir(mock,'s');
end

function rmappdata_safe()
if isappdata(0,'lambMrlfeWorkflowDoubleCalls'),rmappdata(0,'lambMrlfeWorkflowDoubleCalls');end
end
