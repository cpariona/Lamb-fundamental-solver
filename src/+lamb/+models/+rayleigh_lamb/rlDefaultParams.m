function params = rlDefaultParams()
% Return default physical, geometry, and frequency parameters.

params = struct();
params.modelType = "ShearPoisson";
params.rho = 1070;
params.mu = 158e3;
params.nu = 0.4999;

params.thickness = 0.50e-3;
params.fmin = 10;
params.fmax = 16000;
params.numFrequencyPoints = "auto";
params.frequencySpacing = "hybrid";
end
