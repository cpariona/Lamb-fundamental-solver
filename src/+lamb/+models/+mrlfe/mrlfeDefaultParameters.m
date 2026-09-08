function params = mrlfeDefaultParameters()
%MRLFEDEFAULTPARAMETERS Public default physical parameters for mRLFE.
%   Fields use SI units as indicated by their suffixes: Pa, Pa*s, kg/m^3,
%   m, and m/s. thickness_m is full physical thickness.

params = struct();
params.mu_Pa = 75e3;
params.etaS_Pas = 0.05;
params.rho_kgm3 = 1000;
params.nu = 0.4999;
params.thickness_m = 0.5e-3;
params.fluidDensity_kgm3 = 1000;
params.fluidSoundSpeed_mps = 1500;
end
