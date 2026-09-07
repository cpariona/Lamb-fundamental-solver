function problem = mrlfeBuildFitProblem(experimental, fitConfig)
%MRLFEBUILDFITPROBLEM Build an mRLFE dispersion fitting problem.
%
% Required fitConfig fields:
%   freeParams
%
% Optional fitConfig fields:
%   branchName      default "A0Like"
%   fixedParams     fields overriding mrlfeDefaultFitParameters
%   initialGuess    fields for free-parameter initial guesses
%   bounds          fields with [lower upper] bounds
%   solverOptions   mrlfeDefaultFitOptions-compatible options
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

experimental = lamb.fitting.validateExperimentalDispersionData(experimental, 1);
if any(diff(experimental.frequency_Hz(experimental.validMask)) < 0)
    error('mRLFE fitting requires valid frequency_Hz values to be sorted ascending.');
end

branchName = lamb.fitting.getFitConfigValue(fitConfig, 'branchName', "A0Like");
branchName = string(branchName);
solverOptions = lamb.fitting.getFitConfigValue(fitConfig, 'solverOptions', ...
    lamb.fitting.mrlfe.mrlfeDefaultFitOptions(branchName, 'EtaS', 0.05));

baseParams = lamb.fitting.mrlfe.mrlfeDefaultFitParameters();
baseParams.etaS = localEtaSFromOptions(solverOptions);
baseParams = lamb.fitting.applyParameterOverrides(baseParams, ...
    lamb.fitting.getFitConfigValue(fitConfig, 'fixedParams', struct()));
baseParams = lamb.fitting.applyParameterOverrides(baseParams, ...
    lamb.fitting.getFitConfigValue(fitConfig, 'initialGuess', struct()));

freeParams = string(fitConfig.freeParams(:));
[x0, parameterInfo] = lamb.fitting.buildParameterVector(baseParams, freeParams);

bounds = lamb.fitting.getFitConfigValue(fitConfig, 'bounds', struct());
[lowerBounds, upperBounds] = lamb.fitting.buildParameterBounds(bounds, freeParams);

fitOptions = lamb.fitting.getFitConfigValue(fitConfig, 'fitOptions', struct());
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
problem.evaluateModel = @(params) lamb.fitting.mrlfe.mrlfeEvaluateFitModel(params, experimental.frequency_Hz, branchName, solverOptions);
problem.residualFunction = @(x) localResidualFunction(x, problem);
problem.objectiveFunction = @(x) lamb.fitting.evaluateBoundedObjective(x, problem);
end

function residuals = localResidualFunction(x, problem)
params = lamb.fitting.unpackParameterVector(x, problem.baseParams, problem.freeParams);
CpModel_mps = problem.evaluateModel(params);
residuals = lamb.fitting.computeDispersionFitResiduals(CpModel_mps, problem.experimental, problem.fitOptions);
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
    [~, rawReference] = lamb.fitting.mrlfe.mrlfeEvaluateFitModel(referenceParams, experimental.frequency_Hz, branchName, referenceOptions);
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

function value = getOption(options, fieldName, defaultValue)
if isstruct(options) && isfield(options, fieldName) && ~isempty(options.(fieldName))
    value = options.(fieldName);
else
    value = defaultValue;
end
end
