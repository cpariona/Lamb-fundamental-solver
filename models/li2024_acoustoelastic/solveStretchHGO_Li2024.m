function [lambda, info] = solveStretchHGO_Li2024(sigma, mu, k1, k2, varargin)
%SOLVESTRETCHHGO_LI2024 Solve HGO equibiaxial stretch from prestress.
%
% Solves Appendix Eq. A23 from Li et al.:
%
%   mu*(lambda^2 - lambda^-4)
%   + 2*k1*lambda^2*(lambda^2 - 1)*exp(k2*(lambda^2 - 1)^2)
%   = sigma
%
% Inputs are SI units:
%   sigma, mu, k1 : Pa
%   k2            : dimensionless
%
% Optional name-value pairs:
%   LambdaBounds  : [lower upper], default [1, 2.5]
%   Display       : 'off' or 'iter', default 'off'

p = inputParser;
addParameter(p, 'LambdaBounds', [1, 2.5], @(x)isnumeric(x) && numel(x)==2 && x(1)>0 && x(2)>x(1));
addParameter(p, 'Display', 'off', @(x)ischar(x) || isstring(x));
parse(p, varargin{:});

validateattributes(sigma, {'numeric'}, {'real', 'finite', 'scalar'});
validateattributes(mu, {'numeric'}, {'real', 'finite', 'positive', 'scalar'});
validateattributes(k1, {'numeric'}, {'real', 'finite', 'nonnegative', 'scalar'});
validateattributes(k2, {'numeric'}, {'real', 'finite', 'nonnegative', 'scalar'});

bounds = p.Results.LambdaBounds;
residual = @(lam) hgoStress(lam, mu, k1, k2) - sigma;

fLower = residual(bounds(1));
fUpper = residual(bounds(2));

if abs(fLower) < 1e-12 * max(abs(sigma), 1)
    lambda = bounds(1);
elseif fLower * fUpper <= 0
    lambda = fzero(residual, bounds);
else
    % Fall back to bounded minimization if the requested bounds do not bracket
    % a sign change. This is useful during parameter exploration.
    obj = @(lam) residual(lam).^2;
    lambda = fminbnd(obj, bounds(1), bounds(2), optimset('Display', char(p.Results.Display)));
end

info = struct();
info.sigma = sigma;
info.mu = mu;
info.k1 = k1;
info.k2 = k2;
info.lambdaBounds = bounds;
info.residual = residual(lambda);
info.modelStress = hgoStress(lambda, mu, k1, k2);
info.bracketResiduals = [fLower, fUpper];
end

function stress = hgoStress(lambda, mu, k1, k2)
I = lambda.^2 - 1;
stress = mu .* (lambda.^2 - lambda.^(-4)) + ...
    2 .* k1 .* lambda.^2 .* I .* exp(k2 .* I.^2);
end
