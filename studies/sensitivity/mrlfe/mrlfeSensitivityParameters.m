function params = mrlfeSensitivityParameters()
%MRLFEDEFAULTSWEEPPARAMS Build the reference parameter set for mRLFE sweeps.

params = lamb.models.mrlfe.configuration.mrlfeDefaultWorkflowParams();
params.rho = 1070;
params.mu = 75e3;
params.nu = 0.4999;
params.thickness = 0.5e-3;
params.fmin = 100;
params.fmax = 16000;
params.numFrequencyPoints = "auto";
params.frequencySpacing = "hybrid";
end
