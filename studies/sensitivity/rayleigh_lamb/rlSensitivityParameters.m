function params = rlSensitivityParameters()
%RLSENSITIVITYPARAMETERS Build the reference parameter set for Rayleigh-Lamb sensitivity studies.
%
% Maintained Rayleigh-Lamb studies use shear modulus and Poisson ratio as
% user-facing elastic inputs. E and lambda are derived by rlComputeMaterial.

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
