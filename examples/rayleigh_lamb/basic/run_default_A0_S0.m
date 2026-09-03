% Run the default A0/S0 fundamental Lamb-wave calculation.
% S0 is currently experimental and should be benchmarked before use.

addpath(fileparts(fileparts(fileparts(fileparts(mfilename('fullpath'))))));
startup;

params = rlDefaultParams();
options = rlDefaultOptions("Balanced");
options.computeA0 = true;
options.computeS0 = true;

results = rlComputeFundamentalLambModes(params, options);

modeNames = fieldnames(results.modes);
for i = 1:numel(modeNames)
    name = modeNames{i};
    mode = results.modes.(name);
    fprintf('%s valid points: %d / %d\n', name, sum(mode.validMask), numel(mode.validMask));
    if any(mode.validMask)
        fprintf('%s Cp range: %.6g to %.6g m/s\n', name, min(mode.phaseVelocity_mps(mode.validMask)), max(mode.phaseVelocity_mps(mode.validMask)));
    end
    if any(isfinite(mode.residual))
        fprintf('%s max residual: %.3e\n', name, max(mode.residual(isfinite(mode.residual))));
    end
end

figure;
hold on;
if isfield(results.modes, 'A0')
    plot(results.modes.A0.frequency_Hz, results.modes.A0.phaseVelocity_mps, 'LineWidth', 2, 'DisplayName', 'A0');
end
if isfield(results.modes, 'S0') && any(isfinite(results.modes.S0.phaseVelocity_mps))
    plot(results.modes.S0.frequency_Hz, results.modes.S0.phaseVelocity_mps, '--', 'LineWidth', 1.5, 'DisplayName', 'S0 experimental');
end
grid on;
xlabel('frequency [Hz]');
ylabel('Phase velocity Cp [m/s]');
title('Fundamental Lamb mode phase velocities');
legend('Location', 'best');
hold off;
