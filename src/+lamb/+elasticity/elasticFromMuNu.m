function elastic = elasticFromMuNu(mu, nu, rho)
%ELASTICFROMMUNU Build isotropic elastic parameters from shear modulus and Poisson ratio.
%
% Inputs use SI units:
%   mu  : shear modulus [Pa]
%   nu  : Poisson ratio [-]
%   rho : density [kg/m^3]
%
% The returned structure contains the complete equivalent isotropic set used by
% Rayleigh-Lamb and mRLFE workflows.

if nargin < 3
    error('elasticFromMuNu requires mu, nu, and rho.');
end

validateattributes(mu, {'numeric'}, {'scalar', 'real', 'finite', 'positive'}, mfilename, 'mu');
validateattributes(nu, {'numeric'}, {'scalar', 'real', 'finite', '>', -1, '<', 0.5}, mfilename, 'nu');
validateattributes(rho, {'numeric'}, {'scalar', 'real', 'finite', 'positive'}, mfilename, 'rho');

E = 2 * mu * (1 + nu);
lambda = 2 * mu * nu / (1 - 2 * nu);
K = lambda + 2 * mu / 3;
CT = sqrt(mu / rho);
CL = sqrt((lambda + 2 * mu) / rho);

elastic = packElastic("ShearPoisson", rho, E, nu, lambda, mu, K, CL, CT);
end

function elastic = packElastic(modelType, rho, E, nu, lambda, mu, K, CL, CT)
elastic = struct();
elastic.modelType = string(modelType);
elastic.rho = rho;
elastic.E = E;
elastic.nu = nu;
elastic.lambda = lambda;
elastic.mu = mu;
elastic.K = K;
elastic.CL = CL;
elastic.CT = CT;
end
