function params = mrlfeSetYoungModulusForShearPoisson(params, youngModulus)
%MRLFESETYOUNGMODULUSFORSHEARPOISSON Set an E-equivalent stiffness for ShearPoisson workflows.
%
% Maintained Rayleigh-Lamb and mRLFE soft-material workflows use the
% ShearPoisson material contract, where mu, nu, and rho are the primary
% material parameters. Some diagnostics are easier to read as sweeps over an
% E-equivalent stiffness. This helper keeps those diagnostics explicit by
% converting E to the corresponding shear modulus:
%
%   mu = E/(2*(1 + nu))
%
% The converted primary parameter is mu; E is not stored in the model request.

arguments
    params (1,1) struct
    youngModulus (1,1) double {mustBeFinite, mustBePositive}
end

if ~isfield(params, 'nu') || ~isfinite(params.nu)
    error('params.nu must be defined and finite to convert E-equivalent stiffness to mu.');
end
if params.nu <= -1
    error('params.nu must be greater than -1 to convert E-equivalent stiffness to mu.');
end

params.mu = youngModulus / (2 * (1 + params.nu));
end
