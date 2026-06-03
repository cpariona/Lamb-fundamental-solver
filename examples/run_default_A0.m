% Run the default A0-only fundamental Lamb-wave calculation.

startup();

params = struct();
params.modelType = "YoungPoissonFixedCL";
params.rho = 1070;
params.E = 475e3;
params.nu = 0.4999;
params.CL = 1500;
params.lambda = 2.40e9;
params.mu = 158e3;
params.thickness = 0.50e-3;
params.fmin = 10;
params.fmax = 8000;
params.numFrequencyPoints = 250;
params.frequencySpacing = "logspace";

options = struct();
options.computeA0 = true;
options.computeS0 = false;
options.gridPointsInitial = 3000;
options.gridPointsTracking = 600;
options.jumpTol = 0.35;
options.residualTolerance = 1e-5;

results = computeFundamentalLambModes(params, options);

mode = results.modes.A0;
fprintf('A0 valid points: %d / %d\n', sum(mode.valid), numel(mode.valid));
fprintf('A0 Cp range: %.6g to %.6g m/s\n', min(mode.Cp(mode.valid)), max(mode.Cp(mode.valid)));
fprintf('A0 max residual: %.3e\n', max(mode.residual(isfinite(mode.residual))));

figure;
plot(mode.frequency, mode.Cp, 'LineWidth', 2);
grid on;
xlabel('frequency [Hz]');
ylabel('Phase velocity Cp [m/s]');
title('A0 phase velocity');
