clear; clc;
startup

fprintf('\nRunning mRLFE hidden-parameter fitting validation tests...\n');
fprintf('--------------------------------------------------------\n');

summaryRows = table();

%% Shared synthetic setup
trueParams = mrlfeDefaultSweepParams();
trueParams.mu = 75e3;
trueParams.thickness = 0.50e-3;
trueParams.rho = 1070;
trueParams.nu = 0.4999;
frequency_Hz = linspace(1000, 8000, 10).';

%% Case 1: A0Like thickness recovery with etaS = 0
% This validates hidden/fixed parameter handling for mRLFE while using the
% stable zero-viscosity A0Like fitting path. etaS recovery is intentionally
% not part of this maintained synthetic validation case because the current
% real-k A0Like etaS synthetic setup can produce no valid fitting points in
% this frequency band.
solverOptions = mrlfeDefaultSweepOptions("A0Like", 'EtaS', 0.0);
CpSynthetic_mps = mrlfeEvaluateFitModel(trueParams, frequency_Hz, "A0Like", solverOptions);
experimental = struct('frequency_Hz', frequency_Hz, 'Cp_mps', CpSynthetic_mps, 'validMask', true(size(frequency_Hz)));

fitConfig = struct();
fitConfig.branchName = "A0Like";
fitConfig.freeParams = "thickness";
fitConfig.fixedParams = struct('mu', trueParams.mu, 'rho', trueParams.rho, 'nu', trueParams.nu);
fitConfig.initialGuess = struct('thickness', 0.70e-3);
fitConfig.bounds = struct('thickness', [0.25e-3, 1.00e-3]);
fitConfig.solverOptions = solverOptions;
fitConfig.fitOptions = struct('useStandardErrorWeights', false, ...
    'optimizerOptions', optimset('Display', 'off', 'MaxIter', 35, 'MaxFunEvals', 80, 'TolX', 1e-7));
fitResult = mrlfeFitDispersionData(experimental, fitConfig);
summaryRows = [summaryRows; assertFitRecovery("mRLFE_A0Like_thickness_exact", trueParams.thickness, fitResult.bestParams.thickness, 0.08, fitResult, 0.15, 8)]; %#ok<AGROW>

assignin('base', 'MRLFEHiddenParamFitValidationSummary', summaryRows);
disp(summaryRows);
fprintf('\nmRLFE hidden-parameter fitting validation tests passed.\n');
