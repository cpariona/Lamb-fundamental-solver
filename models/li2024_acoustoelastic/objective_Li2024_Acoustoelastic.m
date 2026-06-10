function [objectiveValue, details] = objective_Li2024_Acoustoelastic(alpha, beta, gamma, h, rho, rhoF, fluidBulkModulus, f, c, options)
%OBJECTIVE_LI2024_ACOUSTOELASTIC Objective for Li 2024 secular equation.
%
% The objective is log10 of the smallest singular value of the row-normalized
% characteristic matrix. This is more robust than using det(M) directly.

if nargin < 10 || isempty(options)
    options = defaultLi2024AcoustoelasticOptions();
end

[M, aux] = buildMatrix_Li2024_Acoustoelastic(alpha, beta, gamma, h, rho, rhoF, fluidBulkModulus, f, c, options);
singularValues = svd(M);
sigmaMin = min(singularValues);

if sigmaMin <= 0 || ~isfinite(sigmaMin)
    objectiveValue = inf;
else
    objectiveValue = log10(sigmaMin);
end

details = struct();
details.sigmaMin = sigmaMin;
details.singularValues = singularValues;
details.matrix = M;
details.aux = aux;
end
