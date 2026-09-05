function [objectiveValue, details] = objectiveAcoustoelasticResidual(alpha, beta, gamma, h, rho, rhoF, fluidBulkModulus, f, c, options, cpState)
%OBJECTIVEACOUSTOELASTICRESIDUAL Objective for Li 2024 secular equation.
%
% The objective is log10 of the smallest singular value of the row-normalized
% characteristic matrix. Modal signatures and matrix details are built only
% when explicitly requested by the caller.

if nargin < 10 || isempty(options)
    options = defaultAcoustoelasticIOPHGOOptions();
end
if nargin < 11
    cpState = [];
end

if nargout < 2
    M = buildAcoustoelasticMatrix(alpha, beta, gamma, h, rho, rhoF, fluidBulkModulus, f, c, options, cpState);
    [~, S, ~] = svd(M);
    sigmaMin = min(diag(S));
    objectiveValue = objectiveFromSigma(sigmaMin);
    return;
end

[M, aux] = buildAcoustoelasticMatrix(alpha, beta, gamma, h, rho, rhoF, fluidBulkModulus, f, c, options, cpState);
[U, S, V] = svd(M);
singularValues = diag(S);
[sigmaMin, idxMin] = min(singularValues);
objectiveValue = objectiveFromSigma(sigmaMin);

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

function value = objectiveFromSigma(sigmaMin)
if sigmaMin <= 0 || ~isfinite(sigmaMin)
    value = inf;
else
    value = log10(sigmaMin);
end
end
