function tests = test_oce_fit_observations()
%TEST_OCE_FIT_OBSERVATIONS Lossless app preparation and independent fit owners.
tests = functiontests(localfunctions);
end

function testRlStudyNativeFitReuseAndFixedRows(testCase)
[study,assembly]=rlStudyFixture();
fresh=runRlStudySections(study,assembly);
direct=lamb.fitting.rayleigh_lamb.rlFitDispersionData(assembly.experimental,study.fitConfig);
verifyEqual(testCase,fresh.nativeResult.frequency_Hz,direct.frequency_Hz);
verifyEqual(testCase,fresh.nativeResult.Cp_exp_mps,direct.Cp_exp_mps);
verifyEqual(testCase,fresh.nativeResult.validMask,direct.validMask);
verifyEqual(testCase,fresh.nativeResult.Cp_fit_mps,direct.Cp_fit_mps);
verifyEqual(testCase,fresh.nativeResult.metrics,direct.metrics);
verifyTrue(testCase,isnan(fresh.nativeResult.Cp_fit_mps(1))); % Excluded DC remains row 1.
study.existingNativeResult=fresh.nativeResult;study.existingAssembly=assembly;
study.reuseOnly=true;
reused=runRlStudySections(study,assembly);
verifyTrue(testCase,reused.reusedResult);
verifyEqual(testCase,reused.nativeResult,fresh.nativeResult);
study.fitConfig.bounds.mu=[40e3 130e3];
verifyError(testCase,@()runRlStudySections(study,assembly),'lamb:study:RequestMismatch');
study.fitConfig=fresh.fitConfig;study.fitConfig.branchName="S0";
verifyError(testCase,@()runRlStudySections(study,assembly),'lamb:study:RequestMismatch');
study.fitConfig=fresh.fitConfig;
assembly.experimental.validMask(2)=false;
verifyError(testCase,@()runRlStudySections(study,assembly),'lamb:study:RequestMismatch');
end

function testRlStudyPersistenceHashesAndOverwriteProtection(testCase)
[study,assembly]=rlStudyFixture();
folder=tempname;mkdir(folder);cleanup=onCleanup(@()rmdir(folder,'s'));
inputFile=fullfile(folder,'source.mat');value=1;save(inputFile,'value');
record=oceInversionProvenance(inputFile,testRepositoryRoot(mfilename('fullpath')));
study.experimentRoot=string(folder);study.summaryFile="source.mat";
study=resolveOceInversionPaths(study,"RayleighLamb");study.saveResult=true;
out=runRlStudySections(study,assembly,record.inputFiles);
saved=load(study.resultFile);
verifyEqual(testCase,saved.nativeResult,out.nativeResult);
verifyEqual(testCase,saved.fitConfig,study.fitConfig);
relativeHashes=record.inputFiles;relativeHashes.path="source.mat";
verifyEqual(testCase,saved.studyRecord.inputFiles,relativeHashes);
verifyEqual(testCase,saved.studyRecord.pathBase,"experimentRoot");
verifyEqual(testCase,saved.studyRecord.selection.condition,study.condition);
verifyEqual(testCase,saved.studyRecord.selection.repetitions,study.repetitions);
verifyFalse(testCase,saved.studyRecord.historicalProcessingContentVerified);
verifyEqual(testCase,saved.studyRecord.provenanceScope,"current_input_bytes_unchanged_during_this_study");
study.saveResult=false;study.reuseOnly=true;
reused=runRlStudySections(study,assembly);
verifyTrue(testCase,reused.reusedResult);verifyEqual(testCase,reused.nativeResult,out.nativeResult);
study.saveResult=true;
verifyError(testCase,@()runRlStudySections(study,assembly,record.inputFiles),'lamb:study:OutputExists');
study.outputTag="changed-input";study=resolveOceInversionPaths(study,"RayleighLamb");
study.existingNativeResult=out.nativeResult;
study.existingAssembly=assembly;value=2;save(inputFile,'value');
verifyError(testCase,@()runRlStudySections(study,assembly,record.inputFiles),'lamb:study:InputsChanged');
verifyFalse(testCase,isfile(study.resultFile));
end

function testRlStudyQhReuseRequiresTheOriginalPhysicalAndBinIdentity(testCase)
[study,assembly]=rlStudyFixture();
for name=["frequency_Hz","Cp_mps","validMask"]
    assembly.experimental.(name)=assembly.experimental.(name)(2:end);
end
study.excitationMode="QH";assembly.sourceResultFiles=["f1";"f2";"f3";"f4"];
assembly.physicalFrequency_Hz=[3000;1000;2000;3000];
assembly.requestedTargetFrequency_Hz=assembly.physicalFrequency_Hz;
assembly.lineage=repmat(struct('binIndex',2),4,1);
fresh=runRlStudySections(study,assembly);
study.existingNativeResult=fresh.nativeResult;study.existingAssembly=assembly;study.reuseOnly=true;
reused=runRlStudySections(study,assembly);
verifyTrue(testCase,reused.reusedResult);verifyEqual(testCase,reused.nativeResult,fresh.nativeResult);
assembly.physicalFrequency_Hz(1)=3000+eps(3000);
verifyError(testCase,@()runRlStudySections(study,assembly),'lamb:study:RequestMismatch');
assembly=study.existingAssembly;assembly.lineage(1).binIndex=3;
verifyError(testCase,@()runRlStudySections(study,assembly),'lamb:study:RequestMismatch');
assembly=study.existingAssembly;assembly.sourceResultFiles=flip(assembly.sourceResultFiles);
verifyError(testCase,@()runRlStudySections(study,assembly),'lamb:study:RequestMismatch');
end

