function fig = renderSweepCpInsetFigure(plotData, options)
%RENDERSWEEPCPINSETFIGURE Render sweep curves with a compact inset panel.

if logical(options.NewFigure)
    fig = figure('Name', char(string(options.FigureName)), 'Color', 'w');
else
    fig = gcf;
    clf(fig);
    fig.Color = 'w';
end

ax = axes(fig, 'Units', 'normalized', 'Position', [0.08 0.10 0.88 0.82]);
hold(ax, 'on');
grid(ax, 'on');

legendHandles = gobjects(0);
legendLabels = strings(0);
for i = 1:numel(plotData.curves)
    curve = plotData.curves(i);
    frequency = curve.frequency_Hz(:) ./ options.FrequencyScale;
    Cp = curve.Cp_mps(:);
    valid = logical(curve.valid(:)) & isfinite(frequency) & isfinite(Cp);

    x = frequency;
    y = Cp;
    x(~valid) = nan;
    y(~valid) = nan;

    h = plot(ax, x, y, '-', 'LineWidth', options.LineWidth);
    if any(valid)
        legendHandles(end+1) = h; %#ok<AGROW>
        legendLabels(end+1) = string(curve.legendLabel); %#ok<AGROW>
    else
        h.HandleVisibility = 'off';
    end

    if logical(options.ShowInvalidPoints)
        invalid = ~valid & isfinite(frequency) & isfinite(Cp);
        if any(invalid)
            plot(ax, frequency(invalid), Cp(invalid), '.', ...
                'Color', h.Color, 'HandleVisibility', 'off');
        end
    end

    if logical(options.ShowLastValidPoint) && any(valid)
        lastValid = find(valid, 1, 'last');
        plot(ax, frequency(lastValid), Cp(lastValid), 'o', ...
            'MarkerSize', options.LastValidPointMarkerSize, ...
            'LineWidth', 1.4, 'Color', h.Color, ...
            'MarkerFaceColor', h.Color, 'HandleVisibility', 'off');
    end
end

xlabel(ax, "Frequency [" + string(options.FrequencyUnit) + "]");
ylabel(ax, 'Phase velocity Cp [m/s]');
setSweepPlotLimits(ax, 'CpAxis', 'y');
if logical(options.StartFrequencyAtZero)
    xl = xlim(ax);
    xlim(ax, [0 max(xl(2), eps)]);
end
if logical(options.StartCpAtZero)
    yl = ylim(ax);
    ylim(ax, [0 max(yl(2), eps)]);
end

requestedTitle = string(options.Title);
if any(strlength(requestedTitle(:)) > 0)
    title(ax, singleLine(requestedTitle), 'Interpreter', 'none');
else
    title(ax, singleLine(string(plotData.titleText)), 'Interpreter', 'none');
end

fixedLines = strings(0, 1);
if logical(options.ShowFixedParameters) && isfield(plotData, 'fixedParameterLines')
    fixedLines = string(plotData.fixedParameterLines(:));
end
if ~isempty(legendHandles) || ~isempty(fixedLines)
    infoAx = createInsetPanel(fig, ax, numel(fixedLines), numel(legendLabels), ...
        string(options.InfoPanelLocation));
    drawPanel(infoAx, fixedLines, legendHandles, legendLabels);
end

hold(ax, 'off');
end

function infoAx = createInsetPanel(fig, ax, nFixed, nLegend, location)
axPos = ax.Position;
rowCount = 2 + nFixed + nLegend;
panelWidth = 0.30 * axPos(3);
panelHeight = min(0.72 * axPos(4), ...
    max(0.30 * axPos(4), (0.065 * rowCount + 0.08) * axPos(4)));
marginX = 0.015 * axPos(3);
marginY = 0.020 * axPos(4);

if lower(location) == "southwest"
    x = axPos(1) + marginX;
else
    x = axPos(1) + axPos(3) - panelWidth - marginX;
end
y = axPos(2) + marginY;

infoAx = axes(fig, 'Units', 'normalized', ...
    'Position', [x y panelWidth panelHeight], ...
    'XLim', [0 1], 'YLim', [0 1], 'Color', 'w', ...
    'Box', 'on', 'XTick', [], 'YTick', [], 'Tag', 'SweepInfoPanel');
infoAx.Layer = 'top';
hold(infoAx, 'on');
end

function drawPanel(infoAx, fixedLines, legendHandles, legendLabels)
cla(infoAx);
set(infoAx, 'XLim', [0 1], 'YLim', [0 1], 'Color', 'w', ...
    'Box', 'on', 'XTick', [], 'YTick', [], 'Tag', 'SweepInfoPanel');
hold(infoAx, 'on');

nRows = 2 + numel(fixedLines) + numel(legendLabels);
lineStep = min(0.12, 0.84 / max(nRows, 1));
y = 0.95;

addText(infoAx, 0.05, y, "Fixed parameters", 9, 'bold');
y = y - lineStep;
if isempty(fixedLines)
    addText(infoAx, 0.05, y, "None", 8.5, 'normal');
    y = y - lineStep;
else
    for i = 1:numel(fixedLines)
        addText(infoAx, 0.05, y, fixedLines(i), 8.5, 'normal');
        y = y - lineStep;
    end
end

separatorY = y - 0.20 * lineStep;
plot(infoAx, [0.05 0.95], [separatorY separatorY], '-', ...
    'Color', [0.80 0.80 0.80], 'LineWidth', 0.75, ...
    'HandleVisibility', 'off');
y = separatorY - 0.55 * lineStep;
addText(infoAx, 0.05, y, "Sweep values", 9, 'bold');
y = y - lineStep;

for i = 1:numel(legendLabels)
    color = legendHandles(i).Color;
    plot(infoAx, [0.07 0.22], [y-0.01 y-0.01], '-', ...
        'Color', color, 'LineWidth', legendHandles(i).LineWidth, ...
        'HandleVisibility', 'off');
    addText(infoAx, 0.27, y, legendLabels(i), 8.5, 'normal');
    y = y - lineStep;
end
end

function addText(ax, x, y, value, fontSize, fontWeight)
text(ax, x, y, string(value), 'Units', 'normalized', ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', ...
    'Interpreter', 'none', 'FontSize', fontSize, ...
    'FontWeight', fontWeight);
end

function value = singleLine(value)
value = strjoin(strtrim(string(value(:))).', " ");
end