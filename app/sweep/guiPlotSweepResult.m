function guiPlotSweepResult(normalizedSweep, ax)
%GUIPLOTSWEEPRESULT Plot normalized GUI sweep curves.
%
% This plotting helper is model-neutral. Model adapters should normalize raw
% solver outputs into normalizedSweep.curves before plotting.

cla(ax); hold(ax, 'on'); grid(ax, 'on');

curves = normalizedSweep.curves;
legendText = strings(1, numel(curves));

for i = 1:numel(curves)
    frequency = curves(i).frequency_Hz(:);
    cp = curves(i).Cp_mps(:);
    valid = curves(i).validMask(:);

    if isempty(frequency) || isempty(cp) || isempty(valid)
        continue;
    end

    valid = valid & isfinite(frequency) & isfinite(cp);
    x = frequency;
    y = cp;
    x(~valid) = nan;
    y(~valid) = nan;

    lineHandle = plot(ax, x, y, 'LineWidth', 1.8);
    legendText(i) = string(curves(i).label);

    if any(valid)
        lastIdx = find(valid, 1, 'last');
        plot(ax, frequency(lastIdx), cp(lastIdx), 'o', ...
            'MarkerSize', 7, 'LineWidth', 1.4, ...
            'Color', lineHandle.Color, 'MarkerFaceColor', lineHandle.Color, ...
            'HandleVisibility', 'off');
    end
end

xlabel(ax, 'frequency [Hz]');
ylabel(ax, 'Phase velocity Cp [m/s]');
setSweepPlotLimits(ax, 'CpAxis', 'y');
title(ax, sprintf('%s %s sweep', normalizedSweep.modelName, normalizedSweep.branchName), 'Interpreter', 'none');
legend(ax, legendText(legendText ~= ""), 'Location', 'best', 'Interpreter', 'none');
hold(ax, 'off');
end
