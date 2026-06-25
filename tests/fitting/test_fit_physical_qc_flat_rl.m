clear; clc;
startup

fprintf('\nRunning physical QC test for flat Rayleigh-Lamb A0 fit...\n');
fprintf('--------------------------------------------------------\n');

frequency_Hz = linspace(450, 8000, 12).';
Cp_mps = 4.4707 * ones(size(frequency_Hz));
experimental = struct();
experimental.frequency_Hz = frequency_Hz;
experimental.Cp_mps = Cp_mps;
experimental.validMask = true(size(frequency_Hz));

params = rlDefaultParams();
fitConfig = struct();
fitConfig.branchName = "A0";
fitConfig.freeParams = "mu";
fitConfig.fixedParams = struct('thickness', params.thickness, 'rho', params.rho, 'nu', params.nu);
fitConfig.initialGuess = struct('mu', 50e3);
fitConfig.bounds = struct('mu', [1e3, 1e6]);
fitConfig.solverOptions = rlDefaultOptions("Fast");
fitConfig.fitOptions = struct('useStandardErrorWeights', false);

fitResult = rlFitDispersionData(experimental, fitConfig);
qc = assessFitPhysicalQuality(fitResult);

assert(qc.classification == "warning" || qc.classification == "caution", ...
    'Flat RL A0 fit should produce physical QC warning/caution.');
assert(any(qc.reasons == "near-flat experimental curve"), ...
    'Flat RL A0 fit should flag near-flat experimental curve.');
assert(any(qc.reasons == "constant-speed baseline is competitive"), ...
    'Flat RL A0 fit should flag competitive constant-speed baseline.');
assert(qc.ExperimentalDispersionRatio < 0.015, ...
    'Flat curve experimental dispersion ratio should be below threshold.');

fprintf('Fit mu: %.3f kPa\n', fitResult.bestParams.mu / 1e3);
fprintf('Fit RMSE: %.6g m/s\n', fitResult.metrics.RMSE);
fprintf('Constant RMSE: %.6g m/s\n', qc.ConstantRMSE_mps);
fprintf('Physical QC: %s | %s\n', qc.classification, strjoin(qc.reasons, '; '));
fprintf('\nPhysical QC flat RL A0 test passed.\n');
