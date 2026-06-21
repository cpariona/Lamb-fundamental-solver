function fig = aePlotGridSweepFrequencySurfaceInteractive(sweepResult, sliderAxisName, yAxisName, varargin)
%AEPLOTGRIDSWEEPFREQUENCYSURFACEINTERACTIVE Surface Cp(f,y) with slider over one axis.

p = inputParser();
addParameter(p, 'TitlePrefix', '', @(x)ischar(x) || isstring(x));
parse(p, varargin{:});

sliderAxisName = char(sliderAxisName);
yAxisName = char(yAxisName);
cube = aeBuildGridSweepCpCube(sweepResult, sliderAxisName, yAxisName);

fig = figure('Name', 'AE IOP/HGO interactive Cp frequency surface', 'Color', 'w', ...
    'Units', 'normalized', 'Position', [0.12 0.12 0.74 0.72]);
ax = axes('Parent', fig, 'Position', [0.10 0.22 0.72 0.68]);
labelText = uicontrol(fig, 'Style', 'text', 'Units', 'normalized', ...
    'Position', [0.10 0.08 0.72 0.04], 'BackgroundColor', 'w', ...
    'HorizontalAlignment', 'center', 'FontWeight', 'bold');
slider = uicontrol(fig, 'Style', 'slider', 'Units', 'normalized', ...
    'Position', [0.10 0.04 0.72 0.035], 'Min', 1, 'Max', numel(cube.xValues), ...
    'Value', 1, 'SliderStep', sliderStep(numel(cube.xValues)));

slider.Callback = @(src, ~)updatePlot(round(src.Value));
updatePlot(1);

    function updatePlot(index)
        index = max(1, min(numel(cube.xValues), index));
        slider.Value = index;
        cla(ax);
        Z = squeeze(cube.Cp(:, index, :));
        [F, Y] = meshgrid(cube.frequency_kHz, cube.yValues);
        surf(ax, F, Y, Z, 'EdgeColor', 'none');
        hold(ax, 'on');
        plot3(ax, F(:), Y(:), Z(:), 'k.', 'MarkerSize', 8);
        hold(ax, 'off');
        xlabel(ax, 'Frequency [kHz]');
        ylabel(ax, cube.yLabel);
        zlabel(ax, 'Phase velocity Cp [m/s]');
        grid(ax, 'on');
        view(ax, 45, 28);
        colorbar(ax);
        sliderValueText = string(cube.xAxisName) + " = " + string(sprintf('%.3g', cube.xValues(index)));
        labelText.String = char(sliderValueText);
        if strlength(string(p.Results.TitlePrefix)) > 0
            title(ax, string(p.Results.TitlePrefix) + " | " + sliderValueText);
        else
            title(ax, "Cp(f," + string(cube.yAxisName) + ") | " + sliderValueText);
        end
    end
end

function step = sliderStep(n)
if n <= 1
    step = [1 1];
else
    step = [1/(n-1), min(1, 2/(n-1))];
end
end
