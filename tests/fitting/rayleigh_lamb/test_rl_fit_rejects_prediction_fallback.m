function test_rl_fit_rejects_prediction_fallback()
%TEST_RL_FIT_REJECTS_PREDICTION_FALLBACK Validate strict-root fitting rejection behavior.

fprintf('\nRunning RL fitting prediction-fallback rejection test...\n');
fprintf('----------------------------------------------------\n');

frequency_Hz = linspace(1000, 8000, 12).';
Cp_mps = 6.0 * ones(size(frequency_Hz));
experimental = struct();
experimental.frequency_Hz = frequency_Hz;
experimental.Cp_mps = Cp_mps;
experimental.validMask = true(size(frequency_Hz));

params = lamb.models.rayleigh_lamb.rlDefaultParams();
fitConfig = struct();
fitConfig.branchName = "A0";
fitConfig.freeParams = "mu";
fitConfig.fixedParams = struct('thickness', params.thickness, 'rho', params.rho, 'nu', params.nu);
fitConfig.initialGuess = struct('mu', 158e3);
fitConfig.bounds = struct('mu', [31.6e3, 200e3]);
fitConfig.solverOptions = lamb.models.rayleigh_lamb.rlDefaultOptions("Fast");
fitConfig.fitOptions = struct('useStandardErrorWeights', false);

try
    fitResult = lamb.fitting.rayleigh_lamb.rlFitDispersionData(experimental, fitConfig);
    qc = lamb.fitting.assessFitPhysicalQuality(fitResult);

    assert(isequal(fitResult.validMask(:), experimental.validMask(:)), ...
        'A successful RL fit must preserve complete objective coverage.');
    assert(fitResult.metrics.RMSE > 0.05, ...
        'Flat RL A0 fitting must not report an artificially near-zero RMSE.');
    assert(qc.classification == "warning" || qc.classification == "caution", ...
        'Flat RL A0 fitting must produce physical QC warning/caution.');
    assert(any(qc.reasons == "near-flat experimental curve"), ...
        'Flat RL A0 fitting must flag near-flat experimental curve.');
    fprintf('Fit succeeded with complete strict-root coverage. RMSE: %.6g m/s | QC: %s\n', ...
        fitResult.metrics.RMSE, string(qc.classification));
catch ME
    expectedFailure = strcmp(ME.identifier, 'lamb:fitting:IncompleteModelCoverage') || ...
        contains(ME.message, 'Could not refine initial root');
    assert(expectedFailure, 'Unexpected RL fitting failure: %s', ME.message);
    fprintf('Fit failed as acceptable complete-coverage rejection: %s\n', ME.message);
end

fprintf('\nRL fitting prediction-fallback rejection test passed.\n');
end
