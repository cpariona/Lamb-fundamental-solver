function [objectiveValue, details] = objectiveAcoustoelasticResidual(alpha, beta, gamma, h, rho, rhoF, fluidBulkModulus, f, c, options)
%OBJECTIVEACOUSTOELASTICRESIDUAL Objective for Li 2024 secular equation.
%
% The objective is log10 of the smallest singular value of the row-normalized
% characteristic matrix. This is more robust than using det(M) directly.
% The right singular vector associated with sigma_min is also returned so it
% can be used as a modal signature for MAC-based tracking.

if nargin < 10 || isempty(options)
    options = defaultAcoustoelasticIOPHGOOptions();
end

[M, aux] = buildAcoustoelasticMatrix(alpha, beta, gamma, h, rho, rhoF, fluidBulkModulus, f, c, options);
[U, S, V] = svd(M);
singularValues = diag(S);
[sigmaMin, idxMin] = min(singularValues);

if sigmaMin <= 0 || ~isfinite(sigmaMin)
    objectiveValue = inf;
else
    objectiveValue = log10(sigmaMin);
end

rightVector = V(:, idxMin);
leftVector = U(:, idxMin);

% Normalize the modal signature to make MAC comparisons numerically stable.
if norm(rightVector) > 0
    rightVector = rightVector ./ norm(rightVector);
end
if norm(leftVector) > 0
    leftVector = leftVector ./ norm(leftVector);
end

details = struct();
details.sigmaMin = sigmaMin;
details.singularValues = singularValues;
details.singularVectorRight = rightVector;
details.singularVectorLeft = leftVector;
details.matrix = M;
details.aux = aux;
end
