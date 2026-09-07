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
addParameter(p, 'ShowFixedParameters', true, @(x)islogical(x) || isnumeric(x));
addParameter(p, 'ShowInvalidPoints', false, @(x)islogical(x) || isnumeric(x));
addParameter(p, 'ShowLastValidPoint', false, @(x)islogical(x) || isnumeric(x));
addParameter(p, 'LastValidPointMarkerSize', 7, @(x)isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'LineWidth', 1.8, @(x)isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'LegendLocation', "southeast", @(x)ischar(x) || isstring(x));
parse(p, varargin{:});

validatePlotData(plotData);

if logical(p.Results.NewFigure)
    fig = figure('Name', char(string(p.Results.FigureName)), 'Color', 'w');
else
    fig = gcf;
    clf(fig);
    fig.Color = 'w';
end

ax = axes(fig);
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
            'LineWidth', 1.4, 'Color', h.Color, ...
            'MarkerFaceColor', h.Color, 'HandleVisibility', 'off');
    end
end

xlabel(ax, "Frequency [" + string(p.Results.FrequencyUnit) + "]");
ylabel(ax, 'Phase velocity Cp [m/s]');
applyAxisLimits(ax, logical(p.Results.StartFrequencyAtZero), logical(p.Results.StartCpAtZero));

requestedTitle = string(p.Results.Title);
if any(strlength(requestedTitle(:)) > 0)
    title(ax, makeSingleLine(requestedTitle), 'Interpreter', 'none');
else
    title(ax, makeSingleLine(string(plotData.titleText)), 'Interpreter', 'none');
end

if logical(p.Results.ShowFixedParameters) && ...
        isfield(plotData, 'fixedParameterLines') && ...
        ~isempty(plotData.fixedParameterLines)
    fixedText = "Fixed: " + strjoin(string(plotData.fixedParameterLines(:)).', ", ");
    subtitle(ax, fixedText, 'Interpreter', 'none', 'FontWeight', 'normal');
end

if ~isempty(legendHandles)
    legend(ax, legendHandles, cellstr(legendLabels), ...
        'Location', char(string(p.Results.LegendLocation)), ...
        'Interpreter', 'none');
end

hold(ax, 'off');
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

function value = makeSingleLine(value)
value = strjoin(strtrim(string(value(:))).', " ");
end