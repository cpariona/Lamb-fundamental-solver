clear; clc;
startup

fprintf('\nRunning fit display-curve no-solver contract test...\n');
fprintf('--------------------------------------------------\n');

fitResult = struct();
fitResult.modelFamily = "mrlfe";
fitResult.branchName = "A0Like";
fitResult.frequency_Hz = [1000; 2000; 3000; 4000];
fitResult.Cp_fit_mps = [2.0; 2.4; 2.8; 3.1];
fitResult.validMask = true(4, 1);

curve = guiBuildFitDisplayCurve(fitResult, 80);

assert(curve.source == "fitObjectiveInterpolation", ...
    'Display curve source metadata mismatch.');
assert(curve.solverEvaluated == false, ...
    'Display curve must not report a solver evaluation.');
assert(numel(curve.frequency_Hz) == 80, ...
    'Display curve should use the requested plotting point count.');
assert(all(isfinite(curve.Cp_mps(curve.validMask))), ...
    'Display curve interpolation must be finite on valid points.');
assert(isempty(curve.denseSolver.frequency_Hz), ...
    'Automatic dense solver evaluation must remain absent.');
assert(contains(curve.extension.errorMessage, "explicit user request"), ...
    'Display curve must state that full evaluation is user-triggered.');

fprintf('Fit display-curve no-solver contract test passed.\n');
