function mrlfeParams = mrlfeDefaultInternalParameters()
%MRLFEDEFAULTINTERNALPARAMETERS Return internal mRLFE model parameters.

mrlfeParams = struct();
mrlfeParams.fluidDensity = 1000;       % [kg/m^3]
mrlfeParams.fluidSoundSpeed = 1500;    % [m/s]
mrlfeParams.etaL = 0;                  % [Pa*s]
mrlfeParams.etaS = 0;                  % [Pa*s]
mrlfeParams.solveComplexK = false;
mrlfeParams.seedSource = "RayleighLamb";
mrlfeParams.branchNames = ["A0Like", "S0Like"];

% Complex-k prototype controls.
mrlfeParams.initialImagKFraction = 1e-5;
mrlfeParams.maxImagKFraction = 0.50;
mrlfeParams.minImagKAbsolute = 1e-9;
end
