clear; clc;
configureTestPath;
fprintf('\nRunning mRLFE fitting validation tests...\n');
fprintf('--------------------------------------\n');

summaryRows = table();

%% Case 1: A0Like mu recovery, exact synthetic data, etaS = 0
trueParams = mrlfeDefaultSweepParams();
trueParams.mu = 75e3;
trueParams.thickness = 0.50e-3;
trueParams.rho = 1070;
trueParams.nu = 0.4999;
frequency_Hz = linspace(1000, 8000, 10).';
solverOptions = mrlfeDefaultSweepOptions("A0Like", 'EtaS', 0.0);
CpSynthetic_mps = mrlfeEvaluateFitModel(trueParams, frequency_Hz, "A0Like", solverOptions);

experimental = struct('frequency_Hz', frequency_Hz, 'Cp_mps', CpSynthetic_mps, 'validMask', true(size(frequency_Hz)));
fitConfig = struct();
fitConfig.branchName = "A0Like";
fitConfig.freeParams = "mu";
fitConfig.fixedParams = struct('thickness', trueParams.thickness, 'rho', trueParams.rho, 'nu', trueParams.nu);
fitConfig.initialGuess = struct('mu', 50e3);
fitConfig.bounds = struct('mu', [20e3, 160e3]);
fitConfig.solverOptions = solverOptions;
fitConfig.fitOptions = struct('useStandardErrorWeights', false, ...
    'optimizerOptions', optimset('Display', 'off', 'MaxIter', 35, 'MaxFunEvals', 70, 'TolX', 1e-4));
fitResult = mrlfeFitDispersionData(experimental, fitConfig);
summaryRows = [summaryRows; assertFitRecovery("mRLFE_A0Like_mu_exact", trueParams.mu, fitResult.bestParams.mu, 0.05, fitResult, 0.10, 8)]; %#ok<AGROW>

%% Case 2: A0Like mu recovery with deterministic small perturbation
perturbation = 0.0025 * mean(CpSynthetic_mps, 'omitnan') * sin(linspace(0, 2*pi, numel(CpSynthetic_mps))).';
experimentalPerturbed = experimental;
experimentalPerturbed.Cp_mps = CpSynthetic_mps + perturbation;
fitConfig.initialGuess = struct('mu', 50e3);
fitResult = mrlfeFitDispersionData(experimentalPerturbed, fitConfig);
summaryRows = [summaryRows; assertFitRecovery("mRLFE_A0Like_mu_perturbed", trueParams.mu, fitResult.bestParams.mu, 0.10, fitResult, 0.30, 8)]; %#ok<AGROW>

%% Case 3: App-level mRLFE adapter contract for the same exact dataset
request = guiBuildFitRequest("mrlfe", ...
    'branchName', "A0Like", ...
    'mode', "basic", ...
    'experimental', experimental, ...
    'fixedParams', struct('thickness', trueParams.thickness, 'rho', trueParams.rho, 'nu', trueParams.nu), ...
    'freeParams', "mu", ...
    'initialGuess', struct('mu', 50e3), ...
    'bounds', struct('mu', [20e3, 160e3]), ...
    'controls', struct('robustness', "Fast", 'etaS', 0.0, 'fluidDensity', 1000, 'fluidSoundSpeed', 1500), ...
    'fitOptions', struct('useStandardErrorWeights', false, ...
        'optimizerOptions', optimset('Display', 'off', 'MaxIter', 35, 'MaxFunEvals', 70, 'TolX', 1e-4)));
fitOutput = guiRunFit(request);
summaryRows = [summaryRows; assertFitRecovery("mRLFE_A0Like_mu_app_adapter", trueParams.mu, fitOutput.fitResult.bestParams.mu, 0.05, fitOutput.fitResult, 0.10, 8)]; %#ok<AGROW>

assignin('base', 'MRLFEFitValidationSummary', summaryRows);
disp(summaryRows);
fprintf('\nmRLFE fitting validation tests passed.\n');
