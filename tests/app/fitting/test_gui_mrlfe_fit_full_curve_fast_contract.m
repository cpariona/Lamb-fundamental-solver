clear; clc;
startup

fprintf('\nRunning GUI mRLFE on-demand full-curve test...\n');
fprintf('---------------------------------------------\n');

branchName = "A0Like";
etaS = 0.12;
frequency_Hz = linspace(1000, 6000, 10).';

params = mrlfeDefaultSweepParams();
params.mu = 75e3;
params.etaS = etaS;

solverOptions = mrlfeDefaultSweepOptions(branchName, 'EtaS', etaS, ...
    'A0Policy', "physicalTail");

[CpSynthetic, rawSynthetic] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, solverOptions);
assert(rawSynthetic.evaluationPath.routeFamily == "public_solver", 'Synthetic setup should use public solver route family.');
assert(rawSynthetic.evaluationPath.path == "viscoelastic_adaptive", 'Synthetic setup should use viscoelastic adaptive engine.');
assert(any(isfinite(CpSynthetic)), 'Synthetic data must contain at least one finite Cp value.');

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
        'mrlfeA0Policy', "physicalTail"));

normalized = guiNormalizeFitResult(fitResult, request);
assert(isfield(normalized, 'fullCurve'), 'Normalized fit must include the display curve.');
assert(numel(normalized.fullCurve.frequency_Hz) >= 20, 'In-band display curve should be generated.');
assert(any(isfinite(normalized.fullCurve.Cp_mps)), 'In-band display curve should contain finite Cp values.');
assert(normalized.fullCurve.source == "fitObjectiveInterpolation", ...
    'Normalized display curve must come from fit-objective interpolation.');
assert(normalized.fullCurve.solverEvaluated == false, ...
    'Run Fit must not reevaluate the forward solver for the display curve.');
assert(isempty(normalized.fullCurve.extension.rawResult), ...
    'Run Fit must not evaluate a full-curve extension automatically.');
assert(contains(string(normalized.fullCurve.extension.errorMessage), "explicit user request"), ...
    'Display-curve metadata must state that the full curve requires explicit user request.');
assert(isempty(normalized.fullCurve.denseSolver.rawResult), ...
    'Run Fit must not create an automatic dense-solver diagnostic.');
assert(contains(string(normalized.fullCurve.denseSolver.errorMessage), "skipped until requested"), ...
    'Dense-solver metadata must record that reevaluation is deferred.');

fprintf('Fit path:       %s\n', fitResult.modelEvaluation.evaluationPath.path);
fprintf('Fit funcCount:  %d\n', fitResult.optimizer.output.funcCount);
fprintf('Display source: %s\n', normalized.fullCurve.source);
fprintf('Full curve:     %s\n', normalized.fullCurve.extension.errorMessage);
fprintf('\nGUI mRLFE on-demand full-curve test passed.\n');
