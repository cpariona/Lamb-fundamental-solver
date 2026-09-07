function test_fit_physical_qc_synthetic_pass()
%TEST_FIT_PHYSICAL_QC_SYNTHETIC_PASS Validate physical QC on a clearly dispersive exact fit.

fprintf('\nRunning physical QC pass test for a clearly dispersive synthetic fit...\n');
fprintf('---------------------------------------------------------------\n');

% This is a unit test for the physical-QC logic, not a Rayleigh-Lamb solver
% regression test. It uses a constructed dispersive curve with an exact model
% match so the constant-speed baseline is clearly worse than the fitted model.
frequency_Hz = linspace(500, 8000, 12).';
CpSynthetic_mps = 2.0 + 0.050 * sqrt(frequency_Hz);

experimental = struct();
experimental.frequency_Hz = frequency_Hz;
experimental.Cp_mps = CpSynthetic_mps;
experimental.validMask = true(size(frequency_Hz));

fitResult = struct();
fitResult.modelFamily = "rayleigh_lamb";
fitResult.branchName = "A0";
fitResult.freeParams = "mu";
fitResult.bestParams = struct('mu', 85e3);
fitResult.allParams = struct('mu', 85e3, 'thickness', 0.50e-3, 'rho', 1070, 'nu', 0.4999);
fitResult.fixedParams = struct('thickness', 0.50e-3, 'rho', 1070, 'nu', 0.4999);
fitResult.xBest = 85e3;
fitResult.lowerBounds = 20e3;
fitResult.upperBounds = 180e3;
fitResult.frequency_Hz = frequency_Hz;
fitResult.Cp_exp_mps = CpSynthetic_mps;
fitResult.Cp_fit_mps = CpSynthetic_mps;
fitResult.validMask = true(size(frequency_Hz));
fitResult.metrics = lamb.fitting.computeDispersionFitMetrics(CpSynthetic_mps, experimental);
fitResult.sensitivityMatrix = 0.5 * ones(size(frequency_Hz));
fitResult.identifiability = struct('classification', "locally_identifiable");
fitResult.optimizer = struct('name', "constructed", 'objective', 0, 'exitFlag', 1, 'output', struct());
fitResult.modelEvaluation = struct();

qc = lamb.fitting.assessFitPhysicalQuality(fitResult);

assert(~any(qc.reasons == "constant-speed baseline is competitive"), ...
    'Clearly dispersive exact fit should improve over constant-speed baseline.');
assert(qc.ImprovementOverConstant > 0.10, ...
    'Clearly dispersive exact fit should improve over constant-speed baseline by more than 10%%.');
assert(qc.ExperimentalDispersionRatio > 0.015, ...
    'Clearly dispersive synthetic curve should not be classified as near-flat.');
assert(qc.ModelDispersionRatio > 0.015, ...
    'Clearly dispersive fitted curve should not be weakly dispersive.');

fprintf('Fit RMSE: %.6g m/s\n', fitResult.metrics.RMSE);
fprintf('Constant RMSE: %.6g m/s\n', qc.ConstantRMSE_mps);
fprintf('Physical QC: %s | %s\n', qc.classification, strjoin(qc.reasons, '; '));
fprintf('\nPhysical QC synthetic pass test passed.\n');
end
