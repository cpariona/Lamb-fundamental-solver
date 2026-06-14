function [objectiveValue, details] = objective_Li2024_Acoustoelastic(alpha, beta, gamma, h, rho, rhoF, fluidBulkModulus, f, c, options)
%OBJECTIVE_LI2024_ACOUSTOELASTIC Compatibility wrapper for objectiveAcoustoelasticResidual.

if nargin < 10
    [objectiveValue, details] = objectiveAcoustoelasticResidual(alpha, beta, gamma, h, rho, rhoF, fluidBulkModulus, f, c);
else
    [objectiveValue, details] = objectiveAcoustoelasticResidual(alpha, beta, gamma, h, rho, rhoF, fluidBulkModulus, f, c, options);
end
end
