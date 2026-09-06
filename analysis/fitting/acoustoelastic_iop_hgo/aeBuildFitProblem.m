function problem = aeBuildFitProblem(experimental, fitConfig)
%AEBUILDFITPROBLEM Build an AE IOP/HGO atlasA0 dispersion fitting problem.
%
% Required fitConfig fields:
%   freeParams
%
% Optional fitConfig fields:
%   branchName      default "atlasA0"
%   fixedParams     fields overriding aeDefaultSweepParams
%   initialGuess    fields for free-parameter initial guesses
%   bounds          fields with [lower upper] bounds
%   solverOptions   aeDefaultSweepOptions-compatible options
%   fitOptions      residual options

if nargin < 2 || ~isstruct(fitConfig)
    error('fitConfig must be provided as a structure.');
end
if ~isfield(fitConfig, 'freeParams') || isempty(fitConfig.freeParams)
    error('fitConfig.freeParams is required.');
end

experimental = validateExperimentalDispersionData(experimental, 1);

branchName = getConfigValue(fitConfig, 'branchName', "atlasA0");
branchName = aeNormalizeBranchPolicy(branchName);
if branchName ~= "atlasA0"
    error('AE IOP/HGO fitting supports only atlasA0.');
end

baseParams = aeDefaultSweepParams();
baseParams = applyStructOverrides(baseParams, getConfigValue(fitConfig, 'fixedParams', struct()));
baseParams = applyStructOverrides(baseParams, getConfigValue(fitConfig, 'initialGuess', struct()));

freeParams = string(fitConfig.freeParams(:));
[x0, parameterInfo] = buildParameterVector(baseParams, freeParams);

bounds = getConfigValue(fitConfig, 'bounds', struct());
[lowerBounds, upperBounds] = localBuildBounds(bounds, freeParams);

solverOptions = getConfigValue(fitConfig, 'solverOptions', aeDefaultSweepOptions("Fast"));
solverOptions.atlasBranchPolicy = "atlasA0";

fitOptions = getConfigValue(fitConfig, 'fitOptions', struct());
if ~isfield(fitOptions, 'useStandardErrorWeights')
    fitOptions.useStandardErrorWeights = false;
end

problem = struct();
problem.modelFamily = "acoustoelastic_iop_hgo";
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
problem.optimizerOptions = struct( ...
    'fminbnd', optimset('Display', 'off', 'MaxIter', 25, ...
        'MaxFunEvals', 55, 'TolX', 1e-4), ...
    'fminsearch', optimset('Display', 'off', 'MaxIter', 45, ...
        'MaxFunEvals', 120, 'TolX', 1e-4, 'TolFun', 1e-6));
problem.evaluateModel = @(params) aeEvaluateFitModel(params, experimental.frequency_Hz, branchName, solverOptions);
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
