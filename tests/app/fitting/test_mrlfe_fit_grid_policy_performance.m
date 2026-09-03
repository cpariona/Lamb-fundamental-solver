clear; clc;
configureTestPath;
fprintf('\nRunning lightweight mRLFE fit-grid characterization...\n');
fprintf('---------------------------------------------------\n');

cases = [ ...
    struct('label', "A0 elastic", 'branchName', "A0Like", 'etaS', 0.00, 'mu_Pa', 75e3, ...
        'frequency_Hz', [1000; 1750; 2500; 3250; 4000]), ...
    struct('label', "A0 viscous", 'branchName', "A0Like", 'etaS', 0.10, 'mu_Pa', 75e3, ...
        'frequency_Hz', [1000; 1750; 2500; 3250; 4000]), ...
    struct('label', "S0 elastic", 'branchName', "S0Like", 'etaS', 0.00, 'mu_Pa', 90e3, ...
        'frequency_Hz', [1000; 2500; 4000; 5500; 7000]) ...
    ];

results = repmat(struct(), numel(cases), 1);
maxAllowedRelativeError = 5e-3;

for iCase = 1:numel(cases)
    c = cases(iCase);

    params = mrlfeDefaultSweepParams();
    params.mu = c.mu_Pa;
    params.etaS = c.etaS;
    params.thickness = 0.5e-3;
    params.rho = 1070;
    params.nu = 0.4999;

    options = mrlfeDefaultSweepOptions(c.branchName, 'EtaS', c.etaS, 'A0Policy', "physicalTail");
    options.executionProfile = "Fast";
    options.effectiveExecutionProfile = "Fast";
    options.robustness = "Fast";
    options.forwardModel = struct('gridPolicy', "fitOptimized", ...
        'minimumPointCount', 12, 'maximumPointCount', 40, 'maximumStep_Hz', 250);

    t = tic;
    [CpOptimized_mps, rawOptimized] = mrlfeEvaluateFitModel( ...
        params, c.frequency_Hz, c.branchName, options);
    optimizedSeconds = toc(t);

    presetOptions = options;
    presetOptions.forwardModel.gridPolicy = "numericalPreset";
    t = tic;
    [CpPreset_mps, rawPreset] = mrlfeEvaluateFitModel( ...
        params, c.frequency_Hz, c.branchName, presetOptions);
    presetSeconds = toc(t);

    validOptimized = logical(rawOptimized.validMask(:)) & isfinite(CpOptimized_mps(:));
    validPreset = logical(rawPreset.validMask(:)) & isfinite(CpPreset_mps(:));
    validMaskDifferences = nnz(validOptimized ~= validPreset);
    comparable = validOptimized & validPreset;
    assert(any(comparable), '%s produced no comparable finite points.', c.label);

    relativeError = abs(CpOptimized_mps(comparable) - CpPreset_mps(comparable)) ./ ...
        max(abs(CpPreset_mps(comparable)), eps);
    maxRelativeError = max(relativeError);

    optimizedPointCount = numel(rawOptimized.frequencySolve_Hz);
    presetPointCount = numel(rawPreset.frequencySolve_Hz);
    speedup = presetSeconds / max(optimizedSeconds, eps);

    results(iCase).label = c.label;
    results(iCase).optimizedSeconds = optimizedSeconds;
    results(iCase).presetSeconds = presetSeconds;
    results(iCase).speedup = speedup;
    results(iCase).optimizedPointCount = optimizedPointCount;
    results(iCase).presetPointCount = presetPointCount;
    results(iCase).maxRelativeError = maxRelativeError;
    results(iCase).validMaskDifferences = validMaskDifferences;

    fprintf('%-11s | optimized %.3f s (%d pts) | preset %.3f s (%d pts) | %.3fx | err %.4g | mask diff %d\n', ...
        c.label, optimizedSeconds, optimizedPointCount, presetSeconds, presetPointCount, ...
        speedup, maxRelativeError, validMaskDifferences);

    assert(optimizedPointCount <= 40, ...
        '%s fitOptimized grid exceeded its configured point limit.', c.label);
    assert(rawOptimized.fitGrid.gridPolicy == "fitOptimized", ...
        '%s optimized grid-policy metadata mismatch.', c.label);
    assert(rawPreset.fitGrid.gridPolicy == "numericalPreset", ...
        '%s preset grid-policy metadata mismatch.', c.label);
    assert(validMaskDifferences == 0, ...
        '%s changed valid masks relative to the Fast preset.', c.label);
    assert(maxRelativeError <= maxAllowedRelativeError, ...
        '%s exceeded the %.3g relative Cp error limit.', c.label, maxAllowedRelativeError);
end

fprintf('Worst relative Cp difference: %.6g\n', max([results.maxRelativeError]));
fprintf('Minimum measured speedup: %.3fx\n', min([results.speedup]));
fprintf('Lightweight mRLFE fit-grid characterization passed.\n');
