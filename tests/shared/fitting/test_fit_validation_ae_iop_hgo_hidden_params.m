function test_fit_validation_ae_iop_hgo_hidden_params()
%TEST_FIT_VALIDATION_AE_IOP_HGO_HIDDEN_PARAMS Validate hidden-parameter AE fitting.

fprintf('\nRunning AE IOP/HGO hidden-parameter fitting validation tests...\n');
fprintf('-----------------------------------------------------------\n');

summaryRows = table();

%% Shared synthetic setup
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

solverOptions = lamb.models.acoustoelastic_iop_hgo.defaultAcoustoelasticIOPHGOOptions();
solverOptions.M54_variant = "corrected";
solverOptions.normalizeRows = false;
solverOptions.atlasNumYPoints = 300;
solverOptions.atlasTopNMinima = 12;
solverOptions.atlasBranchPolicy = "atlasA0";
solverOptions.atlasInitializationNumFrequencyPoints = 50;

[CpSynthetic_mps, syntheticRaw] = aeEvaluateFitModel(trueParams, trueParams.frequency, "atlasA0", solverOptions);
assert(any(syntheticRaw.validMask), 'AE hidden-parameter validation synthetic atlasA0 output must contain valid points.');
assert(syntheticRaw.solverResult.quality.selectionFallbackUsed == false, ...
    'AE hidden-parameter validation must not rely on fallback branch selection.');

experimental = struct();
experimental.frequency_Hz = trueParams.frequency(:);
experimental.Cp_mps = CpSynthetic_mps(:);
experimental.validMask = syntheticRaw.validMask(:);

%% Case 1: thickness recovery with mu/IOP fixed
fitConfig = struct();
fitConfig.branchName = "atlasA0";
fitConfig.freeParams = "thickness";
fitConfig.fixedParams = rmfield(trueParams, {'thickness', 'frequency'});
fitConfig.initialGuess = struct('thickness', 500e-6);
fitConfig.bounds = struct('thickness', [480e-6, 620e-6]);
fitConfig.solverOptions = solverOptions;
fitConfig.fitOptions = struct('useStandardErrorWeights', false, ...
    'optimizerOptions', optimset('Display', 'off', 'MaxIter', 10, 'MaxFunEvals', 24, 'TolX', 1e-8));
fitResult = aeFitDispersionData(experimental, fitConfig);
assert(string(fitResult.branchName) == "atlasA0", 'AE thickness validation branch must remain atlasA0.');
summaryRows = [summaryRows; assertFitRecovery("AE_atlasA0_thickness_exact", trueParams.thickness, fitResult.bestParams.thickness, 0.20, fitResult, 0.75, 1)]; %#ok<AGROW>

%% Case 2: IOP recovery with mu/thickness fixed
fitConfig = struct();
fitConfig.branchName = "atlasA0";
fitConfig.freeParams = "IOP";
fitConfig.fixedParams = rmfield(trueParams, {'IOP', 'frequency'});
fitConfig.initialGuess = struct('IOP', 13 * 133.322);
fitConfig.bounds = struct('IOP', [10, 20] * 133.322);
fitConfig.solverOptions = solverOptions;
fitConfig.fitOptions = struct('useStandardErrorWeights', false, ...
    'optimizerOptions', optimset('Display', 'off', 'MaxIter', 10, 'MaxFunEvals', 24, 'TolX', 1e-3));
fitResult = aeFitDispersionData(experimental, fitConfig);
assert(string(fitResult.branchName) == "atlasA0", 'AE IOP validation branch must remain atlasA0.');
summaryRows = [summaryRows; assertFitRecovery("AE_atlasA0_IOP_exact", trueParams.IOP, fitResult.bestParams.IOP, 0.25, fitResult, 0.75, 1)]; %#ok<AGROW>

disp(summaryRows);
fprintf('\nAE IOP/HGO hidden-parameter fitting validation tests passed.\n');
end
