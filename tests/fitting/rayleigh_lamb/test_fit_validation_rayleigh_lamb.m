function test_fit_validation_rayleigh_lamb()
%TEST_FIT_VALIDATION_RAYLEIGH_LAMB Validate Rayleigh-Lamb synthetic fitting recovery.

fprintf('\nRunning Rayleigh-Lamb fitting validation tests...\n');
fprintf('------------------------------------------------\n');

summaryRows = table();

%% Case 1: A0 mu recovery, exact synthetic data
trueParams = lamb.models.rayleigh_lamb.rlDefaultParams();
trueParams.mu = 85e3;
trueParams.thickness = 0.50e-3;
trueParams.rho = 1070;
trueParams.nu = 0.4999;
frequency_Hz = linspace(1000, 8000, 12).';
solverOptions = lamb.models.rayleigh_lamb.rlDefaultOptions("Fast");
CpSynthetic_mps = lamb.fitting.rayleigh_lamb.rlEvaluateFitModel(trueParams, frequency_Hz, "A0", solverOptions);

experimental = struct('frequency_Hz', frequency_Hz, 'Cp_mps', CpSynthetic_mps, 'validMask', true(size(frequency_Hz)));
fitConfig = struct();
fitConfig.branchName = "A0";
fitConfig.freeParams = "mu";
fitConfig.fixedParams = struct('thickness', trueParams.thickness, 'rho', trueParams.rho, 'nu', trueParams.nu);
fitConfig.initialGuess = struct('mu', 55e3);
fitConfig.bounds = struct('mu', [20e3, 180e3]);
fitConfig.solverOptions = solverOptions;
fitConfig.fitOptions = struct('useStandardErrorWeights', false);
fitResult = lamb.fitting.rayleigh_lamb.rlFitDispersionData(experimental, fitConfig);
summaryRows = [summaryRows; assertFitRecovery("RL_A0_mu_exact", trueParams.mu, fitResult.bestParams.mu, 0.03, fitResult, 0.05, 10)]; %#ok<AGROW>

%% Case 2: A0 thickness recovery, exact synthetic data
fitConfig = struct();
fitConfig.branchName = "A0";
fitConfig.freeParams = "thickness";
fitConfig.fixedParams = struct('mu', trueParams.mu, 'rho', trueParams.rho, 'nu', trueParams.nu);
fitConfig.initialGuess = struct('thickness', 0.70e-3);
fitConfig.bounds = struct('thickness', [0.25e-3, 1.00e-3]);
fitConfig.solverOptions = solverOptions;
fitConfig.fitOptions = struct('useStandardErrorWeights', false);
fitResult = lamb.fitting.rayleigh_lamb.rlFitDispersionData(experimental, fitConfig);
summaryRows = [summaryRows; assertFitRecovery("RL_A0_thickness_exact", trueParams.thickness, fitResult.bestParams.thickness, 0.05, fitResult, 0.08, 10)]; %#ok<AGROW>

%% Case 3: A0 mu recovery with deterministic small perturbation
perturbation = 0.0025 * mean(CpSynthetic_mps) * sin(linspace(0, 2*pi, numel(CpSynthetic_mps))).';
experimentalNoisy = experimental;
experimentalNoisy.Cp_mps = CpSynthetic_mps + perturbation;
fitConfig = struct();
fitConfig.branchName = "A0";
fitConfig.freeParams = "mu";
fitConfig.fixedParams = struct('thickness', trueParams.thickness, 'rho', trueParams.rho, 'nu', trueParams.nu);
fitConfig.initialGuess = struct('mu', 55e3);
fitConfig.bounds = struct('mu', [20e3, 180e3]);
fitConfig.solverOptions = solverOptions;
fitConfig.fitOptions = struct('useStandardErrorWeights', false);
fitResult = lamb.fitting.rayleigh_lamb.rlFitDispersionData(experimentalNoisy, fitConfig);
summaryRows = [summaryRows; assertFitRecovery("RL_A0_mu_perturbed", trueParams.mu, fitResult.bestParams.mu, 0.08, fitResult, 0.20, 10)]; %#ok<AGROW>

disp(summaryRows);
fprintf('\nRayleigh-Lamb fitting validation tests passed.\n');
end
