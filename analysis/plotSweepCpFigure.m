function fig = plotSweepCpFigure(plotData, varargin)
%PLOTSWEEPCPFIGURE Render normalized parameter-sweep Cp curves.
%
% plotData must contain:
%   curves(i).frequency_Hz, curves(i).Cp_mps, curves(i).valid,
%   curves(i).legendLabel, titleText, fixedParameterLines.

p = inputParser;
addParameter(p, 'Title', "", @(x)ischar(x) || isstring(x) || iscellstr(x));
addParameter(p, 'FigureName', "Parameter sweep Cp", @(x)ischar(x) || isstring(x));
addParameter(p, 'NewFigure', true, @(x)islogical(x) || isnumeric(x));
addParameter(p, 'FrequencyScale', 1e3, @(x)isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'FrequencyUnit', "kHz", @(x)ischar(x) || isstring(x));
addParameter(p, 'StartFrequencyAtZero', true, @(x)islogical(x) || isnumeric(x));
addParameter(p, 'StartCpAtZero', true, @(x)islogical(x) || isnumeric(x));
addParameter(p, 'LegendLocation', "northwest", @(x)ischar(x) || isstring(x));
addParameter(p, 'FixedParameterLocation', "northeast", @(x)ischar(x) || isstring(x));
addParameter(p, 'ShowFixedParameters', true, @(x)islogical(x) || isnumeric(x));
addParameter(p, 'ShowInvalidPoints', false, @(x)islogical(x) || isnumeric(x));
addParameter(p, 'ShowLastValidPoint', false, @(x)islogical(x) || isnumeric(x));
addParameter(p, 'LastValidPointMarkerSize', 7, @(x)isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'LineWidth', 1.8, @(x)isnumeric(x) && isscalar(x) && x > 0);
parse(p, varargin{:});

validatePlotData(plotData);

if logical(p.Results.NewFigure)
    fig = figure('Name', char(string(p.Results.FigureName)), 'Color', 'w');
else
    fig = gcf;
    clf(fig);
    fig.Color = 'w';
end

[ax, infoAx] = createSweepLayout(fig);
hold(ax, 'on');
grid(ax, 'on');

legendHandles = gobjects(0);
legendLabels = strings(0);
for i = 1:numel(plotData.curves)
    curve = plotData.curves(i);
    frequency = curve.frequency_Hz(:) ./ p.Results.FrequencyScale;
    Cp = curve.Cp_mps(:);
    valid = logical(curve.valid(:)) & isfinite(frequency) & isfinite(Cp);

    x = frequency;
    y = Cp;
    x(~valid) = nan;
    y(~valid) = nan;

    h = plot(ax, x, y, '-', 'LineWidth', p.Results.LineWidth);
    if any(valid)
        legendHandles(end+1) = h; %#ok<AGROW>
        legendLabels(end+1) = string(curve.legendLabel); %#ok<AGROW>
    else
        h.HandleVisibility = 'off';
    end

    if logical(p.Results.ShowInvalidPoints)
        invalid = ~valid & isfinite(frequency) & isfinite(Cp);
        if any(invalid)
            plot(ax, frequency(invalid), Cp(invalid), '.', ...
                'Color', h.Color, 'HandleVisibility', 'off');
        end
    end

    if logical(p.Results.ShowLastValidPoint) && any(valid)
        lastValid = find(valid, 1, 'last');
        plot(ax, frequency(lastValid), Cp(lastValid), 'o', ...
            'MarkerSize', p.Results.LastValidPointMarkerSize, ...
            'LineWidth', 1.4, ...
            'Color', h.Color, 'MarkerFaceColor', h.Color, ...
            'HandleVisibility', 'off');
    end
end

xlabel(ax, "Frequency [" + string(p.Results.FrequencyUnit) + "]");
ylabel(ax, 'Phase velocity Cp [m/s]');
applyAxisLimits(ax, logical(p.Results.StartFrequencyAtZero), logical(p.Results.StartCpAtZero));

requestedTitle = string(p.Results.Title);
if any(strlength(requestedTitle(:)) > 0)
    title(ax, makeSingleLineTitle(requestedTitle), 'Interpreter', 'none');
else
    title(ax, makeSingleLineTitle(string(plotData.titleText)), 'Interpreter', 'none');
end

if ~isempty(legendHandles)
    drawInfoPanel(infoAx, plotData.fixedParameterLines, legendHandles, legendLabels, ...
        logical(p.Results.ShowFixedParameters));
