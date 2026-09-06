function test_shared_fit_optimizer_contract()
%TEST_SHARED_FIT_OPTIMIZER_CONTRACT Protect shared optimizer route semantics.

frequency_Hz = [1; 2; 3; 4];

single = buildProblem(struct('a', 1), "a", 0, 4, ...
    2 .* frequency_Hz, frequency_Hz);
singleResult = solveDispersionFitProblem(single);
assert(singleResult.optimizer.name == "fminbnd");
assert(abs(singleResult.bestParams.a - 2) < 1e-5);
assert(all(singleResult.xBest >= singleResult.lowerBounds) && ...
    all(singleResult.xBest <= singleResult.upperBounds));
assert(isfield(singleResult, 'modelEvaluation'));

multiple = buildProblem(struct('a', 1, 'b', 1), ["a"; "b"], ...
    [0; 0], [4; 6], 2 .* frequency_Hz + 3, frequency_Hz);
multipleResult = solveDispersionFitProblem(multiple);
assert(multipleResult.optimizer.name == "fminsearch");
assert(abs(multipleResult.bestParams.a - 2) < 1e-3);
assert(abs(multipleResult.bestParams.b - 3) < 1e-3);
assert(all(multipleResult.xBest >= multipleResult.lowerBounds) && ...
    all(multipleResult.xBest <= multipleResult.upperBounds));
assert(multipleResult.metrics.RMSE < 1e-3);
assert(numel(multipleResult.identifiability.freeParams) == 2);

fprintf('Shared dispersion-fit optimizer contract passed.\n');
end

function problem = buildProblem(baseParams, freeParams, lowerBounds, upperBounds, CpTarget, frequency_Hz)
experimental = validateExperimentalDispersionData(struct( ...
    'frequency_Hz', frequency_Hz, 'Cp_mps', CpTarget), 1);
problem = struct();
problem.modelFamily = "synthetic";
problem.branchName = "linear";
problem.experimental = experimental;
problem.baseParams = baseParams;
problem.freeParams = string(freeParams(:));
problem.x0 = buildParameterVector(baseParams, problem.freeParams);
problem.lowerBounds = lowerBounds(:);
problem.upperBounds = upperBounds(:);
problem.fitOptions = struct('useStandardErrorWeights', false);
problem.optimizerOptions = struct( ...
    'fminbnd', optimset('Display', 'off', 'MaxIter', 80, ...
        'MaxFunEvals', 160, 'TolX', 1e-8), ...
    'fminsearch', optimset('Display', 'off', 'MaxIter', 250, ...
        'MaxFunEvals', 500, 'TolX', 1e-9, 'TolFun', 1e-12));
problem.evaluateModel = @(params)evaluateLinear(params, frequency_Hz);
problem.residualFunction = @(x)residualForVector(x, problem);
problem.objectiveFunction = @(x)objectiveForVector(x, problem);
end

function [Cp_mps, evaluation] = evaluateLinear(params, frequency_Hz)
b = 0;
if isfield(params, 'b')
    b = params.b;
end
Cp_mps = params.a .* frequency_Hz + b;
evaluation = struct('model', "synthetic", 'parameters', params);
end

function residuals = residualForVector(x, problem)
params = unpackParameterVector(x, problem.baseParams, problem.freeParams);
Cp_mps = problem.evaluateModel(params);
residuals = computeDispersionFitResiduals( ...
    Cp_mps, problem.experimental, problem.fitOptions);
end

function value = objectiveForVector(x, problem)
if any(x(:) < problem.lowerBounds) || any(x(:) > problem.upperBounds)
    value = 1e12 * (1 + sum(abs(x(:))));
    return;
end
residuals = problem.residualFunction(x);
value = sum(residuals.^2);
end
