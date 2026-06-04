function approx = computeS0ExtensionalApproximation(frequency, material, geometry)
% Compute the low-frequency S0 extensional plate approximation.
%
% Convention:
%   thickness is the total plate thickness.
%   kThickness = k * thickness.

frequency = frequency(:).';
omega = 2 * pi * frequency;
thickness = geometry.thickness;

CpExtensional = sqrt(material.E / (material.rho * (1 - material.nu^2)));
Cp = CpExtensional * ones(size(frequency));
k = omega ./ Cp;

approx = struct();
approx.name = "S0Extensional";
approx.family = "symmetric";
approx.description = "Low-frequency plane-stress extensional approximation for S0.";
approx.frequency = frequency;
approx.omega = omega;
approx.Cp = Cp;
approx.k = k;
approx.kThickness = k * thickness;
approx.valid = isfinite(Cp) & Cp > 0;
approx.CpExtensional = CpExtensional;
end
