function [objectiveValue, details] = objectiveAcoustoelasticComplexDeterminant(alpha, beta, gamma, h, rho, rhoF, fluidBulkModulus, f, cComplex, options)
%OBJECTIVEACOUSTOELASTICCOMPLEXDETERMINANT Complex determinant objective.
%
% Evaluates the normalized characteristic matrix and its complex determinant
% for a complex phase velocity c = cr + i*ci. The scalar objective is
%
%   log10(abs(det(M)))
%
% with safeguards for non-finite values.

if nargin < 10 || isempty(options)
    options = lamb.models.acoustoelastic_iop_hgo.configuration.aeDefaultDiagnosticOptions();
end

[M, aux] = lamb.models.acoustoelastic_iop_hgo.core.buildAcoustoelasticMatrix(alpha, beta, gamma, h, rho, rhoF, fluidBulkModulus, f, cComplex, options);
detM = det(M);
absDet = abs(detM);

if absDet <= 0 || ~isfinite(absDet)
    objectiveValue = inf;
else
    objectiveValue = log10(absDet);
end

singularValues = svd(M);
sigmaMin = min(singularValues);

details = struct();
details.detM = detM;
details.absDet = absDet;
details.objectiveValue = objectiveValue;
details.singularValues = singularValues;
details.sigmaMin = sigmaMin;
details.matrix = M;
details.aux = aux;
end
