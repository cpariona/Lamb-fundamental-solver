function fitResult = solveDispersionFitProblem(problem)
%SOLVEDISPERSIONFITPROBLEM Optimize and report one bounded dispersion fit.
%
% The caller owns construction of the model-specific problem, including its
% evaluator, objective, bounds, and optimizer defaults. This function owns
% only the reusable optimization and post-fit reporting workflow.

[optimizerName, xBest, bestObjective, exitFlag, output] = runOptimizer(problem);
xBest = xBest(:);
xBest = min(max(xBest, problem.lowerBounds), problem.upperBounds);

bestParams = lamb.fitting.unpackParameterVector(xBest, problem.baseParams, problem.freeParams);
[CpFit_mps, modelEvaluation] = problem.evaluateModel(bestParams);
[residuals, residualInfo] = lamb.fitting.computeDispersionFitResiduals( ...
    CpFit_mps, problem.experimental, problem.fitOptions);
metrics = lamb.fitting.computeDispersionFitMetrics(CpFit_mps, problem.experimental);
[S, sensitivityInfo] = lamb.fitting.estimateLocalSensitivity( ...
    problem.evaluateModel, bestParams, problem.freeParams, problem.experimental);
identifiability = lamb.fitting.assessFitIdentifiability(S, problem.freeParams);

fitResult = struct();
fitResult.modelFamily = problem.modelFamily;
fitResult.branchName = problem.branchName;
fitResult.bestParams = selectParams(bestParams, problem.freeParams);
fitResult.allParams = bestParams;
fitResult.fixedParams = removeParams(problem.baseParams, problem.freeParams);
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
fitResult.optimizer = struct( ...
    'name', optimizerName, 'objective', bestObjective, ...
    'exitFlag', exitFlag, 'output', output);
fitResult.modelEvaluation = modelEvaluation;
fitResult.problem = rmfield(problem, ...
    {'evaluateModel', 'residualFunction', 'objectiveFunction'});
end

function [optimizerName, xBest, bestObjective, exitFlag, output] = runOptimizer(problem)
objective = @(x) problem.objectiveFunction(x(:));

if numel(problem.x0) == 1 && all(isfinite(problem.lowerBounds)) && ...
        all(isfinite(problem.upperBounds))
    optimizerName = "fminbnd";
    options = optimizerOptions(problem, 'fminbnd');
    [xScalar, bestObjective, exitFlag, output] = fminbnd( ...
        @(x)objective(x), problem.lowerBounds, problem.upperBounds, options);
    xBest = xScalar(:);
else
    optimizerName = "fminsearch";
    options = optimizerOptions(problem, 'fminsearch');
    [xBest, bestObjective, exitFlag, output] = fminsearch( ...
        objective, problem.x0(:), options);
end
end

function options = optimizerOptions(problem, routeName)
if isfield(problem.fitOptions, 'optimizerOptions') && ...
        ~isempty(problem.fitOptions.optimizerOptions)
    options = problem.fitOptions.optimizerOptions;
    return;
end
if ~isfield(problem, 'optimizerOptions') || ...
        ~isfield(problem.optimizerOptions, routeName)
    error('solveDispersionFitProblem:MissingOptimizerOptions', ...
        'The fit problem must define optimizerOptions.%s.', routeName);
end
options = problem.optimizerOptions.(routeName);
end

function subset = selectParams(params, names)
subset = struct();
for i = 1:numel(names)
    name = char(names(i));
    subset.(name) = params.(name);
end
end

function remaining = removeParams(params, names)
remaining = params;
for i = 1:numel(names)
    name = char(names(i));
    if isfield(remaining, name)
        remaining = rmfield(remaining, name);
    end
end
end
