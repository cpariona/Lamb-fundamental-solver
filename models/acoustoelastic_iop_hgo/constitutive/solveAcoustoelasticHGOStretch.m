function [lambda, info] = solveAcoustoelasticHGOStretch(sigma, mu, k1, k2, varargin)
%SOLVEACOUSTOELASTICHGOSTRETCH Solve HGO equibiaxial stretch from prestress.
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
%   NumBracketSamples : number of samples for adaptive bracketing, default 400

p = inputParser;
addParameter(p, 'LambdaBounds', [1, 2.5], @(x)isnumeric(x) && numel(x)==2 && x(1)>0 && x(2)>x(1));
addParameter(p, 'Display', 'off', @(x)ischar(x) || isstring(x));
addParameter(p, 'NumBracketSamples', 400, @(x)isnumeric(x) && isscalar(x) && x >= 20);
parse(p, varargin{:});

validateattributes(sigma, {'numeric'}, {'real', 'finite', 'scalar'});
validateattributes(mu, {'numeric'}, {'real', 'finite', 'positive', 'scalar'});
validateattributes(k1, {'numeric'}, {'real', 'finite', 'nonnegative', 'scalar'});
validateattributes(k2, {'numeric'}, {'real', 'finite', 'nonnegative', 'scalar'});

bounds = p.Results.LambdaBounds;
residual = @(lam) hgoStressSafe(lam, mu, k1, k2, sigma) - sigma;

[fLower, fUpper] = deal(residual(bounds(1)), residual(bounds(2)));
[bracket, bracketInfo] = findFiniteBracket(residual, bounds, p.Results.NumBracketSamples);

tolStress = 1e-12 * max(abs(sigma), 1);
if isfinite(fLower) && abs(fLower) < tolStress
    lambda = bounds(1);
    solveMethod = "lower-bound";
elseif ~isempty(bracket)
    lambda = fzero(residual, bracket);
    solveMethod = "fzero-adaptive-bracket";
else
    % Fall back to bounded minimization if no finite sign-changing bracket is
    % detected. This keeps exploratory runs alive, but the residual should be
    % checked before using the result quantitatively.
    obj = @(lam) residual(lam).^2;
    lambda = fminbnd(obj, bounds(1), bounds(2), optimset('Display', char(p.Results.Display)));
    solveMethod = "fminbnd-residual";
end

info = struct();
info.sigma = sigma;
info.mu = mu;
info.k1 = k1;
info.k2 = k2;
info.lambdaBounds = bounds;
info.lambdaBracket = bracket;
info.bracketInfo = bracketInfo;
info.solveMethod = solveMethod;
info.residual = residual(lambda);
info.modelStress = hgoStressSafe(lambda, mu, k1, k2, sigma);
info.bracketResiduals = [fLower, fUpper];
end

function [bracket, info] = findFiniteBracket(residual, bounds, nSamples)
lambdaGrid = linspace(bounds(1), bounds(2), nSamples);
residualGrid = nan(size(lambdaGrid));

for i = 1:numel(lambdaGrid)
    value = residual(lambdaGrid(i));
    if isreal(value) && isfinite(value)
        residualGrid(i) = value;
    end
end

bracket = [];
for i = 1:numel(lambdaGrid)-1
    f1 = residualGrid(i);
    f2 = residualGrid(i+1);
    if ~isfinite(f1) || ~isfinite(f2)
        continue;
    end
    if f1 == 0
        bracket = [lambdaGrid(i), lambdaGrid(i)];
        break;
    end
    if f1 * f2 <= 0
        bracket = [lambdaGrid(i), lambdaGrid(i+1)];
        break;
    end
end

info = struct();
info.numSamples = nSamples;
info.finiteSamples = nnz(isfinite(residualGrid));
info.minFiniteResidual = min(residualGrid(isfinite(residualGrid)), [], 'omitnan');
info.maxFiniteResidual = max(residualGrid(isfinite(residualGrid)), [], 'omitnan');
end

function stress = hgoStressSafe(lambda, mu, k1, k2, referenceStress)
I = lambda.^2 - 1;
expArg = k2 .* I.^2;

% Large k2 and large trial lambda can overflow exp(). For root bracketing we
% only need a finite positive value above the target stress, not the exact
% enormous stress at unrealistic stretches.
if any(expArg > 600, 'all')
    stress = realmax('double') / 100;
    return;
end

stress = mu .* (lambda.^2 - lambda.^(-4)) + ...
    2 .* k1 .* lambda.^2 .* I .* exp(expArg);

if ~isfinite(stress) || ~isreal(stress)
    stress = sign(max(referenceStress, 1)) * realmax('double') / 100;
end
end
