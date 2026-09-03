clear; clc;
configureTestPath;
fprintf('\nRunning physical QC test for flat Rayleigh-Lamb A0-like fit...\n');
fprintf('-------------------------------------------------------------\n');

% This test validates the physical-QC logic for a near-flat A0-like fit. It is
% intentionally independent of whether strict Rayleigh-Lamb fitting now rejects
% the flat curve because of insufficient valid root coverage.
frequency_Hz = linspace(450, 8000, 12).';
Cp_mps = 4.4707 * ones(size(frequency_Hz));
experimental = struct();
experimental.frequency_Hz = frequency_Hz;
experimental.Cp_mps = Cp_mps;
experimental.validMask = true(size(frequency_Hz));

fitResult = struct();
fitResult.modelFamily = "rayleigh_lamb";
fitResult.branchName = "A0";
fitResult.freeParams = "mu";
fitResult.bestParams = struct('mu', 158e3);
fitResult.allParams = struct('mu', 158e3, 'thickness', 0.50e-3, 'rho', 1070, 'nu', 0.4999);
fitResult.fixedParams = struct('thickness', 0.50e-3, 'rho', 1070, 'nu', 0.4999);
fitResult.xBest = 158e3;
fitResult.lowerBounds = 31.6e3;
fitResult.upperBounds = 200e3;
fitResult.frequency_Hz = frequency_Hz;
fitResult.Cp_exp_mps = Cp_mps;
fitResult.Cp_fit_mps = Cp_mps;
fitResult.validMask = true(size(frequency_Hz));
fitResult.metrics = computeDispersionFitMetrics(Cp_mps, experimental);
fitResult.sensitivityMatrix = 0.1 * ones(size(frequency_Hz));
fitResult.identifiability = struct('classification', "locally_identifiable");
fitResult.optimizer = struct('name', "constructed", 'objective', 0, 'exitFlag', 1, 'output', struct());
fitResult.modelEvaluation = struct();

qc = assessFitPhysicalQuality(fitResult);

assert(qc.classification == "warning" || qc.classification == "caution", ...
    'Flat RL A0-like fit should produce physical QC warning/caution.');
assert(any(qc.reasons == "near-flat experimental curve"), ...
    'Flat RL A0-like fit should flag near-flat experimental curve.');
assert(any(qc.reasons == "constant-speed baseline is competitive"), ...
    'Flat RL A0-like fit should flag competitive constant-speed baseline.');
assert(qc.ExperimentalDispersionRatio < 0.015, ...
    'Flat curve experimental dispersion ratio should be below threshold.');

fprintf('Fit RMSE: %.6g m/s\n', fitResult.metrics.RMSE);
fprintf('Constant RMSE: %.6g m/s\n', qc.ConstantRMSE_mps);
fprintf('Physical QC: %s | %s\n', qc.classification, strjoin(qc.reasons, '; '));
fprintf('\nPhysical QC flat RL A0-like test passed.\n');
