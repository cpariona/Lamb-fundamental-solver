function curve = aePlateA0MasterCurve(q)
%AEPLATEA0MASTERCURVE Physical Li et al. (2022) A0 branch for q = k*h.
%   Q is a nonnegative dimensionless array (Inf includes the Rayleigh limit).
%   H is CURRENT HALF-thickness; k is angular wavenumber in rad/m.
%   Output arrays retain the shape of Q. oneMinusEtaSquared preserves the
%   small flexural correction even when etaSquared rounds to one.
%   Solves 4*eta*tanh(eta*q)/tanh(q) = (1+eta^2)^2 with the constant
%   spurious eta=1 root removed analytically. No material parameters enter.
%   Reference: doi:10.1038/s42005-022-01000-3, Eq. (3).

validateattributes(q, {'double'}, {'real', 'nonnegative', 'nonnan'}, mfilename, 'q');
% Unique positive root of eta^3+eta^2+3*eta-1, rounded to double.
% Material-independent: reuse this value without per-call roots or cache state.
etaInfinity = 0.29559774252208477;
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
% Multiply the deflated residual by tanh(q)/q > 0 and use the same
% thirteenth-order tanh series. Separate 4/3-z before rounding O(q^2)
% terms: evaluating q/tanh(q) first can destroy the sign at z=4/3.
coefficients = [-1/3, 2/15, -17/315, 62/2835, -1382/155925, 21844/6081075];
qSquared = q^2;
etaSquared = 1-z*qSquared;
geometricSum = 1;
seriesTail = 0;
power = 1;
for n = 2:numel(coefficients)
    geometricSum = 1+etaSquared*geometricSum;
    seriesTail = seriesTail+coefficients(n)*power*geometricSum;
    power = power*qSquared;
end
tanhTail = coefficients(end);
for n = numel(coefficients)-1:-1:1
    tanhTail = coefficients(n)+qSquared*tanhTail;
end
value = (4/3-z)-qSquared*(z*(4/3+tanhTail)+4*etaSquared*seriesTail);
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
