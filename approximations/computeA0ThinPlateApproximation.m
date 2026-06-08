function approx = computeA0ThinPlateApproximation(frequency, material, geometry)
% Compute the low-frequency A0 thin-plate flexural approximation.
%
% Convention:
%   thickness is the total plate thickness.
%   kThickness = k * thickness.

frequency = frequency(:).';
omega = 2 * pi * frequency;
thickness = geometry.thickness;

bendingStiffness = material.E * thickness^3 / (12 * (1 - material.nu^2));
rhoArea = material.rho * thickness;

Cp = (bendingStiffness / rhoArea)^(1/4) .* sqrt(omega);
k = omega ./ Cp;

approx = struct();
approx.name = "A0ThinPlate";
approx.family = "antisymmetric";
approx.description = "Low-frequency Kirchhoff-Love thin-plate flexural approximation for A0.";
approx.frequency = frequency;
approx.omega = omega;
approx.Cp = Cp;
approx.k = k;
approx.kThickness = k * thickness;
approx.valid = isfinite(Cp) & Cp > 0;
approx.bendingStiffness = bendingStiffness;
end
