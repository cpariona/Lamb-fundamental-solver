function requestedCurve = guiEvaluateRequestedFitCurve(fitOutput, frequency_Hz)
%GUIEVALUATEREQUESTEDFITTEDCURVE Evaluate solver curve using fitted params.
%
% This helper performs a forward solver evaluation only. It does not call
% guiRunFit and does not run an optimizer. For mRLFE it explicitly uses the
% selected numerical preset rather than the optimized fitting grid.

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
        [Cp_mps, rawResult] = lamb.fitting.rayleigh_lamb.rlEvaluateFitModel(params, frequency_Hz, branchName, options);
    case "mrlfe"
        if ~isfield(options, 'forwardModel') || ~isstruct(options.forwardModel)
            options.forwardModel = struct();
        end
        options.forwardModel.gridPolicy = "numericalPreset";
        [Cp_mps, rawResult] = lamb.fitting.mrlfe.mrlfeEvaluateFitModel(params, frequency_Hz, branchName, options);
    case "acoustoelastic_iop_hgo"
        [Cp_mps, rawResult] = lamb.fitting.acoustoelastic_iop_hgo.aeEvaluateFitModel(params, frequency_Hz, "atlasA0", options);
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
requestedCurve.fitConsistency = localFitConsistency(fitResult, requestedCurve);
requestedCurve.note = "requested solver curve evaluated with fitted parameters; optimizer not rerun";
end

function consistency = localFitConsistency(fitResult, requestedCurve)
consistency = struct();
consistency.available = false;
consistency.maximumRelativeError = nan;
consistency.p95RelativeError = nan;
consistency.medianRelativeError = nan;
consistency.validMaskAgreement = nan;
consistency.accepted = false;

try
    fitFrequency = fitResult.frequency_Hz(:);
    fitCp = fitResult.Cp_fit_mps(:);
    fitValid = logical(fitResult.validMask(:)) & isfinite(fitFrequency) & isfinite(fitCp);
    requestedAtFit = interp1(requestedCurve.frequency_Hz(:), requestedCurve.Cp_mps(:), ...
        fitFrequency, 'linear', nan);
    requestedValidAtFit = interp1(requestedCurve.frequency_Hz(:), ...
        double(requestedCurve.validMask(:)), fitFrequency, 'nearest', 0) > 0.5;
    compareMask = fitValid & requestedValidAtFit & isfinite(requestedAtFit);
    if ~any(compareMask)
        return;
    end
    relativeError = abs(requestedAtFit(compareMask) - fitCp(compareMask)) ./ ...
        max(abs(requestedAtFit(compareMask)), eps);
    consistency.available = true;
    consistency.maximumRelativeError = max(relativeError);
    consistency.p95RelativeError = localPercentile(relativeError, 95);
    consistency.medianRelativeError = median(relativeError);
    consistency.validMaskAgreement = mean(requestedValidAtFit == fitValid);
    consistency.accepted = consistency.maximumRelativeError <= 0.01 && ...
        consistency.p95RelativeError <= 0.005;
catch
end
end

function value = localPercentile(x, percentile)
x = sort(x(:));
if isempty(x)
    value = nan;
    return;
end
position = 1 + (numel(x) - 1) * percentile / 100;
lowerIndex = floor(position);
upperIndex = ceil(position);
if lowerIndex == upperIndex
    value = x(lowerIndex);
else
    fraction = position - lowerIndex;
    value = x(lowerIndex) * (1 - fraction) + x(upperIndex) * fraction;
end
end

function value = localField(s, fieldName, defaultValue)
value = defaultValue;
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = s.(fieldName);
end
end
