function [M, aux] = buildAcoustoelasticMatrix(alpha, beta, gamma, h, rho, rhoF, fluidBulkModulus, f, c, options, cpState)
%BUILDACOUSTOELASTICMATRIX Build the 5x5 acoustoelastic matrix.
%
% This implements Appendix Eq. A17 of Li et al. 2024, with an explicit
% option for the suspected M54 typo.
%
% Coordinates follow the paper: the solid occupies 0 <= x3 <= h, the aqueous
% humor is modeled as a semi-infinite fluid at x3 = 0, and the anterior
% surface x3 = h is stress-free.

if nargin < 10 || isempty(options)
    options = defaultAcoustoelasticIOPHGOOptions();
end
if nargin < 11 || isempty(cpState)
    cpState = computeAcoustoelasticCpState(alpha, beta, gamma, rho, rhoF, fluidBulkModulus, c);
end

s1 = cpState.s1;
s2 = cpState.s2;
xi = cpState.xi;
s1SquaredPlusOne = cpState.s1SquaredPlusOne;
s2SquaredPlusOne = cpState.s2SquaredPlusOne;

k = 2*pi*f/c;
kh = k*h;
coshS1 = cosh(s1*kh);
sinhS1 = sinh(s1*kh);
coshS2 = cosh(s2*kh);
sinhS2 = sinh(s2*kh);

M = complex(zeros(5, 5));

% Posterior solid-fluid interface x3 = 0.
M(1,1) = s1SquaredPlusOne;
M(1,3) = s2SquaredPlusOne;

M(2,2) = cpState.gammaS1S2SquaredPlusOne;
M(2,4) = cpState.gammaS2S1SquaredPlusOne;
M(2,5) = cpState.fluidCoupling;

M(3,1) = 1;
M(3,3) = 1;
M(3,5) = -1i*xi;

% Anterior stress-free surface x3 = h.
M(4,1) = s1SquaredPlusOne*coshS1;
M(4,2) = s1SquaredPlusOne*sinhS1;
M(4,3) = s2SquaredPlusOne*coshS2;
M(4,4) = s2SquaredPlusOne*sinhS2;

M(5,1) = cpState.s1S2SquaredPlusOne*sinhS1;
M(5,2) = cpState.s1S2SquaredPlusOne*coshS1;
M(5,3) = cpState.s2S1SquaredPlusOne*sinhS2;

variant = string(options.M54_variant);
switch variant
    case "paper"
        M(5,4) = cpState.s2S1SquaredPlusOne*coshS1;
    case "corrected"
        M(5,4) = cpState.s2S1SquaredPlusOne*coshS2;
    otherwise
        error('Unknown M54_variant: %s. Use "paper" or "corrected".', variant);
end

if isfield(options, 'normalizeRows') && options.normalizeRows
    M = normalizeMatrixRows(M);
end

if nargout > 1
    aux = struct();
    aux.k = k;
    aux.kh = kh;
    aux.s1 = s1;
    aux.s2 = s2;
    aux.xi = xi;
    aux.rootInfo = cpState.rootInfo;
    aux.M54_variant = variant;
end
end

function Mout = normalizeMatrixRows(Min)
Mout = Min;
for r = 1:size(Mout, 1)
    scale = norm(Mout(r, :));
    if isfinite(scale) && scale > 0
        Mout(r, :) = Mout(r, :) ./ scale;
    end
end
end