function testStudiesUseTheMaintainedExportWithoutChangingRenderers(testCase)
repoRoot=testRepositoryRoot(mfilename('fullpath'));
folder=tempname;mkdir(folder);cleanup=onCleanup(@()rmdir(folder,'s'));
fig=figure('Visible','off');closeFigure=onCleanup(@()close(fig));
plot(1:3);study=struct('exportFigure',true,'figureFolder',string(folder),'figureName',"Plate");
for script=["run_ae_plate_oce_inversion","run_rl_oce_inversion"]
    body=string(fileread(fullfile(repoRoot,'workflows','inversion',script+".m")));
    verifySubstring(testCase,body,'renderOceInversionStudy(');
    renderer=string(fileread(fullfile(repoRoot,'workflows','inversion','renderOceInversionStudy.m')));
    exportCode=extractBetween(renderer,'if study.exportFigure','end');
    eval(char(exportCode));
    verifyTrue(testCase,isfile(figurePaths.fig));verifyTrue(testCase,isfile(figurePaths.tif));
    info=imfinfo(figurePaths.tif);verifyEqual(testCase,info.XResolution,300);
    reopened=openfig(figurePaths.fig,'new','invisible');drawnow;close(reopened);
    verifyError(testCase,@()saveInverseFigure(fig,study.figureFolder,study.figureName), ...
        'lamb:visualization:OutputExists');
    study.figureName="RL";
end
end

function out=runRlStudySections(study,assembly,inputHashes) %#ok<INUSD> Execute maintained script sections.
if nargin<3,inputHashes=table();end %#ok<NASGU> Used by script eval.
repoRoot=testRepositoryRoot(mfilename('fullpath'));projectRoot=repoRoot; %#ok<NASGU> Used by script eval.
experimental=assembly.experimental;sourceFiles=assembly.sourceResultFiles; %#ok<NASGU>
observationReview=table(experimental.validMask,'VariableNames',{'validMask'}); %#ok<NASGU>
frequencySelectionMapping=table();graphicSamplingMapping=table();
inputs=struct('assembly',assembly,'observationReview',observationReview, ...
    'inputHashes',inputHashes,'frequencySelectionMapping',frequencySelectionMapping, ...
    'graphicSamplingMapping',graphicSamplingMapping); %#ok<NASGU> Used by script eval.
body=string(fileread(fullfile(repoRoot,'workflows','inversion','run_rl_oce_inversion.m')));
code=extractBetween(body,'%% 5. REVIEW RAYLEIGH-LAMB PHYSICS AND CONFIGURATION', ...
    '%% 8. OPTIONAL VISUALIZATION');
eval(char("%% 5. REVIEW RAYLEIGH-LAMB PHYSICS AND CONFIGURATION"+code));
out=struct('nativeResult',nativeResult,'reusedResult',reusedResult,'fitConfig',fitConfig);
end

function [study,assembly]=rlStudyFixture()
params=lamb.models.rayleigh_lamb.rlDefaultParams();params.mu=85e3;
params.rho=1070;params.thickness=.0005;params.nu=.4999;
frequency=[0;3000;1000;2000;3000];
speed=[NaN;lamb.fitting.rayleigh_lamb.rlEvaluateFitModel(params,frequency(2:end),"A0", ...
    lamb.models.rayleigh_lamb.rlDefaultOptions("Fast"))];
experimental=struct('frequency_Hz',frequency,'Cp_mps',speed,'validMask',[false;true(4,1)], ...
    'conditionId',"reviewed_state",'directionId',"scan_axis_1:left");
assembly=struct('experimental',experimental,'sourceResultFiles',"synthetic/PhaseSpeed.mat");
study=struct('experimentRoot',"synthetic",'summaryFile',"synthetic/summary.mat", ...
    'experimentId',"synthetic",'subexperimentId',"S",'sampleId',"P", ...
    'excitationMode',"Pulse",'period_us',"320",'repetitions',["1","2","3"], ...
    'conditionId',"reviewed_state",'condition',struct('strain_percent',0), ...
    'scanAxisIndex',1,'direction',"left",'estimator',"kf_ridge",'curve',"raw", ...
    'fitFrequencySelection',"all",'fitFrequency_Hz',[],'plotTargetFrequency_Hz',[], ...
    'observationMask',[],'thicknessPolicy',"explicit_constant", ...
    'reuseOnly',false,'existingNativeResult',[],'existingAssembly',[], ...
    'resultFile',"",'saveResult',false,'showFigure',false, ...
    'fitConfig',struct('branchName',"A0",'freeParams',"mu", ...
        'fixedParams',struct('rho',1070,'thickness',.0005,'nu',.4999), ...
        'initialGuess',struct('mu',80e3),'bounds',struct('mu',[50e3 120e3])), ...
    'review',struct('thicknessSource',"Synthetic constant thickness", ...
        'thicknessJustification',"Homogeneous synthetic plate",'densitySource',"Synthetic density", ...
        'fitParameterJustification',"Synthetic single-mu request",'modelAssumptionsJustification',"Synthetic A0"));
