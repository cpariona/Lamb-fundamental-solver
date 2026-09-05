function test_gui_mrlfe_fixed_etaS_fit_contract()
%TEST_GUI_MRLFE_FIXED_ETAS_FIT_CONTRACT Validate fixed-viscosity mRLFE fitting.

fprintf('\nRunning GUI mRLFE fixed etaS fit contract test...\n');
fprintf('------------------------------------------------\n');

branchName = "A0Like";
trueMu = 75e3;
fixedEtaS = 0.12;
frequency_Hz = linspace(1000, 8000, 10).';

params = mrlfeDefaultSweepParams();
params.mu = trueMu;
params.etaS = fixedEtaS;
options = mrlfeDefaultSweepOptions(branchName, 'EtaS', fixedEtaS, ...
    'A0Policy', "physicalTail");

[CpSynthetic, rawSynthetic] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, options);
assert(rawSynthetic.evaluationPath.routeFamily == "public_solver", 'Synthetic A0Like etaS data should use the public solver route.');
assert(rawSynthetic.evaluationPath.path == "viscoelastic_adaptive", 'Synthetic A0Like etaS data should use the viscoelastic adaptive engine.');

experimental = struct();
experimental.frequency_Hz = frequency_Hz;
experimental.Cp_mps = CpSynthetic;
experimental.validMask = isfinite(CpSynthetic);
assert(any(experimental.validMask), 'Synthetic fixed-etaS data must contain valid points.');

request = guiBuildFitRequest("mrlfe", ...
    'branchName', branchName, ...
    'mode', "basic", ...
    'experimental', experimental, ...
    'fixedParams', struct('thickness', params.thickness, 'rho', params.rho, 'nu', params.nu), ...
    'freeParams', "mu", ...
    'initialGuess', struct('mu', 55e3), ...
    'bounds', struct('mu', [20e3, 160e3]), ...
    'controls', struct('robustness', "Fast", 'etaS', fixedEtaS, ...
        'fluidDensity', 1000, 'fluidSoundSpeed', 1500, ...
        'mrlfeA0Policy', "physicalTail"), ...
    'fitOptions', struct('useStandardErrorWeights', false, ...
        'optimizerOptions', optimset('Display', 'off', 'MaxIter', 35, 'MaxFunEvals', 80, 'TolX', 1e-5)));

fitOutput = guiFitMRLFESolver(request);
fitResult = fitOutput.fitResult;

assert(isfield(fitResult.fixedParams, 'etaS'), 'GUI mRLFE fit must propagate fixed etaS into fixedParams.');
assert(abs(fitResult.fixedParams.etaS - fixedEtaS) < eps(max(1, fixedEtaS)), 'Fixed etaS value was not preserved.');
assert(isfield(fitResult.allParams, 'etaS'), 'All fitted mRLFE params must include etaS.');
assert(abs(fitResult.allParams.etaS - fixedEtaS) < eps(max(1, fixedEtaS)), 'All params did not preserve fixed etaS.');
assert(fitOutput.routePolicy.actualPath == "viscoelastic_adaptive", 'Fixed etaS mRLFE fit should use the viscoelastic adaptive engine.');
assert(abs(fitResult.bestParams.mu - trueMu) / trueMu < 1e-3, 'GUI mRLFE mu fit did not recover the synthetic value with fixed etaS.');
assert(fitResult.metrics.RMSE < 1e-4, 'GUI mRLFE mu fit RMSE is too high for synthetic fixed-etaS data.');

fprintf('Recovered mu: %.6g kPa\n', fitResult.bestParams.mu / 1e3);
fprintf('Fixed etaS:   %.6g Pa*s\n', fitResult.fixedParams.etaS);
fprintf('Route:        %s\n', fitOutput.routePolicy.actualPath);
fprintf('RMSE:         %.6g m/s\n', fitResult.metrics.RMSE);
fprintf('\nGUI mRLFE fixed etaS fit contract test passed.\n');
end
