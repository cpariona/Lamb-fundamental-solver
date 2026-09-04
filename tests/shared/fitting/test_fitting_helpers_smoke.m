clear; clc;
if isempty(which('mrlfeSolve'))
    configureTestPath;
end

fprintf('\nRunning fitting helper smoke test...\n');
fprintf('------------------------------------\n');

experimental = struct();
experimental.frequency_Hz = [1000 2000 3000 4000];
experimental.Cp_mps = [1.0 1.5 2.0 2.5];
experimental.standardError_Cp_mps = [0.1 0.2 0.3 0.4];
experimental.validMask = [true true false true];

normalized = normalizeExperimentalDispersionData(experimental);
assert(isequal(size(normalized.frequency_Hz), [4 1]), 'frequency_Hz must be normalized to a column vector.');
assert(isequal(size(normalized.Cp_mps), [4 1]), 'Cp_mps must be normalized to a column vector.');
assert(normalized.numPoints == 4, 'Unexpected number of normalized points.');
assert(normalized.numValidPoints == 3, 'Unexpected number of valid normalized points.');

validated = validateExperimentalDispersionData(experimental, 3);
assert(validated.numValidPoints == 3, 'Validation should preserve valid point count.');

CpModel_mps = [1.1 1.4 2.2 2.7];
[residuals, residualInfo] = computeDispersionFitResiduals(CpModel_mps, experimental);
assertNumericClose(residuals, [0.1; -0.1; 0.2], 1e-12, 'Unexpected unweighted residuals.');
assert(residualInfo.numResiduals == 3, 'Unexpected number of residuals.');

weightedOptions = struct('useStandardErrorWeights', true);
[weightedResiduals, weightedInfo] = computeDispersionFitResiduals(CpModel_mps, experimental, weightedOptions);
assertNumericClose(weightedResiduals, [1.0; -0.5; 0.5], 1e-12, 'Unexpected standard-error weighted residuals.');
assert(weightedInfo.useStandardErrorWeights, 'Weighted residual info did not preserve weighting flag.');

metrics = computeDispersionFitMetrics(CpModel_mps, experimental);
assert(metrics.NumValid == 3, 'Unexpected metric valid count.');
assert(metrics.RMSE > 0 && metrics.MAE > 0, 'Metrics should report positive residual errors.');
assert(isfinite(metrics.NRMSE_MeanAbs), 'Mean-normalized RMSE should be finite.');

params = struct('mu', 50e3, 'thickness', 550e-6, 'rho', 1060);
[x, parameterInfo] = buildParameterVector(params, ["mu", "thickness"]);
assertNumericClose(x, [50e3; 550e-6], 1e-12, 'Unexpected parameter vector.');
assert(parameterInfo.numParameters == 2, 'Unexpected parameter count.');

updatedParams = unpackParameterVector([75e3; 600e-6], params, ["mu", "thickness"]);
assertNumericClose(updatedParams.mu, 75e3, 1e-12, 'mu was not unpacked correctly.');
assertNumericClose(updatedParams.thickness, 600e-6, 1e-12, 'thickness was not unpacked correctly.');
assertNumericClose(updatedParams.rho, params.rho, 1e-12, 'Fixed parameter rho should not change.');

baseParams = struct('a', 2, 'b', 0.5);
evaluateFcn = @(p) p.a + p.b .* (normalized.frequency_Hz ./ 1000);
[S, sensitivityInfo] = estimateLocalSensitivity(evaluateFcn, baseParams, ["a", "b"], normalized);
assert(isequal(size(S), [3 2]), 'Unexpected sensitivity matrix size.');
assertNumericClose(S(:, 1), ones(3, 1), 1e-6, 'Unexpected sensitivity to a.');
assertNumericClose(S(:, 2), [1; 2; 4], 1e-6, 'Unexpected sensitivity to b.');
assert(sensitivityInfo.numValidPoints == 3, 'Unexpected sensitivity valid point count.');

identifiability = assessFitIdentifiability(S, ["a", "b"]);
assert(identifiability.numParameters == 2, 'Unexpected identifiability parameter count.');
assert(identifiability.rank == 2, 'Sensitivity matrix should be full rank.');
assert(identifiability.classification == "locally_identifiable", 'Expected locally identifiable synthetic case.');

fprintf('\nFitting helper smoke test passed.\n');

function assertNumericClose(actual, expected, tol, message)
actual = actual(:);
expected = expected(:);
assert(isequal(size(actual), size(expected)), message);
assert(max(abs(actual - expected)) <= tol, message);
end
