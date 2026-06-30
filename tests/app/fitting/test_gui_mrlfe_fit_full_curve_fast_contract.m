clear; clc;
startup

fprintf('\nRunning GUI mRLFE fast full-curve test...\n');
fprintf('----------------------------------------\n');

branchName = "A0Like";
etaS = 0.12;
frequency_Hz = linspace(1000, 6000, 10).';

params = mrlfeDefaultSweepParams();
params.mu = 75e3;
params.etaS = etaS;

solverOptions = mrlfeDefaultSweepOptions(branchName, 'EtaS', etaS, ...
    'UseUnifiedAtlasRoute', true, 'A0Policy', "adaptivePhysicalTail");
solverOptions.mrlfeUseAtlasFitRoute = true;

[CpSynthetic, rawSynthetic] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, solverOptions);
assert(rawSynthetic.evaluationPath.routeFamily == "atlas", 'Synthetic full-curve setup should use atlas route family.');
assert(rawSynthetic.evaluationPath.path == "viscous_unified_atlas", 'Synthetic full-curve setup should use viscous unified atlas.');
assert(any(isfinite(CpSynthetic)), 'Synthetic full-curve data must contain at least one finite Cp value.');

experimental = struct();
experimental.frequency_Hz = frequency_Hz;
experimental.Cp_mps = CpSynthetic;
experimental.validMask = isfinite(CpSynthetic);

fitConfig = struct();
fitConfig.branchName = branchName;
fitConfig.freeParams = "etaS";
fitConfig.fixedParams = struct('mu', params.mu, 'thickness', params.thickness, 'rho', params.rho, 'nu', params.nu);
fitConfig.initialGuess = struct('etaS', etaS);
fitConfig.bounds = struct('etaS', [0.0, 0.30]);
fitConfig.solverOptions = solverOptions;
fitConfig.fitOptions = struct('useStandardErrorWeights', false, ...
    'optimizerOptions', optimset('Display', 'off', 'MaxIter', 10, 'MaxFunEvals', 24, 'TolX', 1e-5));

fitResult = mrlfeFitDispersionData(experimental, fitConfig);
request = guiBuildFitRequest("mrlfe", ...
    'branchName', branchName, ...
    'experimental', experimental, ...
    'fixedParams', fitConfig.fixedParams, ...
    'freeParams', fitConfig.freeParams, ...
    'initialGuess', fitConfig.initialGuess, ...
    'bounds', fitConfig.bounds, ...
    'controls', struct('robustness', "Fast", 'etaS', fitConfig.initialGuess.etaS, ...
        'fluidDensity', 1000, 'fluidSoundSpeed', 1500, ...
        'mrlfeUseUnifiedAtlasRoute', true, 'mrlfeA0Policy', "adaptivePhysicalTail"));

normalized = guiNormalizeFitResult(fitResult, request);
assert(isfield(normalized, 'fullCurve'), 'Normalized fit must include fullCurve.');
assert(numel(normalized.fullCurve.frequency_Hz) >= 20, 'In-band plotting curve should be generated.');
assert(any(isfinite(normalized.fullCurve.Cp_mps)), 'In-band plotting curve should contain finite Cp values.');
assert(isempty(normalized.fullCurve.extension.rawResult), 'mRLFE full-curve extension should be skipped by default.');
assert(contains(string(normalized.fullCurve.extension.errorMessage), "skipped"), 'Skipped extension should record a diagnostic message.');

fprintf('Fit path:       %s\n', fitResult.rawSolverResult.evaluationPath.path);
fprintf('Fit funcCount:  %d\n', fitResult.optimizer.output.funcCount);
fprintf('Extension note: %s\n', normalized.fullCurve.extension.errorMessage);
fprintf('\nGUI mRLFE fast full-curve test passed.\n');
