function fig = aePlotGridSensitivity(sweepResult, varargin)
%AEPLOTGRIDSENSITIVITY Plot Cp(f) curves from a multi-parameter AE grid sensitivity study.

p = inputParser();
addParameter(p, 'Title', '', @(x)ischar(x) || isstring(x));
parse(p, varargin{:});

fig = figure('Name', 'AE IOP/HGO grid sensitivity Cp', 'Color', 'w');
ax = axes(fig);
hold(ax, 'on');

for i = 1:numel(sweepResult.conditions)
    condition = sweepResult.conditions(i);
    result = condition.result;
    frequency_kHz = result.frequency_Hz(:) / 1e3;
    Cp = result.phaseVelocity_mps(:);
    valid = result.validMask(:) & isfinite(frequency_kHz) & isfinite(Cp);
    if ~any(valid)
        continue;
    end
    plot(ax, frequency_kHz(valid), Cp(valid), '-', 'LineWidth', 1.5, ...
        'DisplayName', char(makeConditionLabel(condition)));
end

xlabel(ax, 'Frequency [kHz]');
ylabel(ax, 'Phase velocity Cp [m/s]');
grid(ax, 'on');
setSweepPlotLimits(ax, 'CpAxis', 'y');
legend(ax, 'Location', 'bestoutside');

if strlength(string(p.Results.Title)) > 0
    title(ax, string(p.Results.Title));
else
    title(ax, sweepResult.label + " Cp grid sensitivity");
end

hold(ax, 'off');
end

function label = makeConditionLabel(condition)
names = fieldnames(condition.axisValueDisplays);
parts = strings(1, numel(names));
for i = 1:numel(names)
    parts(i) = string(names{i}) + "=" + string(condition.axisValueDisplays.(names{i}));
end
label = strjoin(parts, ', ');
end
