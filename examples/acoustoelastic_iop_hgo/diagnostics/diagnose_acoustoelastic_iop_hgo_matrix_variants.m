clear; clc; close all;
startup

% Diagnostic comparison for the Li 2024 acoustoelastic matrix.
%
% The paper reports M54 = s2*(s1^2 + 1)*cosh(s1*k*h). Based on the modal
% solution term B4*sinh(s2*k*x3), a corrected variant with cosh(s2*k*h) is
% also evaluated here.

params = struct();
params.alpha = 74e3;                % Pa
params.beta = 12 * params.alpha;    % Pa
params.gamma = 0.8 * params.alpha;  % Pa
params.thickness = 0.55e-3;         % m
params.rho = 1060;                  % kg/m^3
params.rhoF = 1000;                 % kg/m^3
params.fluidBulkModulus = 2.2e9;    % Pa
params.frequency = linspace(2e3, 30e3, 80);

baseOptions = defaultAcoustoelasticIOPHGOOptions();
baseOptions.branch = "A0";
baseOptions.cMin = 0.5;
baseOptions.cMax = 30;
baseOptions.numCpScanPoints = 1800;

optionsPaper = baseOptions;
optionsPaper.M54_variant = "paper";
resultPaper = solveAcoustoelasticDispersion(params, optionsPaper);

optionsCorrected = baseOptions;
optionsCorrected.M54_variant = "corrected";
resultCorrected = solveAcoustoelasticDispersion(params, optionsCorrected);

figure('Color', 'w');
hold on; grid on;
plotVariant(resultPaper, 'paper M54');
plotVariant(resultCorrected, 'corrected M54');
xlabel('frequency [kHz]');
ylabel('Phase velocity Cp [m/s]');
title('Li 2024 acoustoelastic matrix diagnostic: M54 variants');
legend('Location', 'best');
hold off;

fprintf('\nLi 2024 matrix variant diagnostic\n');
printSummary('paper', resultPaper);
printSummary('corrected', resultCorrected);

assignin('base', 'AcoustoelasticIOPHGOMatrixVariantPaper', resultPaper);
assignin('base', 'AcoustoelasticIOPHGOMatrixVariantCorrected', resultCorrected);

function plotVariant(result, labelText)
valid = result.validCp & isfinite(result.Cp);
plot(result.frequency(valid)/1e3, result.Cp(valid), 'LineWidth', 2, 'DisplayName', labelText);
if any(valid)
    idx = find(valid, 1, 'last');
    plot(result.frequency(idx)/1e3, result.Cp(idx), 'o', 'HandleVisibility', 'off');
end
end

function printSummary(labelText, result)
d = result.diagnostics;
fprintf('%s: valid %d/%d, Cp %.4g..%.4g m/s, max valid f %.4g kHz, min sigmaMin %.3e\n', ...
    labelText, d.validCpPoints, d.totalPoints, d.minCp, d.maxCp, d.maxFrequencyValid/1e3, d.minSigmaMin);
end
