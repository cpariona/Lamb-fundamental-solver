function test_rl_fit_synthetic_A0()
%TEST_RL_FIT_SYNTHETIC_A0 Validate synthetic Rayleigh-Lamb A0 fitting.

fprintf('\nRunning Rayleigh-Lamb synthetic A0 fitting test...\n');
fprintf('------------------------------------------------\n');

trueParams = rlDefaultParams();
trueParams.mu = 85e3;
trueParams.thickness = 0.50e-3;
trueParams.rho = 1070;
trueParams.nu = 0.4999;

frequency_Hz = linspace(1000, 8000, 10).';
solverOptions = rlDefaultOptions("Fast");

CpSynthetic_mps = rlEvaluateFitModel(trueParams, frequency_Hz, "A0", solverOptions);
assert(all(isfinite(CpSynthetic_mps) & CpSynthetic_mps > 0), 'Synthetic A0 Cp must be finite and positive.');

experimental = struct();
experimental.frequency_Hz = frequency_Hz;
experimental.Cp_mps = CpSynthetic_mps;
experimental.validMask = true(size(frequency_Hz));

fitConfig = struct();
fitConfig.branchName = "A0";
fitConfig.freeParams = "mu";
fitConfig.fixedParams = struct( ...
    'thickness', trueParams.thickness, ...
    'rho', trueParams.rho, ...
    'nu', trueParams.nu);
fitConfig.initialGuess = struct('mu', 50e3);
fitConfig.bounds = struct('mu', [20e3, 200e3]);
fitConfig.solverOptions = solverOptions;
fitConfig.fitOptions = struct('useStandardErrorWeights', false, ...
    'optimizerOptions', optimset('Display', 'off', 'MaxIter', 70, 'MaxFunEvals', 180, 'TolX', 1e-5, 'TolFun', 1e-8));

fitResult = rlFitDispersionData(experimental, fitConfig);

relativeMuError = abs(fitResult.bestParams.mu - trueParams.mu) / trueParams.mu;
assert(relativeMuError < 0.03, 'Synthetic Rayleigh-Lamb A0 fit did not recover mu within 3%%.');
assert(fitResult.metrics.RMSE < 0.05, 'Synthetic Rayleigh-Lamb A0 fit RMSE is unexpectedly high.');
assert(fitResult.identifiability.classification == "locally_identifiable", ...
    'One-parameter synthetic fit should be locally identifiable.');
assert(all(isfinite(fitResult.Cp_fit_mps(fitResult.validMask))), 'Fitted Cp contains invalid values.');

fprintf('True mu: %.3f kPa\n', trueParams.mu / 1e3);
fprintf('Fit  mu: %.3f kPa\n', fitResult.bestParams.mu / 1e3);
fprintf('Relative mu error: %.6g\n', relativeMuError);
fprintf('\nRayleigh-Lamb synthetic A0 fitting test passed.\n');
end
