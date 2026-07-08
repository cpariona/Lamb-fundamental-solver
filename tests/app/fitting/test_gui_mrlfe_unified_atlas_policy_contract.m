clear; clc;
startup

fprintf('\nRunning GUI mRLFE unified atlas policy contract test...\n');
fprintf('-----------------------------------------------------\n');

%% Shared small frequency setup
params = rlDefaultParams();
params.fmin = 1000;
params.fmax = 4000;
params.numFrequencyPoints = 10;
params.frequencySpacing = "linspace";
params.mu = 100e3;
params.thickness = 0.5e-3;
params.rho = 1070;
params.nu = 0.499;

%% Main GUI adapter route metadata
options = rlDefaultOptions("Fast");
options.computeA0 = true;
options.computeS0 = false;
options.computeMRLFERealK = true;
options.computeMRLFEElasticRealK = false;
options.computeMRLFEViscoRealK = false;
options.computeMRLFEComplexK = false;
options.mrlfeComputeA0Like = true;
options.mrlfeComputeS0Like = false;
options.mrlfeUseUnifiedAtlasRoute = true;
options.mrlfeA0Policy = "adaptivePhysicalTail";
options.mrlfeParams = defaultMRLFEParams();
options.mrlfeParams.etaS = 0.05;
options.mrlfeParams.etaL = 0;
options.mrlfeParams.useComplexLambda = false;
options.mrlfeParams.fluidDensity = 1000;
options.mrlfeParams.fluidSoundSpeed = 1500;

mainRequest = struct();
mainRequest.params = params;
mainRequest.options = options;
mainRequest.mrlfeParams = options.mrlfeParams;
mainRequest.computeElastic = true;
mainRequest.computeVisco = true;
mainOutput = guiRunMRLFEModel(mainRequest);

assert(mainOutput.metadata.executionProfile.routePolicy == "mrlfeSolve", ...
    'Main GUI mRLFE adapter must use the public solver route.');
assert(mainOutput.metadata.modelResult.execution.internalEngine == "viscoelastic_adaptive", ...
    'Main GUI positive-viscosity mRLFE adapter must report viscoelastic_adaptive.');
assert(mainOutput.metadata.modelResult.termination.policy == "physicalTail", ...
    'Main GUI mRLFE adapter must preserve A0 physicalTail termination.');
assert(mainOutput.metadata.modelResult.fallback.policy == "none" && ...
    mainOutput.metadata.modelResult.fallback.applied == false, ...
    'Main GUI mRLFE adapter must not apply fallback.');
assert(hasNormalizedBranch(mainOutput, "mRLFERealK", "A0Like"), ...
    'Main GUI mRLFE adapter must expose the unified A0Like branch.');

%% Sweep GUI adapter route metadata
sweepRequest = guiBuildSweepRequest("mrlfe", ...
    'modelLabel', "mRLFE real-k", ...
    'branchName', "A0Like", ...
    'sweepField', "etaS", ...
    'sweepLabel', "etaS", ...
    'sweepValuesDisplay', [0.05], ...
    'displayUnit', "Pa*s", ...
    'displayScale', 1, ...
    'baseParams', params, ...
    'baseOptions', options, ...
    'controls', struct('robustness', "Fast", 'etaS', 0.05, ...
        'fluidDensity', 1000, 'fluidSoundSpeed', 1500, ...
        'mrlfeUseUnifiedAtlasRoute', true, 'mrlfeA0Policy', "adaptivePhysicalTail"));

sweepOutput = guiRunMRLFESweep(sweepRequest);
assert(isfield(sweepOutput, 'atlasPolicy'), 'Sweep adapter must expose atlasPolicy metadata.');
assert(sweepOutput.atlasPolicy.mrlfeUseUnifiedAtlasRoute == true, ...
    'Sweep adapter must route through the unified atlas when requested.');
assert(sweepOutput.atlasPolicy.mrlfeA0Policy == "adaptivePhysicalTail", ...
    'Sweep adapter must preserve requested A0 policy.');
assert(~isempty(sweepOutput.summaryTable), 'Sweep adapter must produce a summary table.');

%% Fitting backend route metadata
frequency_Hz = linspace(1000, 4000, 10).';
fitParams = mrlfeDefaultSweepParams();
fitParams.mu = params.mu;
fitParams.thickness = params.thickness;
fitParams.rho = params.rho;
fitParams.nu = params.nu;
fitParams.etaS = 0.05;
fitOptionsForSynthetic = mrlfeDefaultSweepOptions("A0Like", 'EtaS', fitParams.etaS, ...
    'UseUnifiedAtlasRoute', true, 'A0Policy', "adaptivePhysicalTail");
[CpSynthetic, rawSynthetic] = mrlfeEvaluateFitModel(fitParams, frequency_Hz, "A0Like", fitOptionsForSynthetic);
assert(rawSynthetic.evaluationPath.routeFamily == "atlas", ...
    'Synthetic setup must use the atlas fitting route.');
assert(rawSynthetic.evaluationPath.path == "viscous_unified_atlas", ...
    'Synthetic viscous setup must use the viscous unified atlas path.');

experimental = struct();
experimental.frequency_Hz = frequency_Hz;
experimental.Cp_mps = CpSynthetic;
experimental.validMask = isfinite(CpSynthetic);
assert(any(experimental.validMask), 'Synthetic unified-atlas fit data must contain valid points.');

fitRequest = guiBuildFitRequest("mrlfe", ...
    'branchName', "A0Like", ...
    'mode', "basic", ...
    'experimental', experimental, ...
    'fixedParams', struct('thickness', fitParams.thickness, 'rho', fitParams.rho, 'nu', fitParams.nu, 'etaS', fitParams.etaS), ...
    'freeParams', "mu", ...
    'initialGuess', struct('mu', fitParams.mu), ...
    'bounds', struct('mu', [0.8 * fitParams.mu, 1.2 * fitParams.mu]), ...
    'controls', struct('robustness', "Fast", 'etaS', fitParams.etaS, ...
        'fluidDensity', 1000, 'fluidSoundSpeed', 1500, ...
        'mrlfeUseUnifiedAtlasRoute', true, 'mrlfeA0Policy', "adaptivePhysicalTail"), ...
    'fitOptions', struct('useStandardErrorWeights', false, ...
        'optimizerOptions', optimset('Display', 'off', 'MaxIter', 2, 'MaxFunEvals', 5, 'TolX', 1e-4)));

fitOutput = guiFitMRLFESolver(fitRequest);
assert(isfield(fitOutput, 'routePolicy'), 'Fitting adapter must expose routePolicy metadata.');
assert(fitOutput.routePolicy.requestAtlasFitRoute == true, ...
    'Fitting adapter must report atlas-fit request.');
assert(fitOutput.routePolicy.expectedPath == "mrlfe_atlas", ...
    'Fitting adapter must expect the mRLFE atlas path family.');
assert(fitOutput.routePolicy.actualPath == "viscous_unified_atlas", ...
    'Fitting adapter must actually use the viscous unified atlas path.');
assert(fitOutput.routePolicy.mrlfeA0Policy == "adaptivePhysicalTail", ...
    'Fitting adapter must preserve the requested A0 policy.');

fprintf('GUI mRLFE unified atlas policy contract test passed.\n');

function tf = hasNormalizedBranch(guiResult, modelName, branchName)
tf = false;
if ~isfield(guiResult, 'branches') || isempty(guiResult.branches)
    return;
end
for i = 1:numel(guiResult.branches)
    branch = guiResult.branches(i);
    if string(branch.modelName) == string(modelName) && string(branch.branchName) == string(branchName)
        tf = true;
        return;
    end
end
end
