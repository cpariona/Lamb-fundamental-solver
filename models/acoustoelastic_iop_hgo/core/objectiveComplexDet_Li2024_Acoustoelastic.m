function [objectiveValue, details] = objectiveComplexDet_Li2024_Acoustoelastic(alpha, beta, gamma, h, rho, rhoF, fluidBulkModulus, f, cComplex, options)
%OBJECTIVECOMPLEXDET_LI2024_ACOUSTOELASTIC Compatibility wrapper for objectiveAcoustoelasticComplexDeterminant.

if nargin < 10
    [objectiveValue, details] = objectiveAcoustoelasticComplexDeterminant(alpha, beta, gamma, h, rho, rhoF, fluidBulkModulus, f, cComplex);
else
    [objectiveValue, details] = objectiveAcoustoelasticComplexDeterminant(alpha, beta, gamma, h, rho, rhoF, fluidBulkModulus, f, cComplex, options);
end
end
