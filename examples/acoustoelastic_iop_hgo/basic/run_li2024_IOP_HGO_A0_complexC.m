clear; clc; close all;
startup

% Li 2024 acoustoelastic complex-C continuation example.
%
% This example keeps the previously tested real-Cp strategies available, but
% adds a parallel complex determinant continuation route:
%
%   real-Cp singular-vector tracker -> seed
%   complex c = cr + i*ci continuation -> det(M)=0 diagnostic

params = struct();

% Geometry and pressure.
params.IOP = 15 * 133.322;          % Pa, 15 mmHg
params.R = 7.8e-3;                  % m
params.thickness = 550e-6;          % m

% HGO parameters. Example values for pipeline testing only.
params.mu = 50e3;                   % Pa
params.k1 = 25e3;                   % Pa
params.k2 = 100;                    % dimensionless

% Densities and fluid bulk modulus.
params.rho = 1060;                  % kg/m^3
params.rhoF = 1000;                 % kg/m^3
params.fluidBulkModulus = 2.2e9;    % Pa

% Frequency range.
params.frequency = linspace(6e3, 35e3, 100);

options = defaultLi2024AcoustoelasticOptions();
options.M54_variant = "corrected";
options.branch = "A0";
options.trackingDirection = "backward";
options.minDimensionlessFrequency = 0.20;
options.numCpScanPoints = 1800;

% Step 1: real-Cp seed using the best current real-axis tracker.
seedOptions = options;
seedOptions.trackingMethod = "singularVectorTracking";
seedOptions.predictiveWindow = 0.18;
seedOptions.predictionWeight = 8.0;
seedOptions.curvatureWeight = 4.0;
seedOptions.macWeight = 12.0;
seedResult = solveDispersionIOPHGO_Li2024(params, seedOptions);

% Step 2: complex-C continuation over the direct alpha-beta-gamma problem.
complexOptions = options;
complexOptions.complexCInitialImagRatio = -1e-3;
complexOptions.complexCImagLimitRatio = 0.50;
complexOptions.complexCMaxIter = 250;
complexOptions.complexCMaxFunEvals = 900;
complexResult = solveDispersionComplexC_Li2024_Acoustoelastic(seedResult.directParams, complexOptions, seedResult);

figure('Color', 'w');
validSeed = seedResult.validCp & isfinite(seedResult.Cp);
validComplex = complexResult.validCp & isfinite(complexResult.CpReal);
plot(seedResult.frequency(validSeed)/1e3, seedResult.Cp(validSeed), '--', 'LineWidth', 1.4, 'DisplayName', 'real Cp seed');
hold on; grid on;
plot(complexResult.frequency(validComplex)/1e3, complexResult.CpReal(validComplex), 'LineWidth', 2, 'DisplayName', 'complex-C real part');
xlabel('frequency [kHz]');
ylabel('Phase velocity [m/s]');
title('Li 2024 IOP/HGO A0 complex-C continuation diagnostic');
legend('Location', 'best');
hold off;

figure('Color', 'w');
plot(complexResult.frequency(validComplex)/1e3, complexResult.CpImag(validComplex), 'LineWidth', 2);
grid on;
xlabel('frequency [kHz]');
ylabel('Imaginary phase velocity Im(c) [m/s]');
title('Li 2024 complex-C imaginary component');

fprintf('\nLi 2024 IOP/HGO A0 complex-C continuation diagnostic\n');
fprintf('sigma = %.3f kPa, lambda = %.6f\n', seedResult.constitutiveState.sigma/1e3, seedResult.constitutiveState.lambda);
fprintf('seed valid Cp points = %d/%d\n', seedResult.diagnostics.validCpPoints, seedResult.diagnostics.totalPoints);
fprintf('complex valid Cp points = %d/%d\n', complexResult.diagnostics.validCpPoints, complexResult.diagnostics.totalPoints);
fprintf('complex CpReal range = %.4g..%.4g m/s\n', complexResult.diagnostics.minCpReal, complexResult.diagnostics.maxCpReal);
fprintf('min abs(det(M)) = %.3e\n', complexResult.diagnostics.minAbsDet);
fprintf('median |Im(c)/Re(c)| = %.3e\n', complexResult.diagnostics.medianAbsImagOverReal);

assignin('base', 'Li2024IOPHGOA0ComplexSeedResult', seedResult);
assignin('base', 'Li2024IOPHGOA0ComplexResult', complexResult);
