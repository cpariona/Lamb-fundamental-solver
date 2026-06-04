function mrlfeParams = defaultMRLFEParams()
% Return default parameters for the mRLFE elastic plotting prototype.
%
% This first implementation solves a real-k elastic version of the modified
% Rayleigh-Lamb fluid-loaded model. Viscosity and complex-k attenuation are
% intentionally reserved for a later implementation stage.

mrlfeParams = struct();
mrlfeParams.fluidDensity = 1000;       % [kg/m^3]
mrlfeParams.fluidSoundSpeed = 1500;    % [m/s]
mrlfeParams.etaL = 0;                  % [Pa*s], reserved for future complex model
mrlfeParams.etaS = 0;                  % [Pa*s], reserved for future complex model
mrlfeParams.solveComplexK = false;
mrlfeParams.seedSource = "RayleighLamb";
mrlfeParams.branchNames = ["A0Like", "S0Like"];
end
