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
experimental = lamb.fitting.validateExperimentalDispersionData(experimental, 1);

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
problem.evaluateModel = @(params) lamb.fitting.acoustoelastic_iop_hgo.aeEvaluateFitModel(params, experimental.frequency_Hz, branchName, solverOptions);
problem.residualFunction = @(x) localResidualFunction(x, problem);
problem.objectiveFunction = @(x) lamb.fitting.evaluateBoundedObjective(x, problem);
end

function residuals = localResidualFunction(x, problem)
params = lamb.fitting.unpackParameterVector(x, problem.baseParams, problem.freeParams);
CpModel_mps = problem.evaluateModel(params);
residuals = lamb.fitting.computeDispersionFitResiduals(CpModel_mps, problem.experimental, problem.fitOptions);
end
