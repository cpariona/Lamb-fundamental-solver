clear; clc;
startup

fprintf('\nRunning AE IOP/HGO fitting validation tests...\n');
fprintf('-------------------------------------------\n');

summaryRows = table();

%% Case 1: atlasA0 mu recovery, exact synthetic data
trueParams = struct();
trueParams.R = 7.8e-3;
trueParams.thickness = 550e-6;
trueParams.mu = 50e3;
trueParams.k1 = 25e3;
trueParams.k2 = 100;
trueParams.rho = 1060;
trueParams.rhoF = 1000;
trueParams.fluidBulkModulus = 2.2e9;
trueParams.IOP = 15 * 133.322;
trueParams.frequency = logspace(log10(300), log10(15e3), 35);

solverOptions = defaultAcoustoelasticIOPHGOOptions();
solverOptions.M54_variant = "corrected";
solverOptions.normalizeRows = false;
solverOptions.usePhysicalCpWindow = false;
solverOptions.atlasNumYPoints = 300;
solverOptions.atlasTopNMinima = 12;
solverOptions.atlasBranchPolicy = "atlasA0";
solverOptions.atlasInitializationNumFrequencyPoints = 50;

[CpSynthetic_mps, syntheticRaw] = aeEvaluateFitModel(trueParams, trueParams.frequency, "atlasA0", solverOptions);
assert(any(syntheticRaw.validMask), 'AE validation synthetic atlasA0 output must contain valid points.');
assert(syntheticRaw.solverResult.reliability.SelectionFallbackUsed == false, ...
    'AE validation must not rely on fallback branch selection.');
assert(string(syntheticRaw.solverResult.options.atlasBranchPolicy) == "atlasA0", ...
    'AE validation must use atlasA0 policy.');

experimental = struct();
experimental.frequency_Hz = trueParams.frequency(:);
experimental.Cp_mps = CpSynthetic_mps(:);
experimental.validMask = syntheticRaw.validMask(:);

fitConfig = struct();
fitConfig.branchName = "atlasA0";
fitConfig.freeParams = "mu";
fitConfig.fixedParams = rmfield(trueParams, {'mu', 'frequency'});
fitConfig.initialGuess = struct('mu', 48e3);
fitConfig.bounds = struct('mu', [45e3, 55e3]);
fitConfig.solverOptions = solverOptions;
fitConfig.fitOptions = struct('useStandardErrorWeights', false, ...
    'optimizerOptions', optimset('Display', 'off', 'MaxIter', 10, 'MaxFunEvals', 24, 'TolX', 1e-3));
fitResult = aeFitDispersionData(experimental, fitConfig);
assert(string(fitResult.branchName) == "atlasA0", 'AE validation fit branch must remain atlasA0.');
assert(~isfield(fitResult.rawSolverResult.solverResult, 'identityA0'), ...
    'AE validation fitting output must not contain identityA0 diagnostic branch.');
summaryRows = [summaryRows; assertFitRecovery("AE_atlasA0_mu_exact", trueParams.mu, fitResult.bestParams.mu, 0.15, fitResult, 0.50, 1)]; %#ok<AGROW>

%% Case 2: App-level adapter contract for atlasA0 mu recovery
request = guiBuildFitRequest("acoustoelastic_iop_hgo", ...
    'branchName', "atlasA0", ...
    'mode', "basic", ...
    'experimental', experimental, ...
    'fixedParams', rmfield(trueParams, {'mu', 'frequency'}), ...
    'freeParams', "mu", ...
    'initialGuess', struct('mu', 48e3), ...
    'bounds', struct('mu', [45e3, 55e3]), ...
    'controls', struct('robustness', "Fast", 'atlasNumYPoints', 300, ...
        'atlasTopNMinima', 12, 'atlasInitializationNumFrequencyPoints', 50), ...
    'fitOptions', struct('useStandardErrorWeights', false, ...
        'optimizerOptions', optimset('Display', 'off', 'MaxIter', 10, 'MaxFunEvals', 24, 'TolX', 1e-3)));
fitOutput = guiRunFit(request);
assert(fitOutput.modelFamily == "acoustoelastic_iop_hgo", 'Unexpected AE app-level modelFamily.');
assert(fitOutput.branchName == "atlasA0", 'Unexpected AE app-level branchName.');
summaryRows = [summaryRows; assertFitRecovery("AE_atlasA0_mu_app_adapter", trueParams.mu, fitOutput.fitResult.bestParams.mu, 0.15, fitOutput.fitResult, 0.50, 1)]; %#ok<AGROW>

assignin('base', 'AEIOPHGOFitValidationSummary', summaryRows);
disp(summaryRows);
fprintf('\nAE IOP/HGO fitting validation tests passed.\n');
