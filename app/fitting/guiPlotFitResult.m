function guiPlotFitResult(normalizedFit, ax)
%GUIPLOTFITRESULT Plot normalized experimental data and fitted model.
%
% guiPlotFitResult(normalizedFit, ax)
%
% If ax is omitted, a new figure and axes are created.

if nargin < 2 || isempty(ax) || ~isgraphics(ax, 'axes')
    figure('Color', 'w');
    ax = axes();
end

cla(ax); hold(ax, 'on'); grid(ax, 'on');

frequency_kHz = normalizedFit.frequency_Hz(:) ./ 1e3;
CpExp = normalizedFit.Cp_exp_mps(:);
CpFit = normalizedFit.Cp_fit_mps(:);
valid = normalizedFit.validMask(:) & isfinite(frequency_kHz) & isfinite(CpExp) & isfinite(CpFit);

plot(ax, frequency_kHz(valid), CpExp(valid), 'o', 'LineWidth', 1.2);
plot(ax, frequency_kHz(valid), CpFit(valid), '-', 'LineWidth', 1.5);

xlabel(ax, 'Frequency [kHz]');
ylabel(ax, 'Phase speed [m/s]');
title(ax, sprintf('%s %s fit', normalizedFit.modelName, normalizedFit.branchName), 'Interpreter', 'none');
legend(ax, {'Experimental data', 'Fitted model'}, 'Location', 'best', 'Interpreter', 'none');
applyPhysicalYLimits(ax, CpExp(valid), CpFit(valid));
hold(ax, 'off');
end

function applyPhysicalYLimits(ax, CpExp_mps, CpFit_mps)
CpAll = [CpExp_mps(:); CpFit_mps(:)];
CpAll = CpAll(isfinite(CpAll));
if isempty(CpAll)
    return;
end
CpCenter = mean(CpAll);
CpSpan = max(CpAll) - min(CpAll);
yMargin = max([0.05 * abs(CpCenter), 1.2 * CpSpan, 1e-3]);
ylim(ax, [CpCenter - yMargin, CpCenter + yMargin]);
end
