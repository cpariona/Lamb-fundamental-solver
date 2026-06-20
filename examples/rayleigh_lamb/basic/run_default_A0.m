% Run the default A0-only fundamental Lamb-wave calculation.

startup();

params = rlDefaultParams();
options = rlDefaultOptions("Balanced");
options.computeA0 = true;
options.computeS0 = false;

results = rlComputeFundamentalLambModes(params, options);

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
