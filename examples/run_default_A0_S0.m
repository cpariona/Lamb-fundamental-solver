% Run the default A0/S0 fundamental Lamb-wave calculation.
% S0 is currently experimental and should be benchmarked before use.

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
options.computeS0 = true;
options.gridPointsInitial = 3000;
options.gridPointsTracking = 600;
options.jumpTol = 0.35;
options.residualTolerance = 1e-5;

results = computeFundamentalLambModes(params, options);

modeNames = fieldnames(results.modes);
for i = 1:numel(modeNames)
    name = modeNames{i};
    mode = results.modes.(name);
    fprintf('%s valid points: %d / %d\n', name, sum(mode.valid), numel(mode.valid));
    if any(mode.valid)
        fprintf('%s Cp range: %.6g to %.6g m/s\n', name, min(mode.Cp(mode.valid)), max(mode.Cp(mode.valid)));
    end
    if any(isfinite(mode.residual))
        fprintf('%s max residual: %.3e\n', name, max(mode.residual(isfinite(mode.residual))));
    end
end

figure;
hold on;
if isfield(results.modes, 'A0')
    plot(results.modes.A0.frequency, results.modes.A0.Cp, 'LineWidth', 2, 'DisplayName', 'A0');
end
if isfield(results.modes, 'S0') && any(isfinite(results.modes.S0.Cp))
    plot(results.modes.S0.frequency, results.modes.S0.Cp, '--', 'LineWidth', 1.5, 'DisplayName', 'S0 experimental');
end
grid on;
xlabel('frequency [Hz]');
ylabel('Phase velocity Cp [m/s]');
title('Fundamental Lamb mode phase velocities');
legend('Location', 'best');
hold off;
