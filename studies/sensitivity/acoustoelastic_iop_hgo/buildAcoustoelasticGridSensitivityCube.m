function cube = buildAcoustoelasticGridSensitivityCube(sweepResult, xAxisName, yAxisName)
%AEBUILDGRIDSWEEPCPCUBE Build Cp(y,x,f) cube from a two-axis AE grid sweep.

xAxisName = char(xAxisName);
yAxisName = char(yAxisName);

xRawValues = collectAxisValues(sweepResult, xAxisName);
yRawValues = collectAxisValues(sweepResult, yAxisName);
referenceFrequency = findReferenceFrequency(sweepResult);
Cp = nan(numel(yRawValues), numel(xRawValues), numel(referenceFrequency));
validMask = false(numel(yRawValues), numel(xRawValues), numel(referenceFrequency));

for i = 1:numel(sweepResult.conditions)
    condition = sweepResult.conditions(i);
    assertAxisPresent(condition, xAxisName);
    assertAxisPresent(condition, yAxisName);

    xRaw = condition.axisValues.(xAxisName);
    yRaw = condition.axisValues.(yAxisName);
    ix = find(xRawValues == xRaw, 1, 'first');
    iy = find(yRawValues == yRaw, 1, 'first');

    result = condition.result;
    f = result.frequency_Hz(:);
    c = result.phaseVelocity_mps(:);
    valid = result.validMask(:) & isfinite(f) & isfinite(c);
    if nnz(valid) >= 2
        Cp(iy, ix, :) = interp1(f(valid), c(valid), referenceFrequency, 'linear', nan);
    elseif nnz(valid) == 1
        singleIndex = find(abs(referenceFrequency - f(valid)) == min(abs(referenceFrequency - f(valid))), 1, 'first');
        Cp(iy, ix, singleIndex) = c(valid);
    end
    validMask(iy, ix, :) = isfinite(Cp(iy, ix, :));
end

cube = struct();
cube.frequency_Hz = referenceFrequency(:).';
cube.frequency_kHz = cube.frequency_Hz / 1e3;
cube.Cp = Cp;
cube.validMask = validMask;
cube.xAxisName = string(xAxisName);
cube.yAxisName = string(yAxisName);
cube.xRawValues = xRawValues;
cube.yRawValues = yRawValues;
cube.xScale = getAxisScale(sweepResult, xAxisName);
cube.yScale = getAxisScale(sweepResult, yAxisName);
cube.xValues = xRawValues ./ cube.xScale;
cube.yValues = yRawValues ./ cube.yScale;
cube.xLabel = makeAxisLabel(sweepResult, xAxisName);
cube.yLabel = makeAxisLabel(sweepResult, yAxisName);
end

function frequency = findReferenceFrequency(sweepResult)
frequency = [];
for i = 1:numel(sweepResult.conditions)
    condition = sweepResult.conditions(i);
    if isfield(condition, 'result') && isfield(condition.result, 'frequency_Hz') && ~isempty(condition.result.frequency_Hz)
        frequency = condition.result.frequency_Hz(:).';
        return;
    end
end
error('No valid reference frequency vector found in sweepResult.');
end

function values = collectAxisValues(sweepResult, axisName)
values = [];
for i = 1:numel(sweepResult.conditions)
    condition = sweepResult.conditions(i);
    assertAxisPresent(condition, axisName);
    values(end+1) = condition.axisValues.(axisName); %#ok<AGROW>
end
values = unique(values, 'stable');
end

function assertAxisPresent(condition, axisName)
if ~isfield(condition, 'axisValues') || ~isfield(condition.axisValues, axisName)
    error('Axis "%s" was not found in condition axisValues.', axisName);
end
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
