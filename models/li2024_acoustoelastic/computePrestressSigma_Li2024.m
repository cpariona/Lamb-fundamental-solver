function sigma = computePrestressSigma_Li2024(IOP, R, h)
%COMPUTEPRESTRESSSIGMA_LI2024 Compute in-plane corneal prestress.
%
% Young-Laplace approximation used by Li et al.:
%
%   sigma = IOP * R / (2*h)
%
% Inputs are SI units:
%   IOP : intraocular pressure [Pa]
%   R   : corneal radius of curvature [m]
%   h   : corneal thickness [m]
%
% Output:
%   sigma : in-plane tensile prestress [Pa]

validateattributes(IOP, {'numeric'}, {'real', 'finite', 'scalar'});
validateattributes(R, {'numeric'}, {'real', 'finite', 'positive', 'scalar'});
validateattributes(h, {'numeric'}, {'real', 'finite', 'positive', 'scalar'});

sigma = IOP * R / (2*h);
end
