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
%
% The viscosity parameter etaS is stored in solverOptions.mrlfeParams by the
% mRLFE solver. For fitting purposes, etaS is mirrored into baseParams so it
% can be packed/unpacked by the shared fitting helpers, then propagated back
% to solverOptions by mrlfeEvaluateFitModel.

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
solverOptions = getConfigValue(fitConfig, 'solverOptions', mrlfeDefaultSweepOptions(branchName, 'EtaS', 0.05));

baseParams = mrlfeDefaultSweepParams();
baseParams.etaS = localEtaSFromOptions(solverOptions);
baseParams = applyStructOverrides(baseParams, getConfigValue(fitConfig, 'fixedParams', struct()));
baseParams = applyStructOverrides(baseParams, getConfigValue(fitConfig, 'initialGuess', struct()));

freeParams = string(fitConfig.freeParams(:));
[x0, parameterInfo] = buildParameterVector(baseParams, freeParams);

bounds = getConfigValue(fitConfig, 'bounds', struct());
[lowerBounds, upperBounds] = localBuildBounds(bounds, freeParams);

fitOptions = getConfigValue(fitConfig, 'fitOptions', struct());
if ~isfield(fitOptions, 'useStandardErrorWeights')
    fitOptions.useStandardErrorWeights = false;
end

[solverOptions, forwardCache] = localAttachForwardCacheIfUseful(solverOptions, baseParams, freeParams, branchName, experimental);

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
problem.forwardCache = forwardCache;
problem.fitOptions = fitOptions;
problem.optimizerOptions = struct( ...
    'fminbnd', optimset('Display', 'off', 'MaxIter', 45, ...
        'MaxFunEvals', 90, 'TolX', 1e-5), ...
    'fminsearch', optimset('Display', 'off', 'MaxIter', 60, ...
        'MaxFunEvals', 160, 'TolX', 1e-5, 'TolFun', 1e-7));
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

function [solverOptions, forwardCache] = localAttachForwardCacheIfUseful(solverOptions, baseParams, freeParams, branchName, experimental)
forwardCache = struct();
forwardCache.enabled = false;
forwardCache.kind = "none";
forwardCache.reason = "not_applicable";

if isfield(solverOptions, 'mrlfeDisableForwardCache') && solverOptions.mrlfeDisableForwardCache
    forwardCache.reason = "disabled_by_option";
    return;
end

if ~(isscalar(freeParams) && freeParams(1) == "etaS")
    forwardCache.reason = "free_parameter_not_etaS_only";
    return;
end

if isfield(solverOptions, 'mrlfeElasticReferenceResult') && ~isempty(solverOptions.mrlfeElasticReferenceResult)
    forwardCache.enabled = true;
    forwardCache.kind = "provided_elastic_reference";
    forwardCache.reason = "caller_provided_reference";
    return;
end

referenceOptions = solverOptions;
if ~isfield(referenceOptions, 'mrlfeParams') || isempty(referenceOptions.mrlfeParams)
    referenceOptions.mrlfeParams = lamb.models.mrlfe.configuration.mrlfeDefaultInternalParameters();
end
referenceOptions.mrlfeParams.etaS = 0;
referenceOptions.mrlfeParams.etaL = 0;
referenceOptions.mrlfeParams.solveComplexK = false;
referenceOptions.mrlfeParams.useComplexLambda = false;

% Build the reference with the maintained elastic settings rather than the fast
% elastic fitting preset. This keeps the cached reference equivalent to the
% reference that the viscous path would otherwise compute internally.
referenceOptions.mrlfeUseFitPerformanceDefaults = false;

referenceParams = baseParams;
referenceParams.etaS = 0;

try
    [~, rawReference] = mrlfeEvaluateFitModel(referenceParams, experimental.frequency_Hz, branchName, referenceOptions);
    if isfield(rawReference, 'elasticReferenceResult') && isstruct(rawReference.elasticReferenceResult)
        solverOptions.mrlfeElasticReferenceResult = rawReference.elasticReferenceResult;
        forwardCache.enabled = true;
        forwardCache.kind = "etaS_elastic_reference";
        forwardCache.reason = "precomputed_elastic_reference";
        forwardCache.frequency_Hz = rawReference.frequencySolve_Hz;
        forwardCache.branchName = branchName;
        forwardCache.referenceParams = referenceParams;
        forwardCache.referenceOptions = localSummarizeReferenceOptions(referenceOptions);
    else
        forwardCache.reason = "reference_missing_mRLFEElasticRealK";
    end
catch exception
    forwardCache.enabled = false;
    forwardCache.kind = "none";
    forwardCache.reason = "reference_precompute_failed";
    forwardCache.errorIdentifier = string(exception.identifier);
    forwardCache.errorMessage = string(exception.message);
end
end

function summary = localSummarizeReferenceOptions(options)
summary = struct();
summary.mrlfeUseFitPerformanceDefaults = getOption(options, 'mrlfeUseFitPerformanceDefaults', []);
summary.mrlfeUseInternalTrackingGrid = getOption(options, 'mrlfeUseInternalTrackingGrid', []);
summary.mrlfeInternalTrackingMinPoints = getOption(options, 'mrlfeInternalTrackingMinPoints', []);
summary.mrlfeInternalTrackingPointFactor = getOption(options, 'mrlfeInternalTrackingPointFactor', []);
summary.trackerCpScanPoints = getOption(options, 'trackerCpScanPoints', []);
end

function etaS = localEtaSFromOptions(options)
etaS = 0;
if isstruct(options) && isfield(options, 'mrlfeParams') && isfield(options.mrlfeParams, 'etaS')
    etaS = options.mrlfeParams.etaS;
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

function value = getOption(options, fieldName, defaultValue)
if isstruct(options) && isfield(options, fieldName) && ~isempty(options.(fieldName))
    value = options.(fieldName);
else
    value = defaultValue;
end
end
