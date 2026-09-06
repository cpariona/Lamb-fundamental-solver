function elastic = elasticFromLame(lambda, mu, rho)
%ELASTICFROMLAME Build isotropic elastic parameters from Lame parameters.
%
% Inputs use SI units:
%   lambda : first Lame parameter [Pa]
%   mu     : shear modulus [Pa]
%   rho    : density [kg/m^3]

if nargin < 3
    error('lamb.elasticity.elasticFromLame requires lambda, mu, and rho.');
end

validateattributes(lambda, {'numeric'}, {'scalar', 'real', 'finite', 'nonnegative'}, mfilename, 'lambda');
validateattributes(mu, {'numeric'}, {'scalar', 'real', 'finite', 'positive'}, mfilename, 'mu');
validateattributes(rho, {'numeric'}, {'scalar', 'real', 'finite', 'positive'}, mfilename, 'rho');

E = mu * (3 * lambda + 2 * mu) / (lambda + mu);
nu = lambda / (2 * (lambda + mu));
K = lambda + 2 * mu / 3;
CT = sqrt(mu / rho);
CL = sqrt((lambda + 2 * mu) / rho);

elastic = struct();
elastic.modelType = "LameParameters";
elastic.rho = rho;
elastic.E = E;
elastic.nu = nu;
elastic.lambda = lambda;
elastic.mu = mu;
elastic.K = K;
elastic.CL = CL;
elastic.CT = CT;
end