end

function testExactValuesMasksAndUnknownThickness(testCase)
[source, selection, metadata] = fixture();
source.borders.directional_mean_thickness_mm(1) = NaN;
source.dispersion.estimators.kf_ridge.frequency_axis_hz(1) = 0;
source.dispersion.estimators.kf_ridge.directions(1).phase_speed_curve.smoothed_phase_speed_m_per_s(1) = NaN;
selection.validMask = [false true true false true];
prepared = prepareOceFitObservations(source, selection, metadata);
data = prepared.experimental;
verifyEqual(testCase, data.frequency_Hz, source.dispersion.estimators.kf_ridge.frequency_axis_hz(:));
verifyEqual(testCase, data.Cp_mps, ...
    source.dispersion.estimators.kf_ridge.directions(1).phase_speed_curve.smoothed_phase_speed_m_per_s(:));
verifyEqual(testCase, data.validMask, selection.validMask(:));
verifyEqual(testCase, data.integrationMetadata, metadata);
verifyEqual(testCase, data.source.acquisition, source.acquisition);
verifyEqual(testCase, data.source.processingRunId, source.processing_run_id);
verifyEqual(testCase, data.source.estimatorEvidence.originalMasks, ...
    source.dispersion.estimators.kf_ridge.directions(1).ridge);
verifyTrue(testCase, isnan(prepared.measuredThickness_m));
verifyFalse(testCase, isfield(data, 'standardError_Cp_mps'));
verifyFalse(testCase, isfield(data, 'numPoints'));
normalized = lamb.fitting.normalizeExperimentalDispersionData(data);
verifyEqual(testCase, normalized.frequency_Hz, data.frequency_Hz);
verifyEqual(testCase, normalized.Cp_mps, data.Cp_mps);
verifyEqual(testCase, normalized.validMask, data.validMask);
verifyEqual(testCase, normalized.integrationMetadata, data.integrationMetadata);
verifyEqual(testCase, normalized.source, data.source);
end

function testRawCurveAndSignedIdentityStayExplicit(testCase)
[source, selection, metadata] = fixture();
selection.directionIndex = 4;
selection.curve = "raw";
first = prepareOceFitObservations(source, selection, metadata);
verifyEqual(testCase, first.experimental.source.angularIndex, 2);
verifyEqual(testCase, first.experimental.source.fullCircleAngle_deg, 90);
verifyEqual(testCase, first.experimental.directionId, "scan_axis_2:right");
verifyEqual(testCase, first.experimental.Cp_mps, ...
    source.dispersion.estimators.kf_ridge.directions(4).phase_speed_curve.raw_phase_speed_m_per_s(:));
verifyEqual(testCase, first.measuredThickness_m, 0.00065, 'AbsTol', 1e-18);
metadata.repetitionId = 2;
source.acquisition.run_id = "run_2";
second = prepareOceFitObservations(source, selection, metadata);
verifyEqual(testCase, second.experimental.integrationMetadata.repetitionId, 2);
verifyEqual(testCase, second.experimental.source.acquisition.run_id, "run_2");
verifyEqual(testCase, numel(second.experimental.frequency_Hz), numel(first.experimental.frequency_Hz));
verifyEqual(testCase, second.experimental.frequency_Hz, first.experimental.frequency_Hz);
end

function testPhaseGradientIsNotSubstitutedOrAveraged(testCase)
[source, selection, metadata] = fixture();
selection = rmfield(selection, 'curve');
selection.estimator = "phase_gradient";
selection.validMask = true;
first = prepareOceFitObservations(source, selection, metadata);
verifyEqual(testCase, first.experimental.frequency_Hz, 1500);
verifyEqual(testCase, first.experimental.Cp_mps, 11);
verifyEqual(testCase, first.experimental.source.estimator, "phase_gradient");
selection.directionIndex = 2;
metadata.repetitionId = 2;
second = prepareOceFitObservations(source, selection, metadata);
verifyEqual(testCase, second.experimental.frequency_Hz, first.experimental.frequency_Hz);
verifyEqual(testCase, second.experimental.Cp_mps, 12);
verifyNotEqual(testCase, second.experimental.directionId, first.experimental.directionId);
source.dispersion.estimators.phase_gradient.directions(2).status = "nonfinite_signal";
source.dispersion.estimators.phase_gradient.directions(2).phase_speed_m_per_s = NaN;
selection.validMask = false;
excluded = prepareOceFitObservations(source, selection, metadata);
verifyTrue(testCase, isnan(excluded.experimental.Cp_mps));
verifyFalse(testCase, excluded.experimental.validMask);
verifyFalse(testCase, excluded.experimental.source.estimatorEvidence.originalMasks.valid_mask);
source.dispersion.estimators.phase_gradient.enabled = false;
verifyError(testCase, @() prepareOceFitObservations(source, selection, metadata), ...
    'lamb:oceIntegration:EstimatorUnavailable');
end

