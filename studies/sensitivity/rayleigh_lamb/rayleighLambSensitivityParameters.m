function params = rayleighLambSensitivityParameters()
%RLDEFAULTSWEEPPARAMS Build the reference parameter set for Rayleigh-Lamb sweeps.
%
% Maintained Rayleigh-Lamb sweep examples use shear modulus and Poisson ratio
% as the user-facing elastic inputs. E and lambda are derived by lamb.models.rayleigh_lamb.core.rlComputeMaterial.

params = lamb.models.rayleigh_lamb.rlDefaultParams();
params.modelType = "ShearPoisson";
params.rho = 1070;
params.mu = 75e3;
params.nu = 0.4999;
params.thickness = 0.5e-3;
params.fmin = 100;
params.fmax = 16000;
params.numFrequencyPoints = "auto";
params.frequencySpacing = "hybrid";
end
