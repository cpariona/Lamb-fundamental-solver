function value = evaluateBoundedObjective(x, problem)
%EVALUATEBOUNDEDOBJECTIVE Evaluate a fit objective with bound penalties.

if any(x(:) < problem.lowerBounds(:)) || any(x(:) > problem.upperBounds(:))
    lowerViolation = max(problem.lowerBounds(:) - x(:), 0);
    upperViolation = max(x(:) - problem.upperBounds(:), 0);
    scale = max(abs(problem.x0(:)), 1);
    value = 1e12 * (1 + sum(((lowerViolation + upperViolation) ./ scale).^2));
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
