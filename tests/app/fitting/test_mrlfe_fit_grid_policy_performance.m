clear; clc;
startup

fprintf('\nRunning mRLFE fit-grid performance characterization...\n');
fprintf('----------------------------------------------------\n');

params = mrlfeDefaultSweepParams();
params.mu = 75e3;
params.thickness = 0.5e-3;
params.rho = 1070;
params.nu = 0.4999;
frequency_Hz = [1000; 1750; 2500; 3250; 4000];

options = mrlfeDefaultSweepOptions("A0Like", 'EtaS', 0.05, 'A0Policy', "physicalTail");
options.executionProfile = "Fast";
options.effectiveExecutionProfile = "Fast";
options.robustness = "Fast";
options.forwardModel = struct('gridPolicy', "fitOptimized", ...
    'minimumPointCount', 12, 'maximumPointCount', 40, 'maximumStep_Hz', 250);

 t = tic;
[CpOptimized_mps, rawOptimized] = mrlfeEvaluateFitModel(params, frequency_Hz, "A0Like", options);
optimizedSeconds = toc(t);

presetOptions = options;
presetOptions.forwardModel.gridPolicy = "numericalPreset";
 t = tic;
[CpPreset_mps, rawPreset] = mrlfeEvaluateFitModel(params, frequency_Hz, "A0Like", presetOptions);
presetSeconds = toc(t);

valid = isfinite(CpOptimized_mps) & isfinite(CpPreset_mps);
assert(any(valid), 'Both grid policies must produce comparable finite points.');
relativeError = abs(CpOptimized_mps(valid) - CpPreset_mps(valid)) ./ ...
    max(abs(CpPreset_mps(valid)), eps);

optimizedPointCount = numel(rawOptimized.frequencySolve_Hz);
presetPointCount = numel(rawPreset.frequencySolve_Hz);
speedup = presetSeconds / max(optimizedSeconds, eps);

fprintf('fitOptimized:    %.3f s, %d internal points\n', optimizedSeconds, optimizedPointCount);
fprintf('numericalPreset: %.3f s, %d internal points\n', presetSeconds, presetPointCount);
fprintf('Measured speedup: %.3fx\n', speedup);
fprintf('Maximum relative Cp difference: %.6g\n', max(relativeError));

assert(optimizedPointCount <= 40, ...
    'fitOptimized must respect its configured internal point limit.');
assert(rawOptimized.fitGrid.gridPolicy == "fitOptimized", ...
    'Optimized evaluation grid-policy metadata mismatch.');
assert(rawPreset.fitGrid.gridPolicy == "numericalPreset", ...
    'Preset evaluation grid-policy metadata mismatch.');

fprintf('mRLFE fit-grid performance characterization passed.\n');
