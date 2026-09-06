clear; clc; close all;
addpath(fileparts(fileparts(fileparts(fileparts(mfilename('fullpath'))))));
startup;

%FIT_AE_ATLASA0 Example AE IOP/HGO atlasA0 fit against synthetic data.
%
% This example fits only mu while keeping IOP, thickness, HGO fiber
% parameters, curvature, density, and fluid parameters fixed.

trueParams = struct();
trueParams.R = 7.8e-3;
trueParams.thickness = 550e-6;
trueParams.mu = 50e3;
trueParams.k1 = 25e3;
trueParams.k2 = 100;
trueParams.rho = 1060;
trueParams.rhoF = 1000;
trueParams.fluidBulkModulus = 2.2e9;
trueParams.IOP = 15 * 133.322;
trueParams.frequency = logspace(log10(300), log10(15e3), 35);

solverOptions = lamb.models.acoustoelastic_iop_hgo.defaultAcoustoelasticIOPHGOOptions();
solverOptions.M54_variant = "corrected";
solverOptions.normalizeRows = false;
solverOptions.usePhysicalCpWindow = false;
solverOptions.atlasNumYPoints = 300;
solverOptions.atlasTopNMinima = 12;
solverOptions.atlasBranchPolicy = "atlasA0";
solverOptions.atlasInitializationNumFrequencyPoints = 50;

[CpSynthetic_mps, syntheticRaw] = lamb.fitting.acoustoelastic_iop_hgo.aeEvaluateFitModel(trueParams, trueParams.frequency, "atlasA0", solverOptions);
validMask = syntheticRaw.validMask(:);

if ~any(validMask)
    error(['AE atlasA0 synthetic example produced zero valid points. ', ...
        'Use a validated atlas configuration or inspect solver reliability diagnostics.']);
end

experimental = struct();
experimental.frequency_Hz = trueParams.frequency(:);
experimental.Cp_mps = CpSynthetic_mps(:);
experimental.validMask = validMask;

fitConfig = struct();
fitConfig.branchName = "atlasA0";
fitConfig.freeParams = "mu";
fitConfig.fixedParams = rmfield(trueParams, {'mu', 'frequency'});
fitConfig.initialGuess = struct('mu', 48e3);
fitConfig.bounds = struct('mu', [45e3, 55e3]);
fitConfig.solverOptions = solverOptions;
fitConfig.fitOptions = struct('useStandardErrorWeights', false, ...
    'optimizerOptions', optimset('Display', 'off', 'MaxIter', 10, 'MaxFunEvals', 24, 'TolX', 1e-3));

fitResult = lamb.fitting.acoustoelastic_iop_hgo.aeFitDispersionData(experimental, fitConfig);
relativeRMSE = fitResult.metrics.RMSE / mean(abs(experimental.Cp_mps(experimental.validMask)));

fprintf('\nAE IOP/HGO atlasA0 synthetic fit complete.\n');
fprintf('True mu: %.3f kPa\n', trueParams.mu / 1e3);
fprintf('Fit  mu: %.3f kPa\n', fitResult.bestParams.mu / 1e3);
fprintf('RMSE: %.6g m/s\n', fitResult.metrics.RMSE);
fprintf('Relative RMSE: %.6g\n', relativeRMSE);
fprintf('Identifiability: %s\n', string(fitResult.identifiability.classification));

figure('Color', 'w');
plot(experimental.frequency_Hz(experimental.validMask) ./ 1e3, experimental.Cp_mps(experimental.validMask), 'o', 'LineWidth', 1.2);
hold on;
plot(fitResult.frequency_Hz(fitResult.validMask) ./ 1e3, fitResult.Cp_fit_mps(fitResult.validMask), '-', 'LineWidth', 1.2);
grid on;
xlabel('Frequency [kHz]');
ylabel('Phase speed [m/s]');
title('AE IOP/HGO atlasA0 synthetic fit');
legend({'Synthetic data', 'Fitted model'}, 'Location', 'best');
applyPhysicalYLimits(experimental.Cp_mps(experimental.validMask), fitResult.Cp_fit_mps(fitResult.validMask));

figure('Color', 'w');
plot(fitResult.frequency_Hz(fitResult.validMask) ./ 1e3, fitResult.residualInfo.rawResiduals_mps, 'o-', 'LineWidth', 1.2);
grid on;
xlabel('Frequency [kHz]');
ylabel('Residual [m/s]');
title('AE IOP/HGO atlasA0 synthetic fit residuals');

assignin('base', 'AEAtlasA0FitResult', fitResult);

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
