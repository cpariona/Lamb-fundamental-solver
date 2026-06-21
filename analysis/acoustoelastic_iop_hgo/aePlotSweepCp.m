function fig = aePlotSweepCp(sweepResult, varargin)
%AEPLOTSWEEPCP Plot Cp(f) curves from an AE IOP/HGO sweep result.

p = inputParser();
addParameter(p, 'Title', '', @(x)ischar(x) || isstring(x));
addParameter(p, 'ShowInvalidPoints', false, @(x)islogical(x) || isnumeric(x));
parse(p, varargin{:});

fig = figure('Name', 'AE IOP/HGO sweep Cp', 'Color', 'w');
ax = axes(fig);
hold(ax, 'on');

for i = 1:numel(sweepResult.conditions)
    condition = sweepResult.conditions(i);
    result = condition.result;
    frequency_kHz = result.frequency(:) / 1e3;
    Cp = result.Cp(:);
    valid = result.validCp(:) & isfinite(frequency_kHz) & isfinite(Cp);

    if any(valid)
        plot(ax, frequency_kHz(valid), Cp(valid), '-', 'LineWidth', 1.8, ...
            'DisplayName', char(condition.sweepValueDisplay));
    end

    if p.Results.ShowInvalidPoints
        invalid = ~valid & isfinite(frequency_kHz) & isfinite(Cp);
        if any(invalid)
            plot(ax, frequency_kHz(invalid), Cp(invalid), '.', 'HandleVisibility', 'off');
        end
    end
end

xlabel(ax, 'Frequency [kHz]');
ylabel(ax, 'Phase velocity Cp [m/s]');
grid(ax, 'on');
legend(ax, 'Location', 'best');

if strlength(string(p.Results.Title)) > 0
    title(ax, string(p.Results.Title));
else
    title(ax, sweepResult.label + " sweep");
end

hold(ax, 'off');
end
