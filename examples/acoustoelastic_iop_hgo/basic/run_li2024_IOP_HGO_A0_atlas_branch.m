clear; clc; close all;
startup

% Acoustoelastic IOP/HGO atlas-branch solver example.
%
% This example uses the corrected M54 matrix without row normalization and
% follows a persistent atlas branch instead of the deepest minimum at each
% frequency.

params = struct();
params.IOP = 15 * 133.322;          % Pa
params.R = 7.8e-3;                  % m
params.thickness = 550e-6;          % m
params.mu = 50e3;                   % Pa
params.k1 = 25e3;                   % Pa
params.k2 = 100;                    % dimensionless
params.rho = 1060;                  % kg/m^3
params.rhoF = 1000;                 % kg/m^3
params.fluidBulkModulus = 2.2e9;    % Pa
params.frequency = logspace(log10(100), log10(35e3), 180);

options = defaultAcoustoelasticIOPHGOOptions();
options.M54_variant = "corrected";
options.normalizeRows = false;
options.usePhysicalCpWindow = false;
options.minDimensionlessFrequency = 0.0;
options.atlasYMin = 0.003;
options.atlasYMax = 2.0;
options.atlasNumYPoints = 1000;
options.atlasTopNMinima = 18;
options.atlasMaxLogYJump = 0.075;
options.atlasMinBranchPoints = 12;

atlasResult = solveAcoustoelasticIOPHGOBranch(params, options);

baselineOptions = options;
baselineOptions.normalizeRows = true;
baselineOptions.trackingMethod = "globalScan";
baselineOptions.numCpScanPoints = 3600;
normalizedGlobal = solveDispersionIOPHGO_Li2024(params, baselineOptions);

baselineOptions.normalizeRows = false;
rawGlobal = solveDispersionIOPHGO_Li2024(params, baselineOptions);

figure('Color', 'w');
hold on; grid on;
plot(atlasResult.frequency/1e3, atlasResult.Cp, 'k-', 'LineWidth', 2.8, 'DisplayName', 'atlas branch, corrected raw');
plot(rawGlobal.frequency/1e3, rawGlobal.Cp, '--', 'LineWidth', 1.4, 'DisplayName', 'globalScan, corrected raw');
plot(normalizedGlobal.frequency/1e3, normalizedGlobal.Cp, ':', 'LineWidth', 1.4, 'DisplayName', 'globalScan, corrected normalized');
xlabel('frequency [kHz]');
ylabel('Phase velocity Cp [m/s]');
title('Acoustoelastic IOP/HGO A0 atlas-branch candidate');
legend('Location', 'best');
hold off;

fprintf('\nAcoustoelastic IOP/HGO atlas-branch example\n');
fprintf('IOP = %.1f mmHg\n', params.IOP/133.322);
fprintf('selected BranchID = %.0f\n', atlasResult.selectedBranchID);
fprintf('valid Cp points = %d/%d\n', atlasResult.diagnostics.validCpPoints, atlasResult.diagnostics.totalPoints);
fprintf('Cp range = %.3f to %.3f m/s\n', atlasResult.diagnostics.minCp, atlasResult.diagnostics.maxCp);
fprintf('sigma = %.3f kPa, lambda = %.6f\n', atlasResult.constitutiveState.sigma/1e3, atlasResult.constitutiveState.lambda);

assignin('base', 'AcoustoelasticAtlasBranchResult', atlasResult);
assignin('base', 'AcoustoelasticRawGlobalScanResult', rawGlobal);
assignin('base', 'AcoustoelasticNormalizedGlobalScanResult', normalizedGlobal);
