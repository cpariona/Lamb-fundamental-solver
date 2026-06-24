function [residuals, residualInfo] = computeDispersionFitResiduals(CpModel_mps, experimental, options)
%COMPUTEDISPERSIONFITRESIDUALS Compute residual vector for dispersion fitting.
%
% By default, residuals are unweighted:
%   residual = CpModel_mps - Cp_exp_mps
%
% If options.useStandardErrorWeights is true, residuals are normalized by
% standardError_Cp_mps for points with valid finite standard error.

if nargin < 3 || isempty(options)
    options = struct();
end
if ~isfield(options, 'useStandardErrorWeights') || isempty(options.useStandardErrorWeights)
    options.useStandardErrorWeights = false;
end

experimental = validateExperimentalDispersionData(experimental, 1);
CpModel_mps = CpModel_mps(:);

if numel(CpModel_mps) ~= experimental.numPoints
    error('CpModel_mps must match the number of experimental points.');
end

validMask = experimental.validMask & isfinite(CpModel_mps);
if ~any(validMask)
    error('No valid model/experimental point pairs are available for residual computation.');
end

rawResiduals = CpModel_mps(validMask) - experimental.Cp_mps(validMask);
weights = ones(size(rawResiduals));

if options.useStandardErrorWeights
    standardError = experimental.standardError_Cp_mps(validMask);
    canUseStandardError = isfinite(standardError) & standardError > 0;
    if ~all(canUseStandardError)
        error('Standard-error weighting requested, but some valid points do not have positive finite standard errors.');
    end
    weights = 1 ./ standardError;
end

residuals = rawResiduals .* weights;

residualInfo = struct();
residualInfo.validMask = validMask;
residualInfo.rawResiduals_mps = rawResiduals;
residualInfo.weights = weights;
residualInfo.weightedResiduals = residuals;
residualInfo.useStandardErrorWeights = logical(options.useStandardErrorWeights);
residualInfo.numResiduals = numel(residuals);
end