function testSelectedInvalidNumbersCannotBeSilentlyDeselected(testCase)
[source, selection, metadata] = fixture();
source.dispersion.estimators.kf_ridge.directions(1).phase_speed_curve.smoothed_phase_speed_m_per_s(2) = NaN;
% Show the inherited normalizer hazard independently of the app guard.
unsafe = struct('frequency_Hz', source.dispersion.estimators.kf_ridge.frequency_axis_hz, ...
    'Cp_mps', source.dispersion.estimators.kf_ridge.directions(1).phase_speed_curve.smoothed_phase_speed_m_per_s, ...
    'validMask', selection.validMask);
normalized = lamb.fitting.normalizeExperimentalDispersionData(unsafe);
verifyFalse(testCase, normalized.validMask(2));
verifyError(testCase, @() prepareOceFitObservations(source, selection, metadata), ...
    'lamb:oceIntegration:InvalidSelectedObservation');
selection.validMask(2) = false;
source.dispersion.estimators.kf_ridge.frequency_axis_hz(1) = 0;
verifyError(testCase, @() prepareOceFitObservations(source, selection, metadata), ...
    'lamb:oceIntegration:InvalidSelectedObservation');
end

function testMetadataAndSelectionHaveNoPhysicalDefaults(testCase)
[source, selection, metadata] = fixture();
metadata.mode = "S0"; % Evidence only; the translator does not impose A0.
prepared = prepareOceFitObservations(source, selection, metadata);
verifyEqual(testCase, prepared.experimental.integrationMetadata, metadata);
verifyFalse(testCase, isfield(prepared, 'density_kgpm3'));
verifyError(testCase, @() prepareOceFitObservations(source, selection, rmfield(metadata, 'conditionId')), ...
    'lamb:oceIntegration:MissingMetadata');
selection.estimator = "auto";
verifyError(testCase, @() prepareOceFitObservations(source, selection, metadata), ...
    'lamb:oceIntegration:UnsupportedEstimator');
end

function testDirectSvdPlateEquivalence(testCase)
[source, selection, metadata] = fixture();
selection.validMask = [true false true true true];
prepared = prepareOceFitObservations(source, selection, metadata);
manual = manualData(source, selection, metadata);
physical = struct('density_kgpm3', 1070, 'thickness_m', 0.0005);
mapped = lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(prepared.experimental, physical);
direct = lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(manual, physical);
verifyTrue(testCase, mapped.accepted);
verifyEqual(testCase, rmfield(mapped, 'experimental'), rmfield(direct, 'experimental'));
verifyEqual(testCase, [mapped.alpha_Pa, mapped.gamma_Pa], [314300 147200], 'AbsTol', 2e-7);
verifyEqual(testCase, mapped.validMask, selection.validMask(:));
end

function testNonlinearRayleighLambEquivalence(testCase)
[source, selection, metadata] = fixture();
params = lamb.models.rayleigh_lamb.rlDefaultParams();
params.mu = 85e3; params.rho = 1070; params.thickness = 0.5e-3;
frequency = [1000; 2000; 3500; 5000; 7000];
options = lamb.models.rayleigh_lamb.rlDefaultOptions("Fast");
speed = lamb.fitting.rayleigh_lamb.rlEvaluateFitModel(params, frequency, "A0", options);
source.dispersion.estimators.kf_ridge.frequency_axis_hz = frequency;
speed(2) = NaN; % excluded datum must survive preparation and fitting
source.dispersion.estimators.kf_ridge.directions(1).phase_speed_curve.smoothed_phase_speed_m_per_s = speed;
selection.validMask = [true; false; true; true; true];
prepared = prepareOceFitObservations(source, selection, metadata);
manual = manualData(source, selection, metadata);
config = struct('branchName', "A0", 'freeParams', "mu", ...
    'fixedParams', struct('rho', params.rho, 'thickness', params.thickness, 'nu', params.nu), ...
    'initialGuess', struct('mu', 50e3), 'bounds', struct('mu', [20e3 200e3]), ...
    'solverOptions', options, 'fitOptions', struct('useStandardErrorWeights', false));
mapped = lamb.fitting.rayleigh_lamb.rlFitDispersionData(prepared.experimental, config);
direct = lamb.fitting.rayleigh_lamb.rlFitDispersionData(manual, config);
% Wall-clock execution time is observational, not a scientific output.
mapped.modelEvaluation.modelResult.execution = ...
    rmfield(mapped.modelEvaluation.modelResult.execution, 'elapsedSeconds');
direct.modelEvaluation.modelResult.execution = ...
    rmfield(direct.modelEvaluation.modelResult.execution, 'elapsedSeconds');
verifyEqual(testCase, rmfield(mapped, 'problem'), rmfield(direct, 'problem'));
verifyEqual(testCase, mapped.problem.experimental.validMask, selection.validMask);
verifyEqual(testCase, mapped.validMask, selection.validMask);
verifyTrue(testCase, isnan(mapped.Cp_exp_mps(2)));
verifyLessThan(testCase, abs(mapped.bestParams.mu-params.mu)/params.mu, 0.03);
end

