clear; clc; close all;
startup

% Dimensionless diagnostic inspired by Appendix Fig. A1 of Li et al. 2024.
%
% The plot uses:
%   x = f*h/sqrt(alpha/rho)
%   y = c/sqrt(alpha/rho)
%
% This script is intended to test the direct alpha-beta-gamma solver shape,
% not the IOP/HGO constitutive block.

params = struct();
params.alpha = 74e3;                % Pa, arbitrary dimensional scale
params.beta = 4 * params.alpha;     % Appendix Fig. A1 solid-line ratio beta/alpha = 4
params.gamma = 0.92 * params.alpha; % Appendix Fig. A1 solid-line ratio gamma/alpha = 0.92
params.thickness = 0.55e-3;         % m
params.rho = 1060;                  % kg/m^3
params.rhoF = 1000;                 % kg/m^3
params.fluidBulkModulus = 2.2e9;    % Pa

cShear = sqrt(params.alpha / params.rho);
xDimensionless = linspace(0.05, 2.5, 90);
params.frequency = xDimensionless * cShear / params.thickness;

baseOptions = defaultLi2024AcoustoelasticOptions();
baseOptions.M54_variant = "corrected";
baseOptions.numCpScanPoints = 1800;
baseOptions.usePhysicalCpWindow = true;

optionsA0 = baseOptions;
optionsA0.branch = "A0";
resultA0 = solveDispersion_Li2024_Acoustoelastic(params, optionsA0);

optionsA0High = baseOptions;
optionsA0High.branch = "A0High";
resultA0High = solveDispersion_Li2024_Acoustoelastic(params, optionsA0High);

optionsS0 = baseOptions;
optionsS0.branch = "S0";
resultS0 = solveDispersion_Li2024_Acoustoelastic(params, optionsS0);

figure('Color', 'w');
hold on; grid on;
plotDimensionless(resultA0, cShear, params.thickness, 'A0 low corrected');
plotDimensionless(resultA0High, cShear, params.thickness, 'A0 high corrected');
plotDimensionless(resultS0, cShear, params.thickness, 'S0 corrected');
yline(0.955, ':', 'A0 high-f target ~0.955', 'HandleVisibility', 'off');
yline(sqrt((2*params.beta + 2*params.gamma) / params.alpha), ':', 'S0 f=0 target', 'HandleVisibility', 'off');
xlabel('f h / sqrt(alpha/rho) [-]');
ylabel('c / sqrt(alpha/rho) [-]');
title('Li 2024 direct solver: dimensionless diagnostic inspired by Fig. A1');
legend('Location', 'best');
hold off;

fprintf('\nLi 2024 dimensionless A1-style diagnostic\n');
printSummary('A0 low', resultA0, cShear, params.thickness);
printSummary('A0 high', resultA0High, cShear, params.thickness);
printSummary('S0', resultS0, cShear, params.thickness);

assignin('base', 'Li2024A1DiagnosticA0', resultA0);
assignin('base', 'Li2024A1DiagnosticA0High', resultA0High);
assignin('base', 'Li2024A1DiagnosticS0', resultS0);

function plotDimensionless(result, cShear, h, labelText)
valid = result.validCp & isfinite(result.Cp);
x = result.frequency(valid) * h / cShear;
y = result.Cp(valid) / cShear;
plot(x, y, 'LineWidth', 2, 'DisplayName', labelText);
if any(valid)
    idxValid = find(valid);
    idx = idxValid(end);
    plot(result.frequency(idx)*h/cShear, result.Cp(idx)/cShear, 'o', 'HandleVisibility', 'off');
end
end

function printSummary(labelText, result, cShear, h)
valid = result.validCp & isfinite(result.Cp);
if any(valid)
    xMax = max(result.frequency(valid) * h / cShear);
    yMin = min(result.Cp(valid) / cShear);
    yMax = max(result.Cp(valid) / cShear);
    fprintf('%s: valid %d/%d, y %.4g..%.4g, max x %.4g, Cp window %.4g..%.4g m/s\n', ...
        labelText, nnz(valid), numel(valid), yMin, yMax, xMax, ...
        result.gridInfo.cMin, result.gridInfo.cMax);
else
    fprintf('%s: no valid points\n', labelText);
end
end
