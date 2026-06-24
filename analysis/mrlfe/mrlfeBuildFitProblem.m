function problem = mrlfeBuildFitProblem(experimental, fitConfig)
%MRLFEBUILDFITPROBLEM Build an mRLFE dispersion fitting problem.
%
% Required fitConfig fields:
%   freeParams
%
% Optional fitConfig fields:
%   branchName      default "A0Like"
%   fixedParams     fields overriding mrlfeDefaultSweepParams
%   initialGuess    fields for free-parameter initial guesses
%   bounds          fields with [lower upper] bounds
%   solverOptions   mrlfeDefaultSweepOptions-compatible options
%   fitOptions      residual options

if nargin < 2 || ~isstruct(fitConfig)
    error('fitConfig must be provided as a structure.');
end
if ~isfield(fitConfig, 'freeParams') || isempty(fitConfig.freeParams)
    error('fitConfig.freeParams is required.');
end

experimental = validateExperimentalDispersionData(experimental, 1);
if any(diff(experimental.frequency_Hz(experimental.validMask)) < 0)
    error('mRLFE fitting requires valid frequency_Hz values to be sorted ascending.');
end

branchName = getConfigValue(fitConfig, 'branchName', "A0Like");
branchName = string(branchName);

baseParams = mrlfeDefaultSweepParams();
baseParams = applyStructOverrides(baseParams, getConfigValue(fitConfig, 'fixedParams', struct()));
baseParams = applyStructOverrides(baseParams, getConfigValue(fitConfig, 'initialGuess', struct()));

freeParams = string(fitConfig.freeParams(:));
[x0, parameterInfo] = buildParameterVector(baseParams, freeParams);

bounds = getConfigValue(fitConfig, 'bounds', struct());
[lowerBounds, upperBounds] = localBuildBounds(bounds, freeParams);

solverOptions = getConfigValue(fitConfig, 'solverOptions', mrlfeDefaultSweepOptions(branchName, 'EtaS', 0.05));
fitOptions = getConfigValue(fitConfig, 'fitOptions', struct());
if ~isfield(fitOptions, 'useStandardErrorWeights')
    fitOptions.useStandardErrorWeights = false;
end

problem = struct();
problem.modelFamily = "mrlfe";
problem.branchName = branchName;
problem.experimental = experimental;
problem.baseParams = baseParams;
problem.freeParams = freeParams;
problem.x0 = x0;
problem.lowerBounds = lowerBounds;
problem.upperBounds = upperBounds;
problem.parameterInfo = parameterInfo;
problem.solverOptions = solverOptions;
problem.fitOptions = fitOptions;
problem.evaluateModel = @(params) mrlfeEvaluateFitModel(params, experimental.frequency_Hz, branchName, solverOptions);
problem.residualFunction = @(x) localResidualFunction(x, problem);
problem.objectiveFunction = @(x) localObjectiveFunction(x, problem);
end

function residuals = localResidualFunction(x, problem)
params = unpackParameterVector(x, problem.baseParams, problem.freeParams);
CpModel_mps = problem.evaluateModel(params);
residuals = computeDispersionFitResiduals(CpModel_mps, problem.experimental, problem.fitOptions);
end

function value = localObjectiveFunction(x, problem)
if any(x(:) < problem.lowerBounds(:)) || any(x(:) > problem.upperBounds(:))
    value = localPenaltyValue(x, problem);
    return;
end
try
    residuals = problem.residualFunction(x);
    value = sum(residuals(:).^2);
    if ~isfinite(value)
        value = realmax('double') / 1e6;
    end
catch
    value = realmax('double') / 1e6;
end
end

function value = localPenaltyValue(x, problem)
lowerViolation = max(problem.lowerBounds(:) - x(:), 0);
upperViolation = max(x(:) - problem.upperBounds(:), 0);
scale = max(abs(problem.x0(:)), 1);
value = 1e12 * (1 + sum(((lowerViolation + upperViolation) ./ scale).^2));
end

function [lowerBounds, upperBounds] = localBuildBounds(bounds, freeParams)
lowerBounds = -inf(numel(freeParams), 1);
upperBounds = inf(numel(freeParams), 1);
for i = 1:numel(freeParams)
    name = char(freeParams(i));
    if isstruct(bounds) && isfield(bounds, name) && ~isempty(bounds.(name))
        value = bounds.(name);
        if ~isnumeric(value) || numel(value) ~= 2 || value(1) >= value(2)
            error('bounds.%s must be a numeric [lower upper] pair.', name);
        end
        lowerBounds(i) = value(1);
        upperBounds(i) = value(2);
    end
end
end

function s = applyStructOverrides(s, overrides)
if isempty(overrides)
    return;
end
if ~isstruct(overrides) || ~isscalar(overrides)
    error('Parameter overrides must be scalar structures.');
end
names = fieldnames(overrides);
for i = 1:numel(names)
    s.(names{i}) = overrides.(names{i});
end
end

function value = getConfigValue(config, fieldName, defaultValue)
if isstruct(config) && isfield(config, fieldName) && ~isempty(config.(fieldName))
    value = config.(fieldName);
else
    value = defaultValue;
end
end
