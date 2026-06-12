clear; clc; close all;
startup

% Li 2024 acoustoelastic solver example using the IOP/HGO constitutive block.
%
% Recommended first-stage workflow:
%   IOP/R/h/mu/k1/k2 -> lambda -> alpha,beta,gamma
%   -> corrected M54 matrix -> A0 branch -> backward singular-vector tracking
%
% S0 is intentionally not used here because its branch identity is still
% under diagnostic evaluation.

params = struct();

% Geometry and pressure.
params.IOP = 15 * 133.322;          % Pa, 15 mmHg
params.R = 7.8e-3;                  % m
params.thickness = 550e-6;          % m

% HGO parameters. These are example values for testing the pipeline and must
% be replaced by the paper-specific or fitted values for quantitative work.
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
options.trackingMethod = "singularVectorTracking";
options.predictiveWindow = 0.18;
options.predictiveMinWidth = 0.05;
options.predictionWeight = 8.0;
options.curvatureWeight = 4.0;
options.macWeight = 12.0;
options.minAcceptableMAC = 0.00;
options.minDimensionlessFrequency = 0.20;
options.numCpScanPoints = 1800;

result = solveDispersionIOPHGO_Li2024(params, options);
state = result.constitutiveState;

figure('Color', 'w');
valid = result.validCp & isfinite(result.Cp);
plot(result.frequency(valid)/1e3, result.Cp(valid), 'LineWidth', 2);
grid on;
xlabel('frequency [kHz]');
ylabel('Phase velocity Cp [m/s]');
title('Li 2024 IOP/HGO A0 corrected backward singular-vector tracking solver');

fprintf('\nLi 2024 IOP/HGO A0 backward singular-vector tracking example\n');
fprintf('IOP = %.3f kPa, R = %.3f mm, h = %.3f um\n', params.IOP/1e3, params.R*1e3, params.thickness*1e6);
fprintf('sigma = %.3f kPa\n', state.sigma/1e3);
fprintf('lambda = %.6f, stretch residual = %.3e Pa\n', state.lambda, state.stretchInfo.residual);
fprintf('alpha = %.3f kPa, beta = %.3f kPa, gamma = %.3f kPa\n', ...
    result.directParams.alpha/1e3, result.directParams.beta/1e3, result.directParams.gamma/1e3);
fprintf('tracking method = %s, direction = %s\n', string(result.options.trackingMethod), string(result.options.trackingDirection));
fprintf('median MAC = %.4f, min MAC = %.4f\n', result.diagnostics.medianMAC, result.diagnostics.minMAC);
fprintf('valid Cp points = %d/%d\n', result.diagnostics.validCpPoints, result.diagnostics.totalPoints);

assignin('base', 'Li2024IOPHGOA0BackwardResult', result);
