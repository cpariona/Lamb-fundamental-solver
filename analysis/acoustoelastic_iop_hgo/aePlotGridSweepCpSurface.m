function fig = aePlotGridSweepCpSurface(sweepResult, xAxisName, yAxisName, targetFrequency_Hz, varargin)
%AEPLOTGRIDSWEEPCPSURFACE Plot Cp as a 3D surface over two sweep axes.

p = inputParser();
addParameter(p, 'Title', '', @(x)ischar(x) || isstring(x));
parse(p, varargin{:});

xAxisName = char(xAxisName);
yAxisName = char(yAxisName);

xScale = getAxisScale(sweepResult, xAxisName);
yScale = getAxisScale(sweepResult, yAxisName);
xRawValues = collectAxisValues(sweepResult, xAxisName);
yRawValues = collectAxisValues(sweepResult, yAxisName);
xPlotValues = xRawValues ./ xScale;
yPlotValues = yRawValues ./ yScale;
Z = nan(numel(yRawValues), numel(xRawValues));

for i = 1:numel(sweepResult.conditions)
    condition = sweepResult.conditions(i);
    xRaw = condition.axisValues.(xAxisName);
    yRaw = condition.axisValues.(yAxisName);
    ix = find(xRawValues == xRaw, 1, 'first');
    iy = find(yRawValues == yRaw, 1, 'first');
    Z(iy, ix) = interpolateCpAtFrequency(condition.result, targetFrequency_Hz);
end

[X, Y] = meshgrid(xPlotValues, yPlotValues);

fig = figure('Name', 'AE IOP/HGO grid sweep Cp surface', 'Color', 'w');
ax = axes(fig);
surf(ax, X, Y, Z, 'EdgeColor', 'none');
hold(ax, 'on');
plot3(ax, X(:), Y(:), Z(:), 'k.', 'MarkerSize', 12);
hold(ax, 'off');

xlabel(ax, makeAxisLabel(sweepResult, xAxisName));
ylabel(ax, makeAxisLabel(sweepResult, yAxisName));
zlabel(ax, 'Phase velocity Cp [m/s]');
setAxesOriginLimits(ax, 'IncludeZ', true);
grid(ax, 'on');
view(ax, 45, 28);
colorbar(ax);

if strlength(string(p.Results.Title)) > 0
    title(ax, string(p.Results.Title));
else
    title(ax, sprintf('Cp surface at %.3g kHz', targetFrequency_Hz/1e3));
end
end

function values = collectAxisValues(sweepResult, axisName)
values = [];
for i = 1:numel(sweepResult.conditions)
    condition = sweepResult.conditions(i);
    if ~isfield(condition.axisValues, axisName)
        error('Axis "%s" was not found in condition axisValues.', axisName);
    end
    values(end+1) = condition.axisValues.(axisName); %#ok<AGROW>
end
values = unique(values, 'stable');
end

function Cp = interpolateCpAtFrequency(result, targetFrequency_Hz)
frequency = result.frequency(:);
CpValues = result.Cp(:);
valid = result.validCp(:) & isfinite(frequency) & isfinite(CpValues);
if nnz(valid) < 2
    Cp = nan;
    return;
end
Cp = interp1(frequency(valid), CpValues(valid), targetFrequency_Hz, 'linear', nan);
end

function scale = getAxisScale(sweepResult, axisName)
scale = 1;
if ~isfield(sweepResult, 'axes')
    return;
end
for i = 1:numel(sweepResult.axes)
    axisSpec = sweepResult.axes(i);
    if string(axisSpec.Name) == string(axisName) && isfield(axisSpec, 'ValueScale') && ~isempty(axisSpec.ValueScale)
        scale = axisSpec.ValueScale;
        return;
    end
end
end

function label = makeAxisLabel(sweepResult, axisName)
label = string(axisName);
if ~isfield(sweepResult, 'axes')
    return;
end
for i = 1:numel(sweepResult.axes)
    axisSpec = sweepResult.axes(i);
    if string(axisSpec.Name) == string(axisName)
        label = string(axisSpec.Label);
        if isfield(axisSpec, 'Unit') && strlength(string(axisSpec.Unit)) > 0
            label = label + " [" + string(axisSpec.Unit) + "]";
        end
        return;
    end
end
end