function testNonlinearMrlfeEquivalence(testCase)
[source,selection,metadata] = fixture();
params = lamb.fitting.mrlfe.mrlfeDefaultFitParameters();
params.mu = 75e3; params.rho = 1070; params.thickness = .0005; params.etaS = 0;
frequency = [1000;2000;3500;5000;7000];
options = lamb.fitting.mrlfe.mrlfeDefaultFitOptions("A0Like",'EtaS',0);
options.mrlfeParams.fluidDensity = 1000; options.mrlfeParams.fluidSoundSpeed = 1500;
[speed,forward] = lamb.fitting.mrlfe.mrlfeEvaluateFitModel(params,frequency,"A0Like",options);
verifyTrue(testCase,all(forward.validMask));
source.dispersion.estimators.kf_ridge.frequency_axis_hz = frequency;
speed(2) = NaN;
source.dispersion.estimators.kf_ridge.directions(1).phase_speed_curve.smoothed_phase_speed_m_per_s = speed;
selection.validMask = [true;false;true;true;true];
prepared = prepareOceFitObservations(source,selection,metadata);
config = struct('branchName',"A0Like",'freeParams',"mu", ...
    'fixedParams',struct('rho',params.rho,'thickness',params.thickness,'nu',params.nu,'etaS',0), ...
    'initialGuess',struct('mu',72e3),'bounds',struct('mu',[65e3 85e3]), ...
    'solverOptions',options,'fitOptions',struct('useStandardErrorWeights',false));
mapped = lamb.fitting.mrlfe.mrlfeFitDispersionData(prepared.experimental,config);
direct = lamb.fitting.mrlfe.mrlfeFitDispersionData(manualData(source,selection,metadata),config);
verifyNativeFitEquivalent(testCase,mapped,direct,prepared);
verifyEqual(testCase,mapped.modelFamily,"mrlfe");
verifyTrue(testCase,mapped.modelEvaluation.evaluationPath.usedPublicSolver);
verifyEqual(testCase,mapped.branchName,"A0Like");
end

function testNonlinearIopHgoEquivalence(testCase)
[source,selection,metadata] = fixture();
params = lamb.fitting.acoustoelastic_iop_hgo.aeDefaultFitParameters();
params.mu = 158e3; params.k1 = 25e3; params.k2 = 100;
params.rho = 1070; params.thickness = .0005;
frequency = [1000;2000;4000;7000;10000];
options = lamb.fitting.acoustoelastic_iop_hgo.aeDefaultFitOptions("Balanced");
[speed,forward] = lamb.fitting.acoustoelastic_iop_hgo.aeEvaluateFitModel(params,frequency,"atlasA0",options);
verifyTrue(testCase,all(forward.validMask));
source.dispersion.estimators.kf_ridge.frequency_axis_hz = frequency;
speed(2) = NaN;
source.dispersion.estimators.kf_ridge.directions(1).phase_speed_curve.smoothed_phase_speed_m_per_s = speed;
selection.validMask = [true;false;true;true;true];
prepared = prepareOceFitObservations(source,selection,metadata);
config = struct('branchName',"atlasA0",'freeParams',"mu", ...
    'fixedParams',rmfield(params,{'mu','frequency'}),'initialGuess',struct('mu',155e3), ...
    'bounds',struct('mu',[150e3 166e3]),'solverOptions',options, ...
    'fitOptions',struct('useStandardErrorWeights',false));
mapped = lamb.fitting.acoustoelastic_iop_hgo.aeFitDispersionData(prepared.experimental,config);
direct = lamb.fitting.acoustoelastic_iop_hgo.aeFitDispersionData(manualData(source,selection,metadata),config);
verifyNativeFitEquivalent(testCase,mapped,direct,prepared);
verifyEqual(testCase,mapped.modelFamily,"acoustoelastic_iop_hgo");
verifyEqual(testCase,mapped.branchName,"atlasA0");
verifyEqual(testCase,string(mapped.modelEvaluation.solverResult.options.atlasBranchPolicy),"atlasA0");
end

function testFamilyRequirementsAreNotRepairedByPreparation(testCase)
[source,selection,metadata] = fixture();
source.dispersion.estimators.kf_ridge.frequency_axis_hz = [0;1000;2000;3000;4000];
selection.validMask = [false;true;true;true;true];
prepared = prepareOceFitObservations(source,selection,metadata);
original = prepared;
config = struct('freeParams',"mu");
verifyError(testCase,@() lamb.fitting.mrlfe.mrlfeBuildFitProblem(prepared.experimental,config), ...
    'mrlfe:InvalidFrequency');
rl = lamb.models.rayleigh_lamb.rlDefaultParams();
ae = lamb.fitting.acoustoelastic_iop_hgo.aeDefaultFitParameters();
actions = {@() lamb.fitting.rayleigh_lamb.rlEvaluateFitModel(rl,prepared.experimental.frequency_Hz), ...
    @() lamb.fitting.acoustoelastic_iop_hgo.aeEvaluateFitModel(ae,prepared.experimental.frequency_Hz)};
for index=1:numel(actions)
    caught = false;
    try
        actions{index}();
    catch exception
        caught = true; verifySubstring(testCase,exception.message,'positive finite');
    end
    verifyTrue(testCase,caught,'Excluded DC must not be removed to bypass native frequency support.');
