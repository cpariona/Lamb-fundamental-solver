function fig = aePlotGridSweepCpHeatmapInteractive(sweepResult, xAxisName, yAxisName, varargin)
%AEPLOTGRIDSWEEPCPHEATMAPINTERACTIVE Heatmap Cp(x,y) with frequency slider.

p = inputParser();
addParameter(p, 'TitlePrefix', '', @(x)ischar(x) || isstring(x));
addParameter(p, 'ColorScale', 'fixed', @(x)ischar(x) || isstring(x));
parse(p, varargin{:});

cube = aeBuildGridSweepCpCube(sweepResult, xAxisName, yAxisName);
colorScale = string(p.Results.ColorScale);

fig = figure('Name', 'AE IOP/HGO interactive Cp heatmap', 'Color', 'w', ...
    'Units', 'normalized', 'Position', [0.14 0.14 0.70 0.68]);
ax = axes('Parent', fig, 'Position', [0.10 0.22 0.72 0.68]);
labelText = uicontrol(fig, 'Style', 'text', 'Units', 'normalized', ...
    'Position', [0.10 0.08 0.72 0.04], 'BackgroundColor', 'w', ...
    'HorizontalAlignment', 'center', 'FontWeight', 'bold');
slider = uicontrol(fig, 'Style', 'slider', 'Units', 'normalized', ...
    'Position', [0.10 0.04 0.72 0.035], 'Min', 1, 'Max', numel(cube.frequency_Hz), ...
    'Value', 1, 'SliderStep', sliderStep(numel(cube.frequency_Hz)));

finiteCp = cube.Cp(isfinite(cube.Cp));
if isempty(finiteCp)
    fixedLimits = [0 1];
else
    fixedLimits = [min(finiteCp), max(finiteCp)];
    if fixedLimits(1) == fixedLimits(2)
        fixedLimits = fixedLimits + [-0.5 0.5];
    end
end

slider.Callback = @(src, ~)updatePlot(round(src.Value));
updatePlot(1);

    function updatePlot(index)
        index = max(1, min(numel(cube.frequency_Hz), index));
        slider.Value = index;
        cla(ax);
        Z = squeeze(cube.Cp(:, :, index));
        imagesc(ax, cube.xValues, cube.yValues, Z);
        set(ax, 'YDir', 'normal');
        xlabel(ax, cube.xLabel);
        ylabel(ax, cube.yLabel);
        grid(ax, 'on');
        cb = colorbar(ax);
        cb.Label.String = 'Phase velocity Cp [m/s]';
        if colorScale == "fixed"
            caxis(ax, fixedLimits);
        end
        frequencyText = sprintf('f = %.3g kHz', cube.frequency_kHz(index));
        labelText.String = frequencyText;
        if strlength(string(p.Results.TitlePrefix)) > 0
            title(ax, string(p.Results.TitlePrefix) + " | " + string(frequencyText));
        else
            title(ax, "Cp(" + string(cube.xAxisName) + "," + string(cube.yAxisName) + ") | " + string(frequencyText));
        end
    end
end

function step = sliderStep(n)
if n <= 1
    step = [1 1];
else
    step = [1/(n-1), min(1, 10/(n-1))];
end
end
