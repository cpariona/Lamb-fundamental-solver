function approximations = rlComputeAnalyticalApproximations(frequency, material, geometry)
%RLCOMPUTEANALYTICALAPPROXIMATIONS Low-frequency A0/S0 estimates.
%   APPROXIMATIONS contains A0ThinPlate and S0Extensional estimates for the
%   supplied frequency, material, and geometry. These analytical estimates
%   are separate references and do not replace numerically tracked roots.

approximations = struct();
approximations.A0ThinPlate = lamb.models.rayleigh_lamb.approximations.rlComputeA0ThinPlateApproximation(frequency, material, geometry);
approximations.S0Extensional = lamb.models.rayleigh_lamb.approximations.rlComputeS0ExtensionalApproximation(frequency, material, geometry);
end
