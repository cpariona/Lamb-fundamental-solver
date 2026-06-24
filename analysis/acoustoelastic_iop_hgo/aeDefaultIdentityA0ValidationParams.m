function params = aeDefaultIdentityA0ValidationParams()
%AEDEFAULTIDENTITYA0VALIDATIONPARAMS Default parameters for identity-A0 validation diagnostics.
%
% These defaults are shared by the maintained heavy validation diagnostics:
%   validate_idA0_grid
%   validate_idA0_score_grid

params = struct();
params.R = 7.8e-3;
params.thickness = 550e-6;
params.IOP = 15 * 133.322;
params.mu = 50e3;
params.k1 = 25e3;
params.k2 = 100;
params.rho = 1060;
params.rhoF = 1000;
params.fluidBulkModulus = 2.2e9;
params.frequency = logspace(log10(100), log10(35e3), 120);
end
