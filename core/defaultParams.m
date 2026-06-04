function params = defaultParams()
% Return default physical, geometry, and frequency parameters.

params = struct();
params.modelType = "YoungPoissonFixedCL";
params.rho = 1070;
params.E = 475e3;
params.nu = 0.4999;
params.CL = 1500;
params.lambda = 2.40e9;
params.mu = 158e3;
params.thickness = 0.50e-3;
params.fmin = 10;
params.fmax = 8000;
params.numFrequencyPoints = 250;
params.frequencySpacing = "hybrid";
end
