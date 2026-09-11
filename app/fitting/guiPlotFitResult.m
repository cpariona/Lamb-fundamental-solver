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

legend(ax, 'off');
cla(ax); hold(ax, 'on'); grid(ax, 'on');

frequency_kHz = normalizedFit.frequency_Hz(:) ./ 1e3;
CpExp = normalizedFit.Cp_exp_mps(:);
CpFit = normalizedFit.Cp_fit_mps(:);
selected = normalizedFit.validMask(:) & isfinite(frequency_kHz);
experimentalValid = selected & isfinite(CpExp);
fittedValid = selected & isfinite(CpFit);
valid = experimentalValid & fittedValid;
legendHandles = gobjects(0,1);
if any(experimentalValid)
    legendHandles(end+1) = plot(ax, frequency_kHz(experimentalValid), CpExp(experimentalValid), ...
        'o', 'LineWidth', 1.2, 'DisplayName', 'Experimental data');
end
if any(fittedValid)
    legendHandles(end+1) = plot(ax, frequency_kHz(fittedValid), CpFit(fittedValid), ...
        '.', 'MarkerSize', 14, 'DisplayName', 'Model at data points');
end

if isfield(normalizedFit, 'fullCurve') && isstruct(normalizedFit.fullCurve) && ...
        isfield(normalizedFit.fullCurve, 'frequency_Hz') && ~isempty(normalizedFit.fullCurve.frequency_Hz)
    fullFrequency_kHz = normalizedFit.fullCurve.frequency_Hz(:) ./ 1e3;
    fullCp = normalizedFit.fullCurve.Cp_mps(:);
    fullValid = normalizedFit.fullCurve.validMask(:) & isfinite(fullFrequency_kHz) & isfinite(fullCp);
    if any(fullValid)
        fullCp(~fullValid) = nan;
        legendHandles(end+1) = plot(ax, fullFrequency_kHz, fullCp, '-', ...
            'LineWidth', 1.5, 'DisplayName', 'Fitted curve');
    end
end

if isfield(normalizedFit, 'requestedCurve') && isstruct(normalizedFit.requestedCurve) && ...
        isfield(normalizedFit.requestedCurve, 'frequency_Hz') && ~isempty(normalizedFit.requestedCurve.frequency_Hz)
    requestedFrequency_kHz = normalizedFit.requestedCurve.frequency_Hz(:) ./ 1e3;
    requestedCp = normalizedFit.requestedCurve.Cp_mps(:);
    requestedValid = normalizedFit.requestedCurve.validMask(:) & isfinite(requestedFrequency_kHz) & isfinite(requestedCp);
    if any(requestedValid)
        requestedCp(~requestedValid) = nan;
        legendHandles(end+1) = plot(ax, requestedFrequency_kHz, requestedCp, '-', ...
            'LineWidth', 1.8, 'LineStyle', '-.', 'DisplayName', 'Evaluated solver curve');
    end
end

if isfield(normalizedFit, 'qc') && isfield(normalizedFit.qc, 'baseline') && ...
        isfield(normalizedFit.qc.baseline, 'Cp0_mps') && isfinite(normalizedFit.qc.baseline.Cp0_mps)
    baselineFrequency = frequency_kHz(valid);
    baselineCp = normalizedFit.qc.baseline.Cp0_mps * ones(size(baselineFrequency));
    if ~isempty(baselineFrequency)
        legendHandles(end+1) = plot(ax, baselineFrequency, baselineCp, '--', ...
            'LineWidth', 1.0, 'DisplayName', 'Constant baseline');
    end
end

xlabel(ax, 'Frequency [kHz]');
ylabel(ax, 'Phase speed [m/s]');
if isfield(normalizedFit, 'qc')
    firstTitleLine = sprintf('%s - %s fit', ...
        char(guiFitDisplayLabel("model", normalizedFit.modelName)), ...
        char(guiFitDisplayLabel("branch", normalizedFit.branchName)));

    secondTitleLine = sprintf('Physical quality check: %s', ...
        char(guiFitDisplayLabel( ...
            "quality", string(normalizedFit.qc.classification))));

    title(ax, {firstTitleLine; secondTitleLine}, ...
        'Interpreter', 'none');
else
    title(ax, sprintf('%s - %s fit', char(guiFitDisplayLabel("model", normalizedFit.modelName)), ...
        char(guiFitDisplayLabel("branch", normalizedFit.branchName))), 'Interpreter', 'none');
end
if ~isempty(legendHandles)
    legend(ax, legendHandles, 'Location', 'best', 'Interpreter', 'none');
end
applyPhysicalYLimits(ax, CpExp(experimentalValid), CpFit(fittedValid), normalizedFit);
hold(ax, 'off');
end

function applyPhysicalYLimits(ax, CpExp_mps, CpFit_mps, normalizedFit)
CpAll = [CpExp_mps(:); CpFit_mps(:)];
if nargin >= 4 && isfield(normalizedFit, 'fullCurve') && isfield(normalizedFit.fullCurve, 'Cp_mps')
    CpAll = [CpAll; normalizedFit.fullCurve.Cp_mps(:)];
end
if nargin >= 4 && isfield(normalizedFit, 'requestedCurve') && isfield(normalizedFit.requestedCurve, 'Cp_mps')
    CpAll = [CpAll; normalizedFit.requestedCurve.Cp_mps(:)];
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
