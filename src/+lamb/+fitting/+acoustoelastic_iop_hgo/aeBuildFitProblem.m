function problem = aeBuildFitProblem(experimental, fitConfig)
%AEBUILDFITPROBLEM Build an AE IOP/HGO atlasA0 dispersion fitting problem.
%
% Required fitConfig fields:
%   freeParams
%
% Optional fitConfig fields:
%   branchName      default "atlasA0"
%   fixedParams     fields overriding aeDefaultFitParameters
%   initialGuess    fields for free-parameter initial guesses
%   bounds          fields with [lower upper] bounds
%   solverOptions   aeDefaultFitOptions-compatible options
%   fitOptions      residual options

if nargin < 2 || ~isstruct(fitConfig)
    error('fitConfig must be provided as a structure.');
end
if ~isfield(fitConfig, 'freeParams') || isempty(fitConfig.freeParams)
    error('fitConfig.freeParams is required.');
end
suppliedMask = [];
if isfield(experimental, 'validMask') && ~isempty(experimental.validMask)
    suppliedMask = logical(experimental.validMask(:));
end
experimental = lamb.fitting.validateExperimentalDispersionData(experimental, 1);
if ~isempty(suppliedMask) && ~isequal(suppliedMask, experimental.validMask)
    error('lamb:fitting:AEInvalidSelectedObservation', ...
        'Selected observations require positive finite Hz and finite Cp; validMask cannot be repaired.');
end
% Explicitly excluded nonpositive/nonfinite rows (e.g. DC) stay in the
% experimental/result arrays but are never sent to the native evaluator.
frequency = experimental.frequency_Hz;
admissible = isfinite(frequency) & frequency > 0;
if ~all(admissible) && isempty(suppliedMask)
    error('lamb:fitting:AEInvalidSelectedObservation', ...
        'Nonpositive/nonfinite Hz require explicit validMask=false; exclusions are not inferred.');
end

branchName = lamb.fitting.getFitConfigValue(fitConfig, 'branchName', "atlasA0");
branchName = lamb.models.acoustoelastic_iop_hgo.configuration.aeNormalizeBranchPolicy(branchName);
if branchName ~= "atlasA0"
    error('AE IOP/HGO fitting supports only atlasA0.');
end

baseParams = lamb.fitting.acoustoelastic_iop_hgo.aeDefaultFitParameters();
baseParams = lamb.fitting.applyParameterOverrides(baseParams, ...
    lamb.fitting.getFitConfigValue(fitConfig, 'fixedParams', struct()));
baseParams = lamb.fitting.applyParameterOverrides(baseParams, ...
    lamb.fitting.getFitConfigValue(fitConfig, 'initialGuess', struct()));

freeParams = string(fitConfig.freeParams(:));
[x0, parameterInfo] = lamb.fitting.buildParameterVector(baseParams, freeParams);

bounds = lamb.fitting.getFitConfigValue(fitConfig, 'bounds', struct());
[lowerBounds, upperBounds] = lamb.fitting.buildParameterBounds(bounds, freeParams);

solverOptions = lamb.fitting.getFitConfigValue(fitConfig, 'solverOptions', ...
    lamb.fitting.acoustoelastic_iop_hgo.aeDefaultFitOptions("Fast"));
solverOptions.atlasBranchPolicy = "atlasA0";
validateObjectiveFrequencySupport(experimental, solverOptions);

fitOptions = lamb.fitting.getFitConfigValue(fitConfig, 'fitOptions', struct());
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
if all(admissible)
    problem.evaluateModel = @(params) lamb.fitting.acoustoelastic_iop_hgo.aeEvaluateFitModel(params, frequency, branchName, solverOptions);
else
    problem.evaluateModel = @(params) localEvaluateExcludedRows(params, frequency, admissible, branchName, solverOptions);
end
problem.residualFunction = @(x) localResidualFunction(x, problem);
problem.objectiveFunction = @(x) lamb.fitting.evaluateBoundedObjective(x, problem);
end

function [Cp_mps, rawResult] = localEvaluateExcludedRows(params, frequency, admissible, branchName, options)
[values, rawResult] = lamb.fitting.acoustoelastic_iop_hgo.aeEvaluateFitModel( ...
    params, frequency(admissible), branchName, options);
Cp_mps = nan(size(frequency));
Cp_mps(admissible) = values;
available = false(size(frequency));
available(admissible) = rawResult.validMask;
% solverResult retains the native positive-frequency evaluation untouched.
rawResult.frequency_Hz = frequency;
rawResult.Cp_mps = Cp_mps;
rawResult.validMask = available;
end

function residuals = localResidualFunction(x, problem)
params = lamb.fitting.unpackParameterVector(x, problem.baseParams, problem.freeParams);
CpModel_mps = problem.evaluateModel(params);
residuals = lamb.fitting.computeDispersionFitResiduals(CpModel_mps, problem.experimental, problem.fitOptions);
end

function validateObjectiveFrequencySupport(experimental, solverOptions)
resolved = lamb.models.acoustoelastic_iop_hgo.configuration.aeResolveConfiguration(solverOptions);
if ~resolved.useInternalAtlasTrackingGrid
    return;
end
anchor_Hz = resolved.atlasInitializationMinFrequency_Hz;
outside = experimental.validMask & experimental.frequency_Hz < anchor_Hz;
if any(outside)
    firstFrequency_Hz = experimental.frequency_Hz(find(outside, 1, 'first'));
    error('lamb:fitting:AEObjectiveOutsideSupportedRange', ...
        ['AE atlasA0 fitting requires every selected experimental frequency to ' ...
         'be at or above the %.9g Hz initialization anchor. %d selected point(s) ' ...
         'are below that range; first unsupported frequency %.9g Hz. Exclude ' ...
         'those observations explicitly or adjust the fitting range.'], ...
        anchor_Hz, nnz(outside), firstFrequency_Hz);
end
end
