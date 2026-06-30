clear; clc;
startup

fprintf('\nRunning mRLFE etaS fitting forward-cache test...\n');
fprintf('------------------------------------------------\n');

branchName = "A0Like";
trueEtaS = 0.12;
trueParams = mrlfeDefaultSweepParams();
trueParams.mu = 75e3;
trueParams.thickness = 0.50e-3;
trueParams.rho = 1070;
trueParams.nu = 0.4999;
trueParams.etaS = trueEtaS;
frequency_Hz = linspace(1000, 8000, 10).';

solverOptionsSynthetic = mrlfeDefaultSweepOptions(branchName, 'EtaS', trueEtaS);
CpSynthetic_mps = mrlfeEvaluateFitModel(trueParams, frequency_Hz, branchName, solverOptionsSynthetic);
assert(any(isfinite(CpSynthetic_mps)), 'Synthetic viscous mRLFE data must contain finite Cp points.');

experimental = struct();
experimental.frequency_Hz = frequency_Hz;
experimental.Cp_mps = CpSynthetic_mps;
experimental.validMask = isfinite(CpSynthetic_mps(:));

fitConfig = struct();
fitConfig.branchName = branchName;
fitConfig.freeParams = "etaS";
fitConfig.fixedParams = struct( ...
    'mu', trueParams.mu, ...
    'thickness', trueParams.thickness, ...
    'rho', trueParams.rho, ...
    'nu', trueParams.nu);
fitConfig.initialGuess = struct('etaS', 0.04);
fitConfig.bounds = struct('etaS', [0.0, 0.30]);
fitConfig.solverOptions = mrlfeDefaultSweepOptions(branchName, 'EtaS', fitConfig.initialGuess.etaS);
fitConfig.fitOptions = struct('useStandardErrorWeights', false, ...
    'optimizerOptions', optimset('Display', 'off', 'MaxIter', 35, 'MaxFunEvals', 80, 'TolX', 1e-5));

fitResult = mrlfeFitDispersionData(experimental, fitConfig);

relativeEtaSError = abs(fitResult.bestParams.etaS - trueEtaS) / max(trueEtaS, eps);
assert(relativeEtaSError < 0.35, 'Cached etaS fit did not recover etaS within tolerance.');
assert(fitResult.metrics.RMSE < 0.20, 'Cached etaS fit RMSE is unexpectedly high.');
assert(isfield(fitResult.problem, 'forwardCache'), 'mRLFE fit problem should expose forwardCache diagnostics.');
assert(fitResult.problem.forwardCache.enabled == true, 'etaS-only mRLFE fitting should enable the elastic-reference cache.');
assert(fitResult.problem.forwardCache.kind == "etaS_elastic_reference", 'Unexpected mRLFE forward-cache kind.');
assert(isfield(fitResult.problem.solverOptions, 'mrlfeElasticReferenceResult'), ...
    'Cached etaS solver options must include mrlfeElasticReferenceResult.');
assert(isstruct(fitResult.problem.solverOptions.mrlfeElasticReferenceResult), ...
    'mrlfeElasticReferenceResult must be a structure.');
assert(isfield(fitResult.rawSolverResult.options, 'mrlfeElasticReferenceResult'), ...
    'Final raw solver options should include the cached elastic reference.');
assert(all(isfinite(fitResult.Cp_fit_mps(fitResult.validMask))), 'Cached etaS fitted Cp contains invalid values.');

fprintf('True etaS: %.6g Pa*s\n', trueEtaS);
fprintf('Fit  etaS: %.6g Pa*s\n', fitResult.bestParams.etaS);
fprintf('Relative etaS error: %.6g\n', relativeEtaSError);
fprintf('RMSE: %.6g m/s\n', fitResult.metrics.RMSE);
fprintf('Forward cache: enabled=%d | kind=%s | reason=%s\n', ...
    fitResult.problem.forwardCache.enabled, ...
    fitResult.problem.forwardCache.kind, ...
    fitResult.problem.forwardCache.reason);
fprintf('\nmRLFE etaS fitting forward-cache test passed.\n');
