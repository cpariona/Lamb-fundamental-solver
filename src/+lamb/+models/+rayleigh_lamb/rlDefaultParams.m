function params = rlDefaultParams()
%RLDEFAULTPARAMS Default Rayleigh-Lamb physical and frequency parameters.
%   Physical fields use SI units: mu in Pa, rho in kg/m^3, and full
%   thickness in m. Frequency bounds are in Hz. modelType selects the
%   maintained material formulation; ShearPoisson uses mu, nu, and rho.

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