end
verifyEqual(testCase,prepared,original);
source.dispersion.estimators.kf_ridge.frequency_axis_hz(1) = 100;
selection.validMask(:) = true;
prepared = prepareOceFitObservations(source,selection,metadata);
verifyError(testCase,@() lamb.fitting.acoustoelastic_iop_hgo.aeBuildFitProblem(prepared.experimental,config), ...
    'lamb:fitting:AEObjectiveOutsideSupportedRange');
% Native mRLFE requires strict frequency order even for excluded axis entries.
source.dispersion.estimators.kf_ridge.frequency_axis_hz = [1000;1000;2000;3000;4000];
prepared = prepareOceFitObservations(source,selection,metadata);
verifyError(testCase,@() lamb.fitting.mrlfe.mrlfeBuildFitProblem(prepared.experimental,config), ...
    'mrlfe:InvalidFrequencyOrder');
end

function testNativeRequestCountsAreNotPlateCoveragePolicy(testCase)
[source,selection,metadata] = fixture();
selection = rmfield(selection,'curve'); selection.estimator = "phase_gradient"; selection.validMask = true;
prepared = prepareOceFitObservations(source,selection,metadata);
config = struct('freeParams',"mu");
rl = lamb.fitting.rayleigh_lamb.rlBuildFitProblem(prepared.experimental,config);
mr = lamb.fitting.mrlfe.mrlfeBuildFitProblem(prepared.experimental,config);
ae = lamb.fitting.acoustoelastic_iop_hgo.aeBuildFitProblem(prepared.experimental,config);
for problem = {rl,mr,ae}
    verifyEqual(testCase,problem{1}.experimental.numValidPoints,1);
    verifyTrue(testCase,problem{1}.experimental.validMask);
    verifyFalse(testCase,isfield(problem{1}.experimental,'independentFrequencyGroupId'));
end
% Request construction is not a claim that one observation identifies free parameters.
end

function verifyNativeFitEquivalent(testCase,mapped,direct,prepared)
for name = ["bestParams","allParams","fixedParams","frequency_Hz","Cp_exp_mps", ...
        "Cp_fit_mps","residuals","residualInfo","validMask","metrics","identifiability","sensitivityMatrix"]
    verifyEqual(testCase,mapped.(name),direct.(name));
end
verifyEqual(testCase,mapped.optimizer.objective,direct.optimizer.objective);
verifyEqual(testCase,mapped.optimizer.exitFlag,direct.optimizer.exitFlag);
verifyTrue(testCase,mapped.residualInfo.coverageAccepted);
verifyEqual(testCase,mapped.validMask,prepared.experimental.validMask);
verifyEqual(testCase,mapped.problem.experimental.source,prepared.experimental.source);
verifyEqual(testCase,mapped.problem.experimental.integrationMetadata,prepared.experimental.integrationMetadata);
verifyTrue(testCase,isnan(mapped.Cp_exp_mps(2)));
verifyFalse(testCase,isfield(mapped.problem.experimental,'independentFrequencyGroupId'));
end

function manual = manualData(source, selection, metadata)
manual = struct('frequency_Hz', double(source.dispersion.estimators.kf_ridge.frequency_axis_hz(:)), ...
    'Cp_mps', double(source.dispersion.estimators.kf_ridge.directions(1).phase_speed_curve.smoothed_phase_speed_m_per_s(:)), ...
    'validMask', selection.validMask(:), 'conditionId', metadata.conditionId, ...
    'directionId', "scan_axis_1:left");
end

function testStudyPulseUsesOneOriginalBinMappingAndSeparateMasks(testCase)
[sources,sourceMetadata,summary]=studySources();
study=struct('excitationMode',"Pulse",'scanAxisIndex',1,'direction',"left",'curve',"raw", ...
    'fitFrequencySelection',"explicit",'fitFrequency_Hz',[1000;2000;6000;1002], ...
    'showFigure',true,'plotTargetFrequency_Hz',[3000;2000;6000]);
before=sources;
review=runStudyFrequencySections(study,sources,sourceMetadata,summary);
verifyEqual(testCase,sources,before);
verifyEqual(testCase,find(review.validMask),[2;7;12]);
verifyFalse(testCase,any(review.graphicMask)); % Graphic targets outside the fixed fit stay excluded.
verifyEqual(testCase,review.graphicFrequency,[1998;2002;2997;3003]);
m=review.selectionMapping;
verifyEqual(testCase,nnz(m.mappingSource=="OCE_persisted"),2);
verifyTrue(testCase,all(m.sourceBinIndex(m.requestedFrequency_Hz==2000)==3));
verifyFalse(testCase,any(m.qualityValid(m.requestedFrequency_Hz==2000)));
verifyTrue(testCase,all(isnan(m.observedFrequency_Hz(m.requestedFrequency_Hz==6000))));
verifyEqual(testCase,nnz(review.validMask),3); % Two requests must not duplicate one bin.
g=review.graphicMapping;
verifyEqual(testCase,g.sourceBinIndex(g.requestedFrequency_Hz==3000),[4;4;4]);
verifyEqual(testCase,g.mappingSource(g.requestedFrequency_Hz==3000), ...
    ["OCE_persisted";"nearest_original_bin";"OCE_persisted"]);
