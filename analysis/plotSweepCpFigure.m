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
addParameter(p, 'InfoPanelLocation', "southeast", @(x)ischar(x) || isstring(x));
parse(p, varargin{:});

validatePlotData(plotData);
fig = renderSweepCpInsetFigure(plotData, p.Results);
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