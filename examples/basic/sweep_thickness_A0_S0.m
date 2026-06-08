% Sweep thickness and compute A0/S0 phase velocity curves.
% S0 is currently experimental and should be benchmarked before use.

startup();

baseParams = defaultParams();
baseOptions = defaultOptions("Balanced");
baseOptions.computeA0 = true;
baseOptions.computeS0 = true;

thicknessVec = [0.1 0.2 0.3 0.4 0.5] * 1e-3;
resultsByThickness = cell(size(thicknessVec));

figure;
hold on;
for i = 1:numel(thicknessVec)
    params = baseParams;
    params.thickness = thicknessVec(i);

    results = computeFundamentalLambModes(params, baseOptions);
    resultsByThickness{i} = results;

    if isfield(results.modes, 'A0')
        plot(results.modes.A0.frequency, results.modes.A0.Cp, 'LineWidth', 1.5, ...
            'DisplayName', sprintf('A0, thickness = %.1f mm', thicknessVec(i) * 1e3));
    end
end
grid on;
xlabel('frequency [Hz]');
ylabel('Phase velocity Cp [m/s]');
title('A0 thickness sweep');
legend('Location', 'best');
hold off;

figure;
hold on;
for i = 1:numel(thicknessVec)
    results = resultsByThickness{i};
    if isfield(results.modes, 'S0') && any(isfinite(results.modes.S0.Cp))
        plot(results.modes.S0.frequency, results.modes.S0.Cp, 'LineWidth', 1.5, ...
            'DisplayName', sprintf('S0 experimental, thickness = %.1f mm', thicknessVec(i) * 1e3));
    end
end
grid on;
xlabel('frequency [Hz]');
ylabel('Phase velocity Cp [m/s]');
title('S0 experimental thickness sweep');
legend('Location', 'best');
hold off;

fprintf('\nThickness sweep summary\n');
fprintf('-----------------------\n');
for i = 1:numel(thicknessVec)
    results = resultsByThickness{i};
    fprintf('thickness = %.3f mm\n', thicknessVec(i) * 1e3);

    modeNames = fieldnames(results.modes);
    for j = 1:numel(modeNames)
        name = modeNames{j};
        mode = results.modes.(name);
        fprintf('  %s valid points: %d / %d', name, sum(mode.valid), numel(mode.valid));
        if any(mode.valid)
            fprintf(', Cp range: %.6g to %.6g m/s', min(mode.Cp(mode.valid)), max(mode.Cp(mode.valid)));
        end
        fprintf('\n');
    end
end