% A graphic target change cannot alter the inversion mask or its correspondence.
study.plotTargetFrequency_Hz=4000;
other=runStudyFrequencySections(study,sources,sourceMetadata,summary);
verifyEqual(testCase,other.validMask,review.validMask);
verifyEqual(testCase,other.selectionMapping,review.selectionMapping);
study.fitFrequencySelection="all";study.plotTargetFrequency_Hz=[3000;2000;6000];
allRows=runStudyFrequencySections(study,sources,sourceMetadata,summary);
verifyEqual(testCase,find(allRows.graphicMask),[4;9;14]);
verifyEqual(testCase,allRows.validMask,allRows.qualityMask);
end

function testStudyExplicitMaskAndRecordedPhaseGradient(testCase)
[sources,sourceMetadata,summary]=studySources();
study=struct('excitationMode',"Pulse",'scanAxisIndex',1,'direction',"left",'curve',"raw", ...
    'fitFrequencySelection',"all",'fitFrequency_Hz',[],'showFigure',false, ...
    'plotTargetFrequency_Hz',[],'observationMask',false(15,1));
study.observationMask(2)=true;
out=runStudyFrequencySections(study,sources,sourceMetadata,summary);
verifyEqual(testCase,out.validMask,study.observationMask);
study.fitFrequencySelection="interval";study.fitFrequency_Hz=[2000;4000];
verifyError(testCase,@()runStudyFrequencySections(study,sources,sourceMetadata,summary), ...
    'lamb:study:MaskFrequencyMismatch');
study=rmfield(study,'observationMask');study.excitationMode="QH";study.estimator="phase_gradient";
study.fitFrequencySelection="explicit";study.fitFrequency_Hz=1500;
sourceMetadata.frequency_Hz=repmat(1500,3,1);
out=runStudyFrequencySections(study,sources,sourceMetadata,summary);
verifyEqual(testCase,out.frequency,repmat(1500,3,1));
verifyTrue(testCase,all(isnan(out.bins)));verifyTrue(testCase,all(out.validMask));
study.excitationMode="Pulse";
verifyError(testCase,@()runStudyFrequencySections(study,sources,sourceMetadata,summary), ...
    'lamb:study:EstimatorMode');
end

function testStudyQhNominalIdentityAndLegacyFrequencyModes(testCase)
[sources,sourceMetadata,summary]=studySources();
sourceMetadata.frequency_Hz=[1000;1000;2000];
sources(3).scientific_result.dispersion.estimators.kf_ridge.directions(1).target_selection.selected_bin_index=3;
study=struct('excitationMode',"QH",'scanAxisIndex',1,'direction',"left",'curve',"raw", ...
    'fitFrequencySelection',"explicit",'fitFrequency_Hz',[1000;5000], ...
    'showFigure',false,'plotTargetFrequency_Hz',[]);
review=runStudyFrequencySections(study,sources,sourceMetadata,summary);
verifyEqual(testCase,review.frequency,[1001;999;2002]);
verifyEqual(testCase,review.bins,[2;2;3]);
verifyEqual(testCase,review.validMask,[true;true;false]);
verifyEqual(testCase,review.selectionMapping.observedFrequency_Hz(1:2),[1001;999]);
verifyEqual(testCase,review.selectionMapping.mappingSource(end),"unrecorded_physical_frequency");
study.excitationMode="Pulse";study.fitFrequencySelection="all";
allRows=runStudyFrequencySections(study,sources,sourceMetadata,summary);
verifyEqual(testCase,allRows.validMask,allRows.qualityMask);
study.fitFrequencySelection="interval";study.fitFrequency_Hz=[1000;3000];
interval=runStudyFrequencySections(study,sources,sourceMetadata,summary);
verifyEqual(testCase,interval.validMask, ...
    allRows.qualityMask&allRows.frequency>=1000&allRows.frequency<=3000);
verifyEqual(testCase,interval.frequency,allRows.frequency);
end

function testStudySelectsExactNumericAndLiteralConditions(testCase)
body=string(fileread(fullfile(testRepositoryRoot(mfilename('fullpath')),'workflows','inversion','prepareOceInversionObservations.m')));
selectionCode=extractBetween(body,'selected=metadata.experiment_id','sources=recovered(selected)');
selectionCode="selected=metadata.experiment_id"+selectionCode;
value=1.2345678901234567;
metadata=table(["E";"E"],["S";"S"],["P";"P"],["1";"2"], ...
    ["quasi_harmonic";"quasi_harmonic"],[value;value+eps(value)], ...
    'VariableNames',{'experiment_id','sub_experiment','sample_id','rep_id','excitation_type','state'});
study=struct('experimentId',"E",'subexperimentId',"S",'sampleId',"P", ...
    'repetitions',["1","2"],'excitationMode',"QH",'condition',struct('state',value));
eval(char(selectionCode));verifyEqual(testCase,selected,[true;false]);
study.condition.state=value+eps(value);
eval(char(selectionCode));verifyEqual(testCase,selected,[false;true]);
metadata.state=["001";"1"];
study.condition.state="001";
eval(char(selectionCode));verifyEqual(testCase,selected,[true;false]);
study.condition.state="1"; %#ok<STRNU> Read by the maintained selection section through eval.
eval(char(selectionCode));verifyEqual(testCase,selected,[false;true]);
end

