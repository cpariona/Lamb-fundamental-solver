function [residuals, residualInfo] = computeDispersionFitResiduals(CpModel_mps, experimental, options)
%COMPUTEDISPERSIONFITRESIDUALS Compute residual vector for dispersion fitting.
%
% The objective mask is fixed by experimental.validMask. Every selected
% experimental point must have a finite model prediction; model-dependent
% dropping of points is not allowed.
%
% By default, residuals are unweighted:
%   residual = CpModel_mps - Cp_exp_mps
%
% If options.useStandardErrorWeights is true, residuals are normalized by
% standardError_Cp_mps for every point in the fixed objective mask.

if nargin < 3 || isempty(options)
    options = struct();
end
if ~isfield(options, 'useStandardErrorWeights') || isempty(options.useStandardErrorWeights)
    options.useStandardErrorWeights = false;
end

[coverage, experimental] = lamb.fitting.validateDispersionFitCoverage(CpModel_mps, experimental);
CpModel_mps = CpModel_mps(:);
objectiveMask = coverage.objectiveMask;

rawResiduals = CpModel_mps(objectiveMask) - experimental.Cp_mps(objectiveMask);
weights = ones(size(rawResiduals));

if options.useStandardErrorWeights
    standardError = experimental.standardError_Cp_mps(objectiveMask);
    canUseStandardError = isfinite(standardError) & standardError > 0;
    if ~all(canUseStandardError)
        error('Standard-error weighting requested, but some objective points do not have positive finite standard errors.');
    end
    weights = 1 ./ standardError;
end

residuals = rawResiduals .* weights;

residualInfo = struct();
residualInfo.validMask = objectiveMask;
residualInfo.objectiveMask = coverage.objectiveMask;
residualInfo.modelFiniteMask = coverage.modelFiniteMask;
residualInfo.missingModelMask = coverage.missingModelMask;
residualInfo.expectedPointCount = coverage.expectedPointCount;
residualInfo.evaluatedPointCount = coverage.evaluatedPointCount;
residualInfo.coverageAccepted = coverage.coverageAccepted;
residualInfo.rawResiduals_mps = rawResiduals;
residualInfo.weights = weights;
residualInfo.weightedResiduals = residuals;
residualInfo.useStandardErrorWeights = logical(options.useStandardErrorWeights);
residualInfo.numResiduals = numel(residuals);
end
