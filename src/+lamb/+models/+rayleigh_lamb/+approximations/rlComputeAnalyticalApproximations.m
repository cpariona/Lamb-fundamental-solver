function approximations = rlComputeAnalyticalApproximations(frequency, material, geometry)
% Compute analytical low-frequency approximations for fundamental Lamb modes.

approximations = struct();
approximations.A0ThinPlate = lamb.models.rayleigh_lamb.approximations.rlComputeA0ThinPlateApproximation(frequency, material, geometry);
approximations.S0Extensional = lamb.models.rayleigh_lamb.approximations.rlComputeS0ExtensionalApproximation(frequency, material, geometry);
end
