clear; clc;
startup

fprintf('\nRunning mRLFE public-solver fit parameter regression test...\n');
fprintf('----------------------------------------------------------\n');

cases = [
    struct('branchName', "A0Like", 'freeParam', "mu",   'etaS', 0.00, 'trueMu', 90e3, 'maxIter', 10, 'maxEval', 24)
    struct('branchName', "A0Like", 'freeParam', "etaS", 'etaS', 0.10, 'trueMu', 75e3, 'maxIter', 10, 'maxEval', 24)
    struct('branchName', "S0Like", 'freeParam', "mu",   'etaS', 0.00, 'trueMu', 90e3, 'maxIter', 6,  'maxEval', 14)
    struct('branchName', "S0Like", 'freeParam', "etaS", 'etaS', 0.10, 'trueMu', 75e3, 'maxIter', 6,  'maxEval', 14)
];

for iCase = 1:numel(cases)
    c = cases(iCase);
    frequency_Hz = linspace(1000, 7000, 10).';
    params = mrlfeDefaultSweepParams();
    params.mu = c.trueMu;
    params.etaS = c.etaS;
    params.thickness = 0.5e-3;
    params.rho = 1070;
    params.nu = 0.4999;

    solverOptions = mrlfeDefaultSweepOptions(c.branchName, 'EtaS', c.etaS, ...
        'A0Policy', "physicalTail");
    [CpSynthetic_mps, rawSynthetic] = mrlfeEvaluateFitModel(params, frequency_Hz, c.branchName, solverOptions);
    assert(rawSynthetic.evaluationPath.usedPublicSolver == true, 'Synthetic setup must use public solver.');

    experimental = struct();
    experimental.frequency_Hz = frequency_Hz;
    experimental.Cp_mps = CpSynthetic_mps;
    experimental.validMask = isfinite(CpSynthetic_mps);
    assert(any(experimental.validMask), 'Synthetic fit data must contain finite points.');

    if c.freeParam == "mu"
        fixedParams = struct('thickness', params.thickness, 'rho', params.rho, 'nu', params.nu, 'etaS', c.etaS);
        initialGuess = struct('mu', c.trueMu);
        bounds = struct('mu', [0.8 * c.trueMu, 1.2 * c.trueMu]);
    else
        fixedParams = struct('mu', c.trueMu, 'thickness', params.thickness, 'rho', params.rho, 'nu', params.nu);
        initialGuess = struct('etaS', c.etaS);
        bounds = struct('etaS', [0.0, 0.30]);
    end

    request = guiBuildFitRequest("mrlfe", ...
        'branchName', c.branchName, ...
        'mode', "basic", ...
        'experimental', experimental, ...
        'fixedParams', fixedParams, ...
        'freeParams', c.freeParam, ...
        'initialGuess', initialGuess, ...
        'bounds', bounds, ...
        'controls', struct('robustness', "Fast", 'etaS', c.etaS, ...
            'fluidDensity', 1000, 'fluidSoundSpeed', 1500, ...
            'mrlfeA0Policy', "physicalTail"), ...
        'fitOptions', struct('useStandardErrorWeights', false, ...
            'optimizerOptions', optimset('Display', 'off', 'MaxIter', c.maxIter, ...
            'MaxFunEvals', c.maxEval, 'TolX', 1e-5)));

    fitOutput = guiFitMRLFESolver(request);
    fitResult = fitOutput.fitResult;
    evaluation = fitResult.modelEvaluation;

    assert(isfield(evaluation, 'modelResult'), 'Fit result must preserve public model result.');
    assert(evaluation.evaluationPath.usedPublicSolver == true, 'Objective evaluation must use public solver.');
    assert(evaluation.evaluationPath.gridPolicy == "fitOptimized", ...
        'Fit objective must use the fitOptimized grid policy.');
    assert(evaluation.modelResult.execution.effectivePreset == "fast", 'Fit objective must use fast preset metadata.');
    assert(evaluation.modelResult.fallback.applied == false, 'Fit objective must not apply fallback.');
    assert(any(evaluation.modelResult.execution.internalEngine == ["elastic_adaptive", "viscoelastic_adaptive"]), ...
        'Fit objective must expose neutral engine metadata.');
    assert(fitResult.optimizer.output.funcCount > 0, 'Optimizer diagnostics must report evaluations.');
    assert(isfinite(fitResult.optimizer.objective), 'Objective value must be finite.');
    assert(all(fitResult.xBest(:) >= fitResult.lowerBounds(:) - eps) && ...
        all(fitResult.xBest(:) <= fitResult.upperBounds(:) + eps), ...
        'Fitted parameters must remain within bounds.');

    if c.freeParam == "mu"
        assert(abs(fitResult.bestParams.mu - c.trueMu) / c.trueMu < 1e-3, ...
            'Synthetic mu fit did not recover the true value.');
        assert(abs(fitResult.fixedParams.etaS - c.etaS) <= eps(max(1, c.etaS)), ...
            'Fixed etaS changed during mu fit.');
    else
        assert(isfield(fitResult.bestParams, 'etaS'), 'etaS fit must report fitted etaS.');
        assert(fitResult.bestParams.etaS >= bounds.etaS(1) && fitResult.bestParams.etaS <= bounds.etaS(2), ...
            'Fitted etaS must stay within bounds.');
        assert(abs(fitResult.fixedParams.mu - c.trueMu) <= eps(max(1, c.trueMu)), ...
            'Fixed mu changed during etaS fit.');
    end

    displayCurve = fitOutput.normalized.fullCurve;
    assert(isfield(displayCurve, 'solverEvaluated') && displayCurve.solverEvaluated == false, ...
        'Post-fit display curve must not evaluate the solver automatically.');
    assert(isfield(displayCurve, 'source') && displayCurve.source == "fitObjectiveInterpolation", ...
        'Post-fit display curve must be identified as objective interpolation.');
    assert(isfield(displayCurve, 'denseSolver') && isempty(displayCurve.denseSolver.rawResult), ...
        'Automatic dense solver diagnostics must remain empty.');

    requestedFrequency_Hz = linspace(min(frequency_Hz), max(frequency_Hz), 12).';
    requestedCurve = guiEvaluateRequestedFitCurve(fitOutput, requestedFrequency_Hz);
    assert(isfield(requestedCurve.rawResult, 'modelResult'), ...
        'Requested fitted curve must preserve public model result.');
    assert(requestedCurve.rawResult.evaluationPath.usedPublicSolver == true, ...
        'Requested fitted curve must use public solver.');
    assert(requestedCurve.rawResult.evaluationPath.gridPolicy == "numericalPreset", ...
        'Requested fitted curve must use the numericalPreset grid policy.');
    assert(requestedCurve.rawResult.modelResult.execution.effectivePreset == raw.modelResult.execution.effectivePreset, ...
        'Requested fitted curve must use the same effective preset as objective evaluation.');
    assert(requestedCurve.rawResult.modelResult.fallback.applied == false, ...
        'Requested fitted curve must not apply fallback.');
    if c.freeParam == "mu"
        assert(abs(requestedCurve.rawResult.modelResult.configuration.effective.parameters.mu_Pa - fitResult.bestParams.mu) <= ...
            eps(max(1, fitResult.bestParams.mu)), ...
            'Requested fitted curve must use final fitted mu.');
    else
        assert(abs(requestedCurve.rawResult.modelResult.configuration.effective.parameters.etaS_Pas - fitResult.bestParams.etaS) <= ...
            eps(max(1, fitResult.bestParams.etaS)), ...
            'Requested fitted curve must use final fitted etaS.');
    end

    fprintf('%s fit %s | objective %.6g | evaluations %d | route %s | engine %s\n', ...
        c.branchName, c.freeParam, fitResult.optimizer.objective, ...
        fitResult.optimizer.output.funcCount, evaluation.evaluationPath.path, ...
        evaluation.modelResult.execution.internalEngine);
end

fprintf('\nmRLFE public-solver fit parameter regression test passed.\n');
