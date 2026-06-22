function params = rlDefaultSweepParams()
%RLDEFAULTSWEEPPARAMS Build the reference parameter set for Rayleigh-Lamb sweeps.
%
% The maintained Rayleigh-Lamb sweep examples use shear modulus as the
% user-facing material reference while preserving the current E, nu solver
% parameterization internally.

params = rlDefaultParams();
params.modelType = "YoungPoissonFixedCL";
params.rho = 1070;
params.E = 3 * 75e3;
params.nu = 0.4999;
params.CL = 1500;
params.thickness = 0.5e-3;
params.fmin = 100;
params.fmax = 16000;
params.numFrequencyPoints = "auto";
params.frequencySpacing = "hybrid";
end
