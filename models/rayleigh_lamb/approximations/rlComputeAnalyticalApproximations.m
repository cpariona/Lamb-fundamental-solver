function approximations = rlComputeAnalyticalApproximations(frequency, material, geometry)
% Compute analytical low-frequency approximations for fundamental Lamb modes.

approximations = struct();
approximations.A0ThinPlate = rlComputeA0ThinPlateApproximation(frequency, material, geometry);
approximations.S0Extensional = rlComputeS0ExtensionalApproximation(frequency, material, geometry);
end
