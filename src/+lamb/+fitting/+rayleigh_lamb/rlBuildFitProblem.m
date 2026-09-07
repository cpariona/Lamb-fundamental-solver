function problem = rlBuildFitProblem(experimental, fitConfig)
%RLBUILDFITPROBLEM Build a Rayleigh-Lamb dispersion fitting problem.
%
% Required fitConfig fields:
%   freeParams
%
% Optional fitConfig fields:
%   branchName      default "A0"
%   fixedParams     fields overriding lamb.models.rayleigh_lamb.rlDefaultParams
%   initialGuess    fields for free-parameter initial guesses
%   bounds          fields with [lower upper] bounds
%   solverOptions   lamb.models.rayleigh_lamb.rlDefaultOptions-compatible options
%   fitOptions      residual options

if nargin < 2 || ~isstruct(fitConfig)
    error('fitConfig must be provided as a structure.');
end
if ~isfield(fitConfig, 'freeParams') || isempty(fitConfig.freeParams)
    error('fitConfig.freeParams is required.');
end
experimental = lamb.fitting.validateExperimentalDispersionData(experimental, 1);

branchName = lamb.fitting.getFitConfigValue(fitConfig, 'branchName', "A0");
branchName = string(branchName);

baseParams = lamb.models.rayleigh_lamb.rlDefaultParams();
baseParams = lamb.fitting.applyParameterOverrides(baseParams, ...
    lamb.fitting.getFitConfigValue(fitConfig, 'fixedParams', struct()));
baseParams = lamb.fitting.applyParameterOverrides(baseParams, ...
    lamb.fitting.getFitConfigValue(fitConfig, 'initialGuess', struct()));

freeParams = string(fitConfig.freeParams(:));
[x0, parameterInfo] = lamb.fitting.buildParameterVector(baseParams, freeParams);

bounds = lamb.fitting.getFitConfigValue(fitConfig, 'bounds', struct());
[lowerBounds, upperBounds] = lamb.fitting.buildParameterBounds(bounds, freeParams);

solverOptions = lamb.fitting.getFitConfigValue(fitConfig, 'solverOptions', lamb.models.rayleigh_lamb.rlDefaultOptions("Fast"));
fitOptions = lamb.fitting.getFitConfigValue(fitConfig, 'fitOptions', struct());
if ~isfield(fitOptions, 'useStandardErrorWeights')
    fitOptions.useStandardErrorWeights = false;
end
if ~isfield(fitOptions, 'minValidFraction') || isempty(fitOptions.minValidFraction)
    fitOptions.minValidFraction = 0.80;
end

problem = struct();
problem.modelFamily = "rayleigh_lamb";
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
    'fminbnd', optimset('Display', 'off', 'MaxIter', 80, ...
        'MaxFunEvals', 160, 'TolX', 1e-6), ...
    'fminsearch', optimset('Display', 'off', 'MaxIter', 80, ...
        'MaxFunEvals', 220, 'TolX', 1e-6, 'TolFun', 1e-8));
problem.evaluateModel = @(params) lamb.fitting.rayleigh_lamb.rlEvaluateFitModel(params, experimental.frequency_Hz, branchName, solverOptions);
problem.residualFunction = @(x) localResidualFunction(x, problem);
problem.objectiveFunction = @(x) lamb.fitting.evaluateBoundedObjective(x, problem);
end

function residuals = localResidualFunction(x, problem)
params = lamb.fitting.unpackParameterVector(x, problem.baseParams, problem.freeParams);
CpModel_mps = problem.evaluateModel(params);
[residuals, residualInfo] = lamb.fitting.computeDispersionFitResiduals(CpModel_mps, problem.experimental, problem.fitOptions);
requiredCount = max(1, ceil(problem.fitOptions.minValidFraction * nnz(problem.experimental.validMask)));
if residualInfo.numResiduals < requiredCount
    error('Insufficient valid Rayleigh-Lamb model coverage: %d/%d valid pairs.', ...
        residualInfo.numResiduals, nnz(problem.experimental.validMask));
end
end
