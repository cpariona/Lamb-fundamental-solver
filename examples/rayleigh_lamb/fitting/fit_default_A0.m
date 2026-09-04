clear; clc; close all;
addpath(fileparts(fileparts(fileparts(fileparts(mfilename('fullpath'))))));
startup;

%FIT_DEFAULT_A0 Example Rayleigh-Lamb A0 fit against synthetic data.
%
% This example fits only mu while keeping thickness, rho, and nu fixed.

trueParams = rlDefaultParams();
trueParams.mu = 85e3;
trueParams.thickness = 0.50e-3;
trueParams.rho = 1070;
trueParams.nu = 0.4999;

frequency_Hz = linspace(1000, 8000, 12).';
solverOptions = rlDefaultOptions("Fast");

CpSynthetic_mps = rlEvaluateFitModel(trueParams, frequency_Hz, "A0", solverOptions);

experimental = struct();
experimental.frequency_Hz = frequency_Hz;
experimental.Cp_mps = CpSynthetic_mps;
experimental.validMask = true(size(frequency_Hz));

fitConfig = struct();
fitConfig.branchName = "A0";
fitConfig.freeParams = "mu";
fitConfig.fixedParams = struct( ...
    'thickness', trueParams.thickness, ...
    'rho', trueParams.rho, ...
    'nu', trueParams.nu);
fitConfig.initialGuess = struct('mu', 50e3);
fitConfig.bounds = struct('mu', [20e3, 200e3]);
fitConfig.solverOptions = solverOptions;

fitResult = rlFitDispersionData(experimental, fitConfig);
relativeRMSE = fitResult.metrics.RMSE / mean(abs(experimental.Cp_mps));

fprintf('\nRayleigh-Lamb A0 synthetic fit complete.\n');
fprintf('True mu: %.3f kPa\n', trueParams.mu / 1e3);
fprintf('Fit  mu: %.3f kPa\n', fitResult.bestParams.mu / 1e3);
fprintf('RMSE: %.6g m/s\n', fitResult.metrics.RMSE);
fprintf('Relative RMSE: %.6g\n', relativeRMSE);
fprintf('Identifiability: %s\n', string(fitResult.identifiability.classification));

figure('Color', 'w');
plot(experimental.frequency_Hz ./ 1e3, experimental.Cp_mps, 'o', 'LineWidth', 1.2);
hold on;
plot(fitResult.frequency_Hz ./ 1e3, fitResult.Cp_fit_mps, '-', 'LineWidth', 1.2);
grid on;
xlabel('Frequency [kHz]');
ylabel('Phase speed [m/s]');
title('Rayleigh-Lamb A0 synthetic fit');
legend({'Synthetic data', 'Fitted model'}, 'Location', 'best');
applyPhysicalYLimits(experimental.Cp_mps, fitResult.Cp_fit_mps);

figure('Color', 'w');
plot(fitResult.frequency_Hz ./ 1e3, fitResult.residualInfo.rawResiduals_mps, 'o-', 'LineWidth', 1.2);
grid on;
xlabel('Frequency [kHz]');
ylabel('Residual [m/s]');
title('Rayleigh-Lamb A0 synthetic fit residuals');

assignin('base', 'RayleighLambA0FitResult', fitResult);

function applyPhysicalYLimits(CpExp_mps, CpFit_mps)
CpAll = [CpExp_mps(:); CpFit_mps(:)];
CpAll = CpAll(isfinite(CpAll));
if isempty(CpAll)
    return;
end
CpCenter = mean(CpAll);
CpSpan = max(CpAll) - min(CpAll);
yMargin = max([0.05 * abs(CpCenter), 1.2 * CpSpan, 1e-3]);
ylim([CpCenter - yMargin, CpCenter + yMargin]);
end
