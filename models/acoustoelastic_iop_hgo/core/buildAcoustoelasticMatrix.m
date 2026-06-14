function [M, aux] = buildAcoustoelasticMatrix(alpha, beta, gamma, h, rho, rhoF, fluidBulkModulus, f, c, options)
%BUILDACOUSTOELASTICMATRIX Build the 5x5 acoustoelastic matrix.
%
% This implements Appendix Eq. A17 of Li et al. 2024, with an explicit
% option for the suspected M54 typo.
%
% Coordinates follow the paper: the solid occupies 0 <= x3 <= h, the aqueous
% humor is modeled as a semi-infinite fluid at x3 = 0, and the anterior
% surface x3 = h is stress-free.

if nargin < 10 || isempty(options)
    options = defaultLi2024AcoustoelasticOptions();
end

k = 2*pi*f/c;
[s1, s2, rootInfo] = computeSRoots_Li2024(alpha, beta, gamma, rho, c);
xi = sqrt(complex(1 - (c^2*rhoF/fluidBulkModulus)));

kh = k*h;
iUnit = 1i;

M = complex(zeros(5, 5));

% Posterior solid-fluid interface x3 = 0.
M(1,1) = s1^2 + 1;
M(1,3) = s2^2 + 1;

M(2,2) = gamma*s1*(s2^2 + 1);
M(2,4) = gamma*s2*(s1^2 + 1);
M(2,5) = iUnit*rhoF*c^2;

M(3,1) = 1;
M(3,3) = 1;
M(3,5) = -iUnit*xi;

% Anterior stress-free surface x3 = h.
M(4,1) = (s1^2 + 1)*cosh(s1*kh);
M(4,2) = (s1^2 + 1)*sinh(s1*kh);
M(4,3) = (s2^2 + 1)*cosh(s2*kh);
M(4,4) = (s2^2 + 1)*sinh(s2*kh);

M(5,1) = s1*(s2^2 + 1)*sinh(s1*kh);
M(5,2) = s1*(s2^2 + 1)*cosh(s1*kh);
M(5,3) = s2*(s1^2 + 1)*sinh(s2*kh);

variant = string(options.M54_variant);
switch variant
    case "paper"
        M(5,4) = s2*(s1^2 + 1)*cosh(s1*kh);
    case "corrected"
        M(5,4) = s2*(s1^2 + 1)*cosh(s2*kh);
    otherwise
        error('Unknown M54_variant: %s. Use "paper" or "corrected".', variant);
end

if isfield(options, 'normalizeRows') && options.normalizeRows
    M = normalizeMatrixRows(M);
end

aux = struct();
aux.k = k;
aux.kh = kh;
aux.s1 = s1;
aux.s2 = s2;
aux.xi = xi;
aux.rootInfo = rootInfo;
aux.M54_variant = variant;
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
