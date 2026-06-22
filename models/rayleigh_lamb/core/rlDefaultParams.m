function params = rlDefaultParams()
% Return default physical, geometry, and frequency parameters.

params = struct();
params.modelType = "ShearPoisson";
params.rho = 1070;
params.mu = 158e3;
params.nu = 0.4999;

% Derived values are stored for display and compatibility with older scripts.
elastic = elasticFromMuNu(params.mu, params.nu, params.rho);
params.E = elastic.E;
params.lambda = elastic.lambda;
params.K = elastic.K;
params.CL = elastic.CL;
params.CT = elastic.CT;

params.thickness = 0.50e-3;
params.fmin = 10;
params.fmax = 8000;
params.numFrequencyPoints = "auto";
params.frequencySpacing = "hybrid";
end
