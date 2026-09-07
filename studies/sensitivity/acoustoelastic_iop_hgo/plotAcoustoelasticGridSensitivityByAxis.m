function figs = plotAcoustoelasticGridSensitivityByAxis(sweepResult, groupAxisName, curveAxisName, varargin)
%AEPLOTGRIDSWEEPCPBYAXIS Plot one Cp figure per value of a grid-sweep axis.

p = inputParser();
addParameter(p, 'TitlePrefix', '', @(x)ischar(x) || isstring(x));
addParameter(p, 'CpLimits', [], @(x)isnumeric(x) && (isempty(x) || numel(x) == 2));
addParameter(p, 'PaddingFraction', 0.05, @(x)isnumeric(x) && isscalar(x) && x >= 0);
parse(p, varargin{:});

groupAxisName = char(groupAxisName);
curveAxisName = char(curveAxisName);
cpLimits = p.Results.CpLimits;
if isempty(cpLimits)
    cpLimits = computeGlobalCpLimits(sweepResult, p.Results.PaddingFraction);
end

groupValues = collectAxisValues(sweepResult, groupAxisName);
figs = gobjects(1, numel(groupValues));

for g = 1:numel(groupValues)
    groupValue = groupValues(g);
    groupDisplay = "";
    fig = figure('Name', ['AE IOP/HGO grid sweep ', groupAxisName], 'Color', 'w');
    ax = axes(fig);
    hold(ax, 'on');

    for i = 1:numel(sweepResult.conditions)
        condition = sweepResult.conditions(i);
        if ~isfield(condition.axisValues, groupAxisName)
            error('Group axis "%s" was not found in condition axisValues.', groupAxisName);
        end
        if condition.axisValues.(groupAxisName) ~= groupValue
            continue;
        end

        groupDisplay = string(condition.axisValueDisplays.(groupAxisName));
        result = condition.result;
        frequency_kHz = result.frequency_Hz(:) / 1e3;
        Cp = result.phaseVelocity_mps(:);
        valid = result.validMask(:) & isfinite(frequency_kHz) & isfinite(Cp);
        if ~any(valid)
            continue;
        end

        plot(ax, frequency_kHz(valid), Cp(valid), '-', 'LineWidth', 1.8, ...
            'DisplayName', char(makeCurveLabel(condition, curveAxisName)));
    end

    xlabel(ax, 'Frequency [kHz]');
    ylabel(ax, 'Phase velocity Cp [m/s]');
    grid(ax, 'on');
    setSweepPlotLimits(ax, 'CpAxis', 'y', 'CpLimits', cpLimits, 'PaddingFraction', p.Results.PaddingFraction);
    legend(ax, 'Location', 'best');

    if strlength(string(p.Results.TitlePrefix)) > 0
        title(ax, string(p.Results.TitlePrefix) + " | " + string(groupAxisName) + " = " + groupDisplay);
    else
        title(ax, string(groupAxisName) + " = " + groupDisplay);
    end

    hold(ax, 'off');
    figs(g) = fig;
end
end

function limits = computeGlobalCpLimits(sweepResult, paddingFraction)
values = [];
for i = 1:numel(sweepResult.conditions)
    result = sweepResult.conditions(i).result;
    Cp = result.phaseVelocity_mps(:);
    valid = result.validMask(:) & isfinite(Cp);
    values = [values; Cp(valid)]; %#ok<AGROW>
end
if isempty(values)
    limits = [0 1];
    return;
end
upper = max(values(:));
if ~isfinite(upper) || upper <= 0
    upper = 1;
end
limits = [0 upper * (1 + paddingFraction)];
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

function label = makeCurveLabel(condition, curveAxisName)
if isfield(condition.axisValueDisplays, curveAxisName)
    label = string(curveAxisName) + " = " + string(condition.axisValueDisplays.(curveAxisName));
else
    label = "condition " + string(condition.index);
end
end
