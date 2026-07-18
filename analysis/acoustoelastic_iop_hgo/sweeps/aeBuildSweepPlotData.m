function plotData = aeBuildSweepPlotData(sweepResult)
%AEBUILDSWEEPPLOTDATA Normalize AE sweep results for shared plotting.

if ~isstruct(sweepResult) || ~isfield(sweepResult, 'conditions') || isempty(sweepResult.conditions)
    error('aeBuildSweepPlotData:InvalidSweepResult', ...
        'Expected aeRunSweep output with at least one condition.');
end

sweepField = string(sweepResult.sweepField);
shortLabel = compactLabel(sweepField);
curves = repmat(struct('frequency_Hz', [], 'Cp_mps', [], ...
    'valid', [], 'legendLabel', ""), 1, numel(sweepResult.conditions));

for i = 1:numel(sweepResult.conditions)
    condition = sweepResult.conditions(i);
    result = condition.result;
    curves(i).frequency_Hz = result.frequency(:);
    curves(i).Cp_mps = result.Cp(:);
    curves(i).valid = logical(result.validCp(:));
    curves(i).legendLabel = shortLabel + " = " + string(condition.sweepValueDisplay);
end

plotData = struct();
plotData.curves = curves;
plotData.titleText = "AE IOP/HGO A0-like sensitivity to " + lower(string(sweepResult.label));
plotData.fixedParameterLines = makeFixedParameterLines(sweepResult.baseParams, sweepField);
end

function lines = makeFixedParameterLines(params, sweptField)
lines = strings(0, 1);
lines = addIfFixed(lines, sweptField, "IOP", ...
    "IOP = " + formatValue(params, 'IOP', 133.322, '%.1f', 'mmHg'));
lines = addIfFixed(lines, sweptField, "mu", ...
    "mu = " + formatValue(params, 'mu', 1e3, '%.1f', 'kPa'));
lines = addIfFixed(lines, sweptField, "k1", ...
    "k1 = " + formatValue(params, 'k1', 1e3, '%.1f', 'kPa'));
lines = addIfFixed(lines, sweptField, "k2", ...
    "k2 = " + formatValue(params, 'k2', 1, '%.0f', ''));
lines = addIfFixed(lines, sweptField, "thickness", ...
    "h = " + formatValue(params, 'thickness', 1e-6, '%.0f', 'um'));
lines = addIfFixed(lines, sweptField, "R", ...
    "R = " + formatValue(params, 'R', 1e-3, '%.1f', 'mm'));
end

function label = compactLabel(fieldName)
switch string(fieldName)
    case "thickness"
        label = "h";
    otherwise
        label = string(fieldName);
end
end

function lines = addIfFixed(lines, sweptField, fieldName, textValue)
if sweptField ~= string(fieldName) && ~contains(textValue, "missing")
    lines(end+1, 1) = textValue; %#ok<AGROW>
end
end

function textValue = formatValue(params, fieldName, scale, formatSpec, unit)
if ~isfield(params, fieldName) || isempty(params.(fieldName))
    textValue = "missing";
    return;
end
value = params.(fieldName) ./ scale;
textValue = string(sprintf(formatSpec, value));
if strlength(string(unit)) > 0
    textValue = textValue + " " + string(unit);
end
end