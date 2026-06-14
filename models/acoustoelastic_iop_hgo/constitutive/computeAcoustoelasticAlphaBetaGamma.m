function [alpha, beta, gamma, info] = computeAcoustoelasticAlphaBetaGamma(lambda, mu, k1, k2)
%COMPUTEACOUSTOELASTICALPHABETAGAMMA Compute acoustoelastic parameters from HGO stretch.
%
% Implements Appendix Eq. A6 from Li et al.
%
% Inputs:
%   lambda : equibiaxial stretch [-]
%   mu     : matrix shear modulus [Pa]
%   k1     : collagen fiber stiffness parameter [Pa]
%   k2     : collagen nonlinearity parameter [-]
%
% Outputs:
%   alpha, beta, gamma : acoustoelastic parameters [Pa]

validateattributes(lambda, {'numeric'}, {'real', 'finite', 'positive', 'scalar'});
validateattributes(mu, {'numeric'}, {'real', 'finite', 'positive', 'scalar'});
validateattributes(k1, {'numeric'}, {'real', 'finite', 'nonnegative', 'scalar'});
validateattributes(k2, {'numeric'}, {'real', 'finite', 'nonnegative', 'scalar'});

I = lambda^2 - 1;
expTerm = exp(k2 * I^2);

alpha = lambda^2 * (mu + 2*k1*I*expTerm);
gamma = mu * lambda^(-4);

twoBeta = alpha + gamma + 4*k1*lambda^4*(2*k2*I^2 + 1)*expTerm;
beta = 0.5 * twoBeta;

info = struct();
info.lambda = lambda;
info.mu = mu;
info.k1 = k1;
info.k2 = k2;
info.I = I;
info.expTerm = expTerm;
info.twoBeta = twoBeta;
info.alphaMinusGamma = alpha - gamma;
info.tensileModulusEffective = twoBeta + 2*gamma;
end
