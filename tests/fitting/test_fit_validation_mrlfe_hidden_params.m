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

%% Case 2: A0Like etaS recovery with mu/thickness fixed
% This case validates whether the current real-k mRLFE backend has sufficient
% phase-speed sensitivity to etaS over the maintained fitting band.
trueEtaS = 0.12;
trueParamsEta = trueParams;
trueParamsEta.etaS = trueEtaS;
solverOptionsEta = mrlfeDefaultSweepOptions("A0Like", 'EtaS', trueEtaS);
CpEtaSynthetic_mps = mrlfeEvaluateFitModel(trueParamsEta, frequency_Hz, "A0Like", solverOptionsEta);
experimentalEta = struct('frequency_Hz', frequency_Hz, 'Cp_mps', CpEtaSynthetic_mps, 'validMask', true(size(frequency_Hz)));

fitConfig = struct();
fitConfig.branchName = "A0Like";
fitConfig.freeParams = "etaS";
fitConfig.fixedParams = struct('mu', trueParamsEta.mu, 'thickness', trueParamsEta.thickness, 'rho', trueParamsEta.rho, 'nu', trueParamsEta.nu);
fitConfig.initialGuess = struct('etaS', 0.04);
fitConfig.bounds = struct('etaS', [0.0, 0.30]);
fitConfig.solverOptions = mrlfeDefaultSweepOptions("A0Like", 'EtaS', 0.04);
fitConfig.fitOptions = struct('useStandardErrorWeights', false, ...
    'optimizerOptions', optimset('Display', 'off', 'MaxIter', 35, 'MaxFunEvals', 80, 'TolX', 1e-5));
fitResult = mrlfeFitDispersionData(experimentalEta, fitConfig);
summaryRows = [summaryRows; assertFitRecovery("mRLFE_A0Like_etaS_exact", trueEtaS, fitResult.bestParams.etaS, 0.35, fitResult, 0.20, 8)]; %#ok<AGROW>

assignin('base', 'MRLFEHiddenParamFitValidationSummary', summaryRows);
disp(summaryRows);
fprintf('\nmRLFE hidden-parameter fitting validation tests passed.\n');
