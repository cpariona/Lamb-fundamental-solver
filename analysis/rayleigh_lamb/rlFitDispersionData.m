function fitResult = rlFitDispersionData(experimental, fitConfig)
%RLFITDISPERSIONDATA Fit Rayleigh-Lamb parameters to dispersion data.
%
% This first implementation uses fminsearch with objective penalties for
% bounds. It is intended as a lightweight backend for Phase 2 and avoids an
% Optimization Toolbox dependency.

problem = rlBuildFitProblem(experimental, fitConfig);

optimizerOptions = getFitOption(problem.fitOptions, 'optimizerOptions', []);
if isempty(optimizerOptions)
    optimizerOptions = optimset('Display', 'off', 'MaxIter', 80, 'MaxFunEvals', 220, 'TolX', 1e-6, 'TolFun', 1e-8);
end

objective = @(x) problem.objectiveFunction(x(:));
[xBest, bestObjective, exitFlag, output] = fminsearch(objective, problem.x0(:), optimizerOptions);
xBest = xBest(:);

% Keep the final report inside declared bounds. The objective already
% penalizes out-of-bound candidates, but this prevents tiny numerical drift.
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
fitResult.optimizer.name = "fminsearch";
fitResult.optimizer.objective = bestObjective;
fitResult.optimizer.exitFlag = exitFlag;
fitResult.optimizer.output = output;
fitResult.rawSolverResult = rawSolverResult;
fitResult.problem = rmfield(problem, {'evaluateModel', 'residualFunction', 'objectiveFunction'});
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
