function approximations = computeAnalyticalApproximations(frequency, material, geometry)
% Compute analytical low-frequency approximations for fundamental Lamb modes.

approximations = struct();
approximations.A0ThinPlate = computeA0ThinPlateApproximation(frequency, material, geometry);
approximations.S0Extensional = computeS0ExtensionalApproximation(frequency, material, geometry);
end
