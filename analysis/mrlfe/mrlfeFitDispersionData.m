function fitResult = mrlfeFitDispersionData(experimental, fitConfig)
%MRLFEFITDISPERSIONDATA Fit mRLFE parameters to dispersion data.
%
% One-parameter fits with finite bounds use fminbnd. Multi-parameter fits use
% fminsearch with objective penalties for bounds. This keeps the first mRLFE
% fitting implementation free of Optimization Toolbox dependency.

problem = mrlfeBuildFitProblem(experimental, fitConfig);

[optimizerName, xBest, bestObjective, exitFlag, output] = runOptimizer(problem);
xBest = xBest(:);
xBest = min(max(xBest, problem.lowerBounds), problem.upperBounds);

bestParams = unpackParameterVector(xBest, problem.baseParams, problem.freeParams);
[CpFit_mps, rawSolverResult] = problem.evaluateModel(bestParams);
[residuals, residualInfo] = computeDispersionFitResiduals(CpFit_mps, problem.experimental, problem.fitOptions);
metrics = computeDispersionFitMetrics(CpFit_mps, problem.experimental);
[S, sensitivityInfo] = estimateLocalSensitivity(problem.evaluateModel, bestParams, problem.freeParams, problem.experimental);
identifiability = assessFitIdentifiability(S, problem.freeParams);

fitResult = struct();
fitResult.modelFamily = problem.modelFamily;
fitResult.branchName = problem.branchName;
fitResult.bestParams = filterParams(bestParams, problem.freeParams);
fitResult.allParams = bestParams;
fitResult.fixedParams = removeFreeParams(problem.baseParams, problem.freeParams);
fitResult.freeParams = problem.freeParams;
fitResult.xBest = xBest;
fitResult.x0 = problem.x0;
fitResult.lowerBounds = problem.lowerBounds;
fitResult.upperBounds = problem.upperBounds;
fitResult.frequency_Hz = problem.experimental.frequency_Hz;
fitResult.Cp_exp_mps = problem.experimental.Cp_mps;
fitResult.Cp_fit_mps = CpFit_mps;
fitResult.residuals = residuals;
fitResult.residualInfo = residualInfo;
fitResult.validMask = residualInfo.validMask;
fitResult.metrics = metrics;
fitResult.sensitivity = sensitivityInfo;
fitResult.sensitivityMatrix = S;
fitResult.identifiability = identifiability;
fitResult.optimizer = struct();
fitResult.optimizer.name = optimizerName;
fitResult.optimizer.objective = bestObjective;
fitResult.optimizer.exitFlag = exitFlag;
fitResult.optimizer.output = output;
fitResult.rawSolverResult = rawSolverResult;
fitResult.problem = rmfield(problem, {'evaluateModel', 'residualFunction', 'objectiveFunction'});
end

function [optimizerName, xBest, bestObjective, exitFlag, output] = runOptimizer(problem)
objective = @(x) problem.objectiveFunction(x(:));

if numel(problem.x0) == 1 && isfinite(problem.lowerBounds) && isfinite(problem.upperBounds)
    optimizerName = "fminbnd";
    options = getFitOption(problem.fitOptions, 'optimizerOptions', []);
    if isempty(options)
        options = optimset('Display', 'off', 'MaxIter', 45, 'MaxFunEvals', 90, 'TolX', 1e-5);
    end
    scalarObjective = @(x) objective(x);
    [xScalar, bestObjective, exitFlag, output] = fminbnd(scalarObjective, problem.lowerBounds, problem.upperBounds, options);
    xBest = xScalar(:);
else
    optimizerName = "fminsearch";
    options = getFitOption(problem.fitOptions, 'optimizerOptions', []);
    if isempty(options)
        options = optimset('Display', 'off', 'MaxIter', 60, 'MaxFunEvals', 160, 'TolX', 1e-5, 'TolFun', 1e-7);
    end
    [xBest, bestObjective, exitFlag, output] = fminsearch(objective, problem.x0(:), options);
end
end

function value = getFitOption(options, fieldName, defaultValue)
if isstruct(options) && isfield(options, fieldName) && ~isempty(options.(fieldName))
    value = options.(fieldName);
else
    value = defaultValue;
end
end

function subset = filterParams(params, names)
subset = struct();
for i = 1:numel(names)
    name = char(names(i));
    subset.(name) = params.(name);
end
end

function fixedParams = removeFreeParams(params, freeParams)
fixedParams = params;
for i = 1:numel(freeParams)
    name = char(freeParams(i));
    if isfield(fixedParams, name)
        fixedParams = rmfield(fixedParams, name);
    end
end
end
