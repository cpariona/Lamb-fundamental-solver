function params = mrlfeDefaultSweepParams()
%MRLFEDEFAULTSWEEPPARAMS Build the reference parameter set for mRLFE sweeps.
%
% The values match the maintained mRLFE sweep examples. This helper keeps
% public sweep scripts short while preserving the same numerical inputs.

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
