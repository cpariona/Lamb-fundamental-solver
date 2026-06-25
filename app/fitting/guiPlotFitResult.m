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
legendEntries = {};

if isfield(normalizedFit, 'fullCurve') && isstruct(normalizedFit.fullCurve) && ...
        isfield(normalizedFit.fullCurve, 'frequency_Hz') && ~isempty(normalizedFit.fullCurve.frequency_Hz)
    fullFrequency_kHz = normalizedFit.fullCurve.frequency_Hz(:) ./ 1e3;
    fullCp = normalizedFit.fullCurve.Cp_mps(:);
    fullValid = normalizedFit.fullCurve.validMask(:) & isfinite(fullFrequency_kHz) & isfinite(fullCp);
    if any(fullValid)
        plot(ax, fullFrequency_kHz(fullValid), fullCp(fullValid), '-', 'LineWidth', 1.5);
        legendEntries{end+1} = 'Full fitted curve'; %#ok<AGROW>
    end
end

if isfield(normalizedFit, 'qc') && isfield(normalizedFit.qc, 'baseline') && ...
        isfield(normalizedFit.qc.baseline, 'Cp0_mps') && isfinite(normalizedFit.qc.baseline.Cp0_mps)
    baselineFrequency = frequency_kHz(valid);
    baselineCp = normalizedFit.qc.baseline.Cp0_mps * ones(size(baselineFrequency));
    if ~isempty(baselineFrequency)
        plot(ax, baselineFrequency, baselineCp, '--', 'LineWidth', 1.0);
        legendEntries{end+1} = 'Constant-speed baseline'; %#ok<AGROW>
    end
end

plot(ax, frequency_kHz(valid), CpExp(valid), 'o', 'LineWidth', 1.2);
legendEntries{end+1} = 'Experimental data';
plot(ax, frequency_kHz(valid), CpFit(valid), '.', 'MarkerSize', 14);
legendEntries{end+1} = 'Model at data points';

xlabel(ax, 'Frequency [kHz]');
ylabel(ax, 'Phase speed [m/s]');
if isfield(normalizedFit, 'qc')
    title(ax, sprintf('%s %s fit | PhysicalQC: %s', normalizedFit.modelName, normalizedFit.branchName, string(normalizedFit.qc.classification)), 'Interpreter', 'none');
else
    title(ax, sprintf('%s %s fit', normalizedFit.modelName, normalizedFit.branchName), 'Interpreter', 'none');
end
legend(ax, legendEntries, 'Location', 'best', 'Interpreter', 'none');
applyPhysicalYLimits(ax, CpExp(valid), CpFit(valid), normalizedFit);
hold(ax, 'off');
end

function applyPhysicalYLimits(ax, CpExp_mps, CpFit_mps, normalizedFit)
CpAll = [CpExp_mps(:); CpFit_mps(:)];
if nargin >= 4 && isfield(normalizedFit, 'fullCurve') && isfield(normalizedFit.fullCurve, 'Cp_mps')
    CpAll = [CpAll; normalizedFit.fullCurve.Cp_mps(:)];
end
CpAll = CpAll(isfinite(CpAll));
if isempty(CpAll)
    return;
end
CpCenter = mean(CpAll);
CpSpan = max(CpAll) - min(CpAll);
yMargin = max([0.05 * abs(CpCenter), 1.2 * CpSpan, 1e-3]);
ylim(ax, [CpCenter - yMargin, CpCenter + yMargin]);
end
