% Run the default A0-only fundamental Lamb-wave calculation.

startup();

params = rlDefaultParams();
options = rlDefaultOptions("Balanced");
options.computeA0 = true;
options.computeS0 = false;

results = rlComputeFundamentalLambModes(params, options);

mode = results.modes.A0;
fprintf('A0 valid points: %d / %d\n', sum(mode.validMask), numel(mode.validMask));
fprintf('A0 Cp range: %.6g to %.6g m/s\n', min(mode.phaseVelocity_mps(mode.validMask)), max(mode.phaseVelocity_mps(mode.validMask)));
fprintf('A0 max residual: %.3e\n', max(mode.residual(isfinite(mode.residual))));

figure;
plot(mode.frequency_Hz, mode.phaseVelocity_mps, 'LineWidth', 2);
grid on;
xlabel('frequency [Hz]');
ylabel('Phase velocity Cp [m/s]');
title('A0 phase velocity');
