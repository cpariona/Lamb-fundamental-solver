clear; clc; close all;
startup

% Li 2024 IOP sweep using the current recommended A0-low strategy.
%
% Strategy:
%   corrected M54 + A0 branch + backward globalScan
%
% Purpose:
%   Test physical monotonicity of the IOP/HGO constitutive block and the
%   resulting A0 dispersion curves.

baseParams = struct();

% Geometry.
baseParams.R = 7.8e-3;                  % m
baseParams.thickness = 550e-6;          % m

% HGO parameters. Example values for pipeline testing only.
baseParams.mu = 50e3;                   % Pa
baseParams.k1 = 25e3;                   % Pa
baseParams.k2 = 100;                    % dimensionless

% Densities and fluid bulk modulus.
baseParams.rho = 1060;                  % kg/m^3
baseParams.rhoF = 1000;                 % kg/m^3
baseParams.fluidBulkModulus = 2.2e9;    % Pa

% Frequency range.
baseParams.frequency = linspace(6e3, 35e3, 100);

IOP_mmHg = [5, 10, 15, 20, 25];
IOP_Pa = IOP_mmHg * 133.322;

options = defaultLi2024AcoustoelasticOptions();
options.M54_variant = "corrected";
options.branch = "A0";
options.trackingDirection = "backward";
options.trackingMethod = "globalScan";
options.minDimensionlessFrequency = 0.20;
options.numCpScanPoints = 1800;

results = cell(numel(IOP_Pa), 1);
sigma_kPa = nan(numel(IOP_Pa), 1);
lambda = nan(numel(IOP_Pa), 1);
alpha_kPa = nan(numel(IOP_Pa), 1);
beta_kPa = nan(numel(IOP_Pa), 1);
gamma_kPa = nan(numel(IOP_Pa), 1);
medianCp = nan(numel(IOP_Pa), 1);
cpAt20kHz = nan(numel(IOP_Pa), 1);
validPoints = nan(numel(IOP_Pa), 1);

for i = 1:numel(IOP_Pa)
    params = baseParams;
    params.IOP = IOP_Pa(i);

    results{i} = solveDispersionIOPHGO_Li2024(params, options);
    state = results{i}.constitutiveState;

    sigma_kPa(i) = state.sigma / 1e3;
    lambda(i) = state.lambda;
    alpha_kPa(i) = results{i}.directParams.alpha / 1e3;
    beta_kPa(i) = results{i}.directParams.beta / 1e3;
    gamma_kPa(i) = results{i}.directParams.gamma / 1e3;

    valid = results{i}.validCp & isfinite(results{i}.Cp);
    validPoints(i) = nnz(valid);
    if any(valid)
        medianCp(i) = median(results{i}.Cp(valid), 'omitnan');
        cpAt20kHz(i) = interp1(results{i}.frequency(valid), results{i}.Cp(valid), 20e3, 'linear', nan);
    end

    fprintf('IOP %.1f mmHg: sigma %.3f kPa, lambda %.6f, valid %d/%d\n', ...
        IOP_mmHg(i), sigma_kPa(i), lambda(i), validPoints(i), numel(results{i}.Cp));
end

summaryTable = table(IOP_mmHg(:), IOP_Pa(:)/1e3, sigma_kPa, lambda, alpha_kPa, beta_kPa, gamma_kPa, ...
    validPoints, medianCp, cpAt20kHz, ...
    'VariableNames', {'IOP_mmHg','IOP_kPa','Sigma_kPa','Lambda','Alpha_kPa','Beta_kPa','Gamma_kPa', ...
    'ValidPoints','MedianCp_mps','CpAt20kHz_mps'});

figure('Color', 'w');
hold on; grid on;
for i = 1:numel(results)
    valid = results{i}.validCp & isfinite(results{i}.Cp);
    plot(results{i}.frequency(valid)/1e3, results{i}.Cp(valid), 'LineWidth', 1.7, ...
        'DisplayName', sprintf('IOP %.0f mmHg', IOP_mmHg(i)));
end
xlabel('frequency [kHz]');
ylabel('Phase velocity Cp [m/s]');
title('Li 2024 IOP/HGO A0 corrected backward global-scan IOP sweep');
legend('Location', 'best');
hold off;

figure('Color', 'w');
plot(IOP_mmHg, cpAt20kHz, 'o-', 'LineWidth', 2);
grid on;
xlabel('IOP [mmHg]');
ylabel('Cp at 20 kHz [m/s]');
title('Li 2024 A0 sensitivity to IOP at 20 kHz');

figure('Color', 'w');
plot(IOP_mmHg, alpha_kPa - gamma_kPa, 'o-', 'LineWidth', 2, 'DisplayName', 'alpha - gamma');
hold on; grid on;
plot(IOP_mmHg, sigma_kPa, 's--', 'LineWidth', 1.6, 'DisplayName', 'sigma');
xlabel('IOP [mmHg]');
ylabel('stress [kPa]');
title('Li 2024 constitutive check: alpha - gamma vs sigma');
legend('Location', 'best');
hold off;

fprintf('\nLi 2024 IOP sweep summary\n');
disp(summaryTable);

assignin('base', 'Li2024IOPSweepResults', results);
assignin('base', 'Li2024IOPSweepSummary', summaryTable);
