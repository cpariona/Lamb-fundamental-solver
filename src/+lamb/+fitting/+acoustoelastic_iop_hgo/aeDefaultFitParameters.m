function params = aeDefaultFitParameters()
%AEDEFAULTFITPARAMETERS Default initial parameters for AE IOP/HGO fitting.

params = struct();
params.R = 7.8e-3;
params.thickness = 550e-6;
params.IOP = 15 * 133.322;
params.mu = 64e3;
params.k1 = 50e3;
params.k2 = 200;
params.rho = 1060;
params.rhoF = 1000;
params.fluidBulkModulus = 2.2e9;
params.frequency = logspace(log10(100), log10(35e3), 120);
end
