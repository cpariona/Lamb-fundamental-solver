clear; clc;
startup

fprintf('\nRunning mRLFE synthetic A0-like fitting test...\n');
fprintf('---------------------------------------------\n');

trueParams = mrlfeDefaultSweepParams();
trueParams.mu = 75e3;
trueParams.thickness = 0.50e-3;
trueParams.rho = 1070;
trueParams.nu = 0.4999;

frequency_Hz = linspace(1000, 8000, 6).';
solverOptions = mrlfeDefaultSweepOptions("A0Like", 'EtaS', 0.0);

CpSynthetic_mps = mrlfeEvaluateFitModel(trueParams, frequency_Hz, "A0Like", solverOptions);
assert(all(isfinite(CpSynthetic_mps) & CpSynthetic_mps > 0), 'Synthetic mRLFE A0-like Cp must be finite and positive.');

experimental = struct();
experimental.frequency_Hz = frequency_Hz;
experimental.Cp_mps = CpSynthetic_mps;
experimental.validMask = true(size(frequency_Hz));

fitConfig = struct();
fitConfig.branchName = "A0Like";
fitConfig.freeParams = "mu";
fitConfig.fixedParams = struct( ...
    'thickness', trueParams.thickness, ...
    'rho', trueParams.rho, ...
    'nu', trueParams.nu);
fitConfig.initialGuess = struct('mu', 50e3);
fitConfig.bounds = struct('mu', [20e3, 160e3]);
fitConfig.solverOptions = solverOptions;
fitConfig.fitOptions = struct('useStandardErrorWeights', false, ...
    'optimizerOptions', optimset('Display', 'off', 'MaxIter', 35, 'MaxFunEvals', 70, 'TolX', 1e-4));

fitResult = mrlfeFitDispersionData(experimental, fitConfig);

relativeMuError = abs(fitResult.bestParams.mu - trueParams.mu) / trueParams.mu;
assert(relativeMuError < 0.05, 'Synthetic mRLFE A0-like fit did not recover mu within 5%%.');
assert(fitResult.metrics.RMSE < 0.10, 'Synthetic mRLFE A0-like fit RMSE is unexpectedly high.');
assert(fitResult.identifiability.classification == "locally_identifiable", ...
    'One-parameter synthetic mRLFE fit should be locally identifiable.');
assert(all(isfinite(fitResult.Cp_fit_mps(fitResult.validMask))), 'Fitted mRLFE Cp contains invalid values.');

fprintf('True mu: %.3f kPa\n', trueParams.mu / 1e3);
fprintf('Fit  mu: %.3f kPa\n', fitResult.bestParams.mu / 1e3);
fprintf('Relative mu error: %.6g\n', relativeMuError);
fprintf('\nmRLFE synthetic A0-like fitting test passed.\n');