elseif logical(p.Results.ShowFixedParameters) && ...
        isfield(plotData, 'fixedParameterLines') && ...
        ~isempty(plotData.fixedParameterLines)
    drawInfoPanel(infoAx, plotData.fixedParameterLines, legendHandles, legendLabels, true);
end

hold(ax, 'off');
end

function [ax, infoAx] = createSweepLayout(fig)
layout = tiledlayout(fig, 1, 4, ...
    'TileSpacing', 'compact', ...
    'Padding', 'compact');
ax = nexttile(layout, 1, [1 3]);
infoAx = nexttile(layout, 4);
set(infoAx, 'Visible', 'off', 'XLim', [0 1], 'YLim', [0 1], ...
    'Color', 'w', 'Tag', 'SweepInfoPanel');
hold(infoAx, 'on');
end

function titleText = makeSingleLineTitle(titleText)
titleText = strjoin(strtrim(string(titleText(:))).', " ");
end

function validatePlotData(plotData)
if ~isstruct(plotData) || ~isfield(plotData, 'curves') || isempty(plotData.curves)
    error('plotSweepCpFigure:InvalidPlotData', ...
        'Expected normalized sweep plot data with at least one curve.');
end
required = {'frequency_Hz', 'Cp_mps', 'valid', 'legendLabel'};
for i = 1:numel(plotData.curves)
    for j = 1:numel(required)
        if ~isfield(plotData.curves(i), required{j})
            error('plotSweepCpFigure:MissingCurveField', ...
                'Curve %d is missing field %s.', i, required{j});
        end
    end
    n = numel(plotData.curves(i).frequency_Hz);
    if numel(plotData.curves(i).Cp_mps) ~= n || numel(plotData.curves(i).valid) ~= n
        error('plotSweepCpFigure:InconsistentCurveLength', ...
            'Curve %d has inconsistent frequency, Cp, and validity lengths.', i);
    end
end
end

function applyAxisLimits(ax, startFrequencyAtZero, startCpAtZero)
setSweepPlotLimits(ax, 'CpAxis', 'y');
if startFrequencyAtZero
    xl = xlim(ax);
    xlim(ax, [0 max(xl(2), eps)]);
end
if startCpAtZero
    yl = ylim(ax);
    ylim(ax, [0 max(yl(2), eps)]);
end
end

function drawInfoPanel(infoAx, fixedLines, legendHandles, legendLabels, showFixedParameters)
cla(infoAx);
set(infoAx, 'Visible', 'off', 'XLim', [0 1], 'YLim', [0 1], ...
    'Color', 'w', 'Tag', 'SweepInfoPanel');
hold(infoAx, 'on');

y = 0.96;
lineStep = 0.075;

text(infoAx, 0.02, y, "Fixed parameters", ...
    'Units', 'normalized', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'top', ...
    'Interpreter', 'none', ...
    'FontWeight', 'bold', ...
    'FontSize', 9);
y = y - lineStep;

if showFixedParameters && ~isempty(fixedLines)
    fixedLines = string(fixedLines(:));
    for i = 1:numel(fixedLines)
        text(infoAx, 0.02, y, fixedLines(i), ...
            'Units', 'normalized', ...
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'top', ...
            'Interpreter', 'none', ...
            'FontSize', 8.5);
        y = y - lineStep;
    end
else
    text(infoAx, 0.02, y, "None", ...
        'Units', 'normalized', ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'top', ...
        'Interpreter', 'none', ...
        'FontSize', 8.5);
    y = y - lineStep;
end

y = max(y - 0.03, 0.50);
plot(infoAx, [0.02 0.98], [y y], '-', ...
    'Color', [0.80 0.80 0.80], 'LineWidth', 0.75, ...
    'HandleVisibility', 'off');
y = y - 0.04;

text(infoAx, 0.02, y, "Sweep values", ...
    'Units', 'normalized', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'top', ...
    'Interpreter', 'none', ...
    'FontWeight', 'bold', ...
    'FontSize', 9);
y = y - lineStep;

for i = 1:numel(legendLabels)
    if y < 0.03
        break;
    end
    color = legendHandles(i).Color;
    plot(infoAx, [0.03 0.18], [y-0.01 y-0.01], '-', ...
        'Color', color, ...
        'LineWidth', legendHandles(i).LineWidth, ...
        'HandleVisibility', 'off');
    text(infoAx, 0.22, y, string(legendLabels(i)), ...
        'Units', 'normalized', ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'top', ...
        'Interpreter', 'none', ...
        'FontSize', 8.5);
    y = y - lineStep;
end
end
