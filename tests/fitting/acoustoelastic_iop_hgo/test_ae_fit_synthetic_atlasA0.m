function test_ae_fit_synthetic_atlasA0()
%TEST_AE_FIT_SYNTHETIC_ATLASA0 Validate synthetic AE atlasA0 fitting.

fprintf('\nRunning AE IOP/HGO synthetic atlasA0 fitting test...\n');
fprintf('-------------------------------------------------\n');

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

[CpSynthetic_mps, syntheticRaw] = lamb.fitting.acoustoelastic_iop_hgo.aeEvaluateFitModel(trueParams, trueParams.frequency, "atlasA0", solverOptions);
assert(any(syntheticRaw.validMask), 'Synthetic AE atlasA0 output must contain at least one valid point.');
assert(all(isfinite(CpSynthetic_mps(syntheticRaw.validMask)) & CpSynthetic_mps(syntheticRaw.validMask) > 0), ...
    'Synthetic AE atlasA0 valid Cp must be finite and positive.');
assert(syntheticRaw.solverResult.quality.selectionFallbackUsed == false, ...
    'Synthetic AE atlasA0 fitting test should not rely on fallback branch selection.');

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

fitResult = lamb.fitting.acoustoelastic_iop_hgo.aeFitDispersionData(experimental, fitConfig);

relativeMuError = abs(fitResult.bestParams.mu - trueParams.mu) / trueParams.mu;
assert(relativeMuError < 0.15, 'Synthetic AE atlasA0 fit did not recover mu within 15%%.');
assert(fitResult.metrics.RMSE < 0.50, 'Synthetic AE atlasA0 fit RMSE is unexpectedly high.');
assert(any(fitResult.validMask), 'AE atlasA0 fit must retain at least one valid fitted point.');
assert(string(fitResult.branchName) == "atlasA0", 'AE fitting branch must remain atlasA0.');
assert(~isfield(fitResult.modelEvaluation.solverResult, 'identityA0') || ...
    string(fitResult.modelEvaluation.solverResult.options.atlasBranchPolicy) == "atlasA0", ...
    'AE fitting must not use identityA0Diagnostic as production output.');

fprintf('True mu: %.3f kPa\n', trueParams.mu / 1e3);
fprintf('Fit  mu: %.3f kPa\n', fitResult.bestParams.mu / 1e3);
fprintf('Relative mu error: %.6g\n', relativeMuError);
fprintf('\nAE IOP/HGO synthetic atlasA0 fitting test passed.\n');
end