function review=runStudyFrequencySections(study,sources,sourceMetadata,summary) %#ok<INUSD> Inputs are consumed by eval below.
% Execute the maintained manual sections, without optional external OCE I/O or fitting.
repoRoot=testRepositoryRoot(mfilename('fullpath'));
body=string(fileread(fullfile(repoRoot,'workflows','inversion','prepareOceInversionObservations.m')));
if ~isfield(study,'estimator'),study.estimator="kf_ridge";end
selectionCode=extractBetween(body,'%% 3. Review','%% 4. Prepare');
eval(char("%% 3. Review"+selectionCode));
% Exercise the maintained renderer's mapping preflight without opening a figure.
inputs=struct('assembly',struct('experimental',struct('frequency_Hz',frequency, ...
    'Cp_mps',speed,'validMask',validMask)),'observationReview',observationReview, ...
    'graphicSamplingMapping',graphicSamplingMapping); %#ok<NASGU> Used by eval.
body=string(fileread(fullfile(repoRoot,'workflows','inversion','renderOceInversionStudy.m')));
graphicCode=extractBetween(body,'experimental=inputs.assembly.experimental;', ...
    'label=string(study.displayLabel);');
graphicMask=false(size(validMask));graphicFrequency=[];
if study.showFigure
    eval(char("experimental=inputs.assembly.experimental;"+graphicCode));
    if study.excitationMode=="Pulse",graphicMask=expected;graphicFrequency=graphicHz;end
end
review=struct('frequency',frequency,'bins',bins,'qualityMask',qualityMask, ...
    'validMask',validMask,'selectionMapping',frequencySelectionMapping, ...
    'graphicMapping',graphicSamplingMapping,'graphicMask',graphicMask,'graphicFrequency',graphicFrequency);
end

function [sources,sourceMetadata,summary]=studySources()
[source,~,~]=fixture();
sources=repmat(struct('scientific_result',source),3,1);
for j=1:3
    f=[0;1001;2002;3003;4004];if j==2,f=[0;999;1998;2997;3996];end
    one=source.dispersion.estimators.kf_ridge.directions(1);
    one.phase_speed_curve.raw_phase_speed_m_per_s=[NaN;10;20;30;40];
    one.ridge.valid_mask=[false;true;false;true;true];
    one.ridge.interpolated_mask=false(5,1);one.ridge.extrapolated_mask=false(5,1);
    one.target_selection.selected_bin_index=2;
    sources(j).scientific_result.dispersion.estimators.kf_ridge.frequency_axis_hz=f;
    sources(j).scientific_result.dispersion.estimators.kf_ridge.directions=repmat(one,1,4);
end
sourceMetadata=table(["1";"2";"3"],'VariableNames',{'rep_id'});
% These are aligned-axis indices, deliberately outside every original source axis.
summary=struct('summary',struct('dispersion_sampling', ...
    struct('requested_frequency_hz',[1000;3000],'selected_frequency_hz',[1001;3003], ...
    'selected_bin_index',[501;1501])));
end

function [source, selection, metadata] = fixture()
% Narrow consumer projection, not a second complete OCE schema fixture.
frequency = [800.14304727021295 4367.7985459023481 9583.0979186334731 ...
    20543.560908072888 53135.565817473445];
speed = [12.568617595625258 13.721843824166998 15.053095009905279 ...
    16.134875006844061 16.693030321651151];
direction = struct('ridge', struct('valid_mask', [true false true true false], ...
    'interpolated_mask', [false true false false false], ...
    'extrapolated_mask', [false false false false true]), ...
    'phase_speed_curve', struct('smoothed_phase_speed_m_per_s', speed, ...
        'raw_phase_speed_m_per_s', speed+1), 'target_selection', struct('selected_bin_index', 1));
identities = struct('scan_axis_index', {1,1,2,2}, 'direction', {"left","right","left","right"});
gradient = struct('enabled', true, 'directions', ...
    struct('status', {"valid","valid","valid","valid"}, 'phase_speed_m_per_s', {11,12,13,14}));
source = struct('schema', struct('name', "oce_phase_speed_result", 'version', 4), ...
    'processing_run_id', "synthetic_processing", ...
    'acquisition', struct('experiment_id', "synthetic", 'run_id', "run_1"), ...
    'dispersion', struct('directions', identities, 'scan_axis_angles_deg', [0 90], ...
        'estimators', struct('kf_ridge', struct('frequency_axis_hz', frequency, ...
        'directions', repmat(direction, 1, 4)), 'phase_gradient', gradient), ...
        'target_frequency', struct('source', "resolved_filter_center", 'requested_hz', 1500), ...
        'filter_effective_passband_hz', [500 55000]), ...
    'borders', struct('directional_mean_thickness_mm', [0.5 0.55 0.6 0.65]), ...
    'angular', struct('source_direction_indices', [1 4 2 3], 'full_circle_angles_deg', [0 90 180 270]));
selection = struct('directionIndex', 1, 'estimator', "kf_ridge", 'curve', "smoothed", ...
    'validMask', true(1, 5));
metadata = struct('conditionId', "synthetic_state", 'repetitionId', 1, ...
    'loadingCondition', struct('label', "explicit synthetic state"), ...
    'sourceResultFile', "synthetic/PhaseSpeed.mat", 'metadataReference', "synthetic log row 1");
end
