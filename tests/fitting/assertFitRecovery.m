function row = assertFitRecovery(testName, trueValue, fittedValue, relativeTolerance, fitResult, maxRMSE, minValidPoints)
%ASSERTFITRECOVERY Validate and summarize one synthetic fitting recovery case.
%
% row = assertFitRecovery(testName, trueValue, fittedValue, relativeTolerance, fitResult, maxRMSE, minValidPoints)

if nargin < 6 || isempty(maxRMSE)
    maxRMSE = inf;
end
if nargin < 7 || isempty(minValidPoints)
    minValidPoints = 1;
end

testName = string(testName);
relativeError = abs(fittedValue - trueValue) / max(abs(trueValue), eps);
validPoints = nnz(fitResult.validMask);

assert(isfinite(fittedValue), '%s fitted value must be finite.', testName);
assert(relativeError <= relativeTolerance, ...
    '%s relative error %.6g exceeded tolerance %.6g.', testName, relativeError, relativeTolerance);
assert(fitResult.metrics.RMSE <= maxRMSE, ...
    '%s RMSE %.6g exceeded tolerance %.6g m/s.', testName, fitResult.metrics.RMSE, maxRMSE);
assert(validPoints >= minValidPoints, ...
    '%s valid point count %d is below required minimum %d.', testName, validPoints, minValidPoints);
assert(any(isfinite(fitResult.Cp_fit_mps(fitResult.validMask))), ...
    '%s fitted Cp contains no finite valid points.', testName);

row = table(testName, trueValue, fittedValue, relativeError, fitResult.metrics.RMSE, validPoints, ...
    string(fitResult.identifiability.classification), string(fitResult.optimizer.name), ...
    'VariableNames', {'TestName', 'TrueValue', 'FittedValue', 'RelativeError', 'RMSE_mps', 'ValidPoints', 'Identifiability', 'Optimizer'});
end
