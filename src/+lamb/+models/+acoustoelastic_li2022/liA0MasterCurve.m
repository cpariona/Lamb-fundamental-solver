function curve = liA0MasterCurve(q)
%LIA0MASTERCURVE Physical Li et al. (2022) A0 branch for q = k*h.
%   Q is a nonnegative dimensionless array (Inf includes the Rayleigh limit).
%   H is CURRENT HALF-thickness; k is angular wavenumber in rad/m.
%   Output arrays retain the shape of Q. oneMinusEtaSquared preserves the
%   small flexural correction even when etaSquared rounds to one.
%   Solves 4*eta*tanh(eta*q)/tanh(q) = (1+eta^2)^2 with the constant
%   spurious eta=1 root removed analytically. No material parameters enter.
%   Reference: doi:10.1038/s42005-022-01000-3, Eq. (3).

validateattributes(q, {'double'}, {'real', 'nonnegative', 'nonnan'}, mfilename, 'q');
etaInfinity = fzero(@(e) e^3 + e^2 + 3*e - 1, [0, 0.5]);
eta = ones(size(q));
delta = zeros(size(q));
for i = 1:numel(q)
    qi = q(i);
    if qi == 0
        continue;
    elseif qi <= 0.05
        % Solve z=(1-eta^2)/q^2, which stays O(1) as q -> 0.
        z = fzero(@(z) smallResidual(z, qi), [0, 4/3]);
        delta(i) = qi^2*z;
        eta(i) = sqrt(1-delta(i));
    elseif qi < 64
        eta(i) = fzero(@(e) deflatedResidual(e, qi), [etaInfinity, 1]);
        delta(i) = (1-eta(i))*(1+eta(i));
    else
        % Finite-q correction is O(exp(-2*etaInfinity*q)); below double
        % precision here. Avoid overflow and endpoint sign roundoff.
        eta(i) = etaInfinity;
        delta(i) = 1-etaInfinity^2;
    end
end
curve = struct('wavenumberThickness', q, 'eta', eta, ...
    'etaSquared', 1-delta, 'oneMinusEtaSquared', delta);
end

function value = smallResidual(z, q)
% tanh(t)=t+sum(c_n*t^(2*n+1)); factor eta^2-1 before evaluation.
coefficients = [-1/3, 2/15, -17/315, 62/2835, -1382/155925, 21844/6081075];
etaSquared = 1-z*q^2;
geometricSum = 0;
series = 0;
for n = 1:numel(coefficients)
    geometricSum = 1+etaSquared*geometricSum;
    series = series+coefficients(n)*q^(2*n-2)*geometricSum;
end
value = -4*etaSquared*(q/tanh(q))*series-z;
end

function value = deflatedResidual(eta, q)
% Original residual divided by (1-eta^2). The divided tanh difference
% has a regular eta=1 limit; exponentials avoid hyperbolic overflow.
if eta == 1
    ratio = 4*q*exp(-2*q)/(-expm1(-4*q));
else
    ratio = 2*exp(-2*eta*q)*(-expm1(-2*(1-eta)*q)) / ...
        ((1-eta)*(-expm1(-2*q))*(1+exp(-2*eta*q)));
end
value = 4*eta/(1+eta)*(1-ratio)-(1-eta)*(1+eta);
end
