% Run the default A0/S0 fundamental Lamb-wave calculation.
% S0 is currently experimental and should be benchmarked before use.

startup();

params = defaultParams();
options = defaultOptions("Balanced");
options.computeA0 = true;
options.computeS0 = true;

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
