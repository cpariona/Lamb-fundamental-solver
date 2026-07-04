function requestedCurve = guiEvaluateRequestedFitCurve(fitOutput, frequency_Hz)
%GUIEVALUATEREQUESTEDFITTEDCURVE Evaluate solver curve using fitted params.
%
% This helper performs a forward solver evaluation only. It does not call
% guiRunFit and does not run an optimizer.

if nargin < 2 || isempty(frequency_Hz)
    error('guiEvaluateRequestedFitCurve:MissingFrequency', ...
        'frequency_Hz must be provided.');
end
frequency_Hz = frequency_Hz(:);
if any(~isfinite(frequency_Hz)) || any(frequency_Hz <= 0)
    error('guiEvaluateRequestedFitCurve:InvalidFrequency', ...
        'Requested curve frequencies must be finite and positive.');
end
if ~isfield(fitOutput, 'fitResult') || ~isstruct(fitOutput.fitResult)
    error('guiEvaluateRequestedFitCurve:MissingFitResult', ...
        'fitOutput.fitResult is required.');
end

fitResult = fitOutput.fitResult;
modelFamily = string(fitResult.modelFamily);
branchName = string(fitResult.branchName);
params = fitResult.allParams;
options = fitResult.problem.solverOptions;

tCurve = tic;
switch modelFamily
    case "rayleigh_lamb"
        [Cp_mps, rawResult] = rlEvaluateFitModel(params, frequency_Hz, branchName, options);
    case "mrlfe"
        [Cp_mps, rawResult] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, options);
    case "acoustoelastic_iop_hgo"
        [Cp_mps, rawResult] = aeEvaluateFitModel(params, frequency_Hz, "atlasA0", options);
        branchName = "atlasA0";
    otherwise
        error('guiEvaluateRequestedFitCurve:UnsupportedModel', ...
            'Unsupported fitting model family: %s.', modelFamily);
end
elapsedSeconds = toc(tCurve);

validMask = isfinite(Cp_mps(:));
if isstruct(rawResult) && isfield(rawResult, 'validMask') && numel(rawResult.validMask) == numel(validMask)
    validMask = validMask & logical(rawResult.validMask(:));
end

requestedCurve = struct();
requestedCurve.modelFamily = modelFamily;
requestedCurve.branchName = branchName;
requestedCurve.frequency_Hz = frequency_Hz;
requestedCurve.Cp_mps = Cp_mps(:);
requestedCurve.validMask = validMask(:);
requestedCurve.elapsedSeconds = elapsedSeconds;
requestedCurve.rawResult = rawResult;
requestedCurve.executionProfile = localField(fitOutput, 'executionProfile', struct());
requestedCurve.routePolicy = localField(fitOutput, 'routePolicy', struct());
requestedCurve.note = "requested solver curve evaluated with fitted parameters; optimizer not rerun";
end

function value = localField(s, fieldName, defaultValue)
value = defaultValue;
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = s.(fieldName);
end
end
