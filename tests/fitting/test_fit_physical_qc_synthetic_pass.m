clear; clc;
startup

fprintf('\nRunning physical QC pass test for synthetic Rayleigh-Lamb fit...\n');
fprintf('------------------------------------------------------------\n');

trueParams = rlDefaultParams();
trueParams.mu = 85e3;
trueParams.thickness = 0.50e-3;
trueParams.rho = 1070;
trueParams.nu = 0.4999;
frequency_Hz = linspace(1000, 8000, 12).';
solverOptions = rlDefaultOptions("Fast");
CpSynthetic_mps = rlEvaluateFitModel(trueParams, frequency_Hz, "A0", solverOptions);
experimental = struct('frequency_Hz', frequency_Hz, 'Cp_mps', CpSynthetic_mps, 'validMask', true(size(frequency_Hz)));

fitConfig = struct();
fitConfig.branchName = "A0";
fitConfig.freeParams = "mu";
fitConfig.fixedParams = struct('thickness', trueParams.thickness, 'rho', trueParams.rho, 'nu', trueParams.nu);
fitConfig.initialGuess = struct('mu', 55e3);
fitConfig.bounds = struct('mu', [20e3, 180e3]);
fitConfig.solverOptions = solverOptions;
fitConfig.fitOptions = struct('useStandardErrorWeights', false);

fitResult = rlFitDispersionData(experimental, fitConfig);
qc = assessFitPhysicalQuality(fitResult);

assert(~any(qc.reasons == "constant-speed baseline is competitive"), ...
    'Synthetic dispersive RL fit should improve over constant-speed baseline.');
assert(qc.ImprovementOverConstant > 0.10, ...
    'Synthetic dispersive RL fit should improve over constant-speed baseline by more than 10%%.');
assert(qc.ExperimentalDispersionRatio > 0.015, ...
    'Synthetic dispersive RL fit should not be classified as near-flat.');

fprintf('Fit mu: %.3f kPa\n', fitResult.bestParams.mu / 1e3);
fprintf('Fit RMSE: %.6g m/s\n', fitResult.metrics.RMSE);
fprintf('Constant RMSE: %.6g m/s\n', qc.ConstantRMSE_mps);
fprintf('Physical QC: %s | %s\n', qc.classification, strjoin(qc.reasons, '; '));
fprintf('\nPhysical QC synthetic pass test passed.\n');
