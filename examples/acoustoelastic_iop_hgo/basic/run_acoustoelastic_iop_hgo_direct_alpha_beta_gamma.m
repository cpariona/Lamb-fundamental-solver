clear; clc; close all;
startup

% Direct alpha-beta-gamma Li 2024 acoustoelastic dispersion example.
%
% This first-stage example bypasses IOP/HGO and solves the matrix problem
% directly using prescribed acoustoelastic parameters.

params = struct();
params.alpha = 74e3;                % Pa, in-situ out-of-plane shear stiffness
params.beta = 12 * params.alpha;    % Pa, representative beta/alpha from Li et al.
params.gamma = 0.8 * params.alpha;  % Pa, representative gamma/alpha under normal IOP
params.thickness = 0.55e-3;         % m
params.rho = 1060;                  % kg/m^3
params.rhoF = 1000;                 % kg/m^3
params.fluidBulkModulus = 2.2e9;    % Pa
params.frequency = linspace(2e3, 30e3, 80);

options = defaultAcoustoelasticIOPHGOOptions();
options.branch = "A0";
options.M54_variant = "corrected";
options.cMin = 0.5;
options.cMax = 30;
options.numCpScanPoints = 1800;

result = solveAcoustoelasticDispersion(params, options);

figure('Color', 'w');
valid = result.validCp & isfinite(result.Cp);
plot(result.frequency(valid) / 1e3, result.Cp(valid), 'LineWidth', 2);
grid on;
xlabel('frequency [kHz]');
ylabel('Phase velocity Cp [m/s]');
title('Li 2024 direct acoustoelastic solver: prescribed alpha, beta, gamma');

assignin('base', 'AcoustoelasticIOPHGODirectResult', result);
