function sweepResult = aeRunGridSweep(baseParams, sweepAxes, options, sweepConfig)
%AERUNGRIDSWEEP Run a reusable multi-parameter AE IOP/HGO grid sweep.
%
% sweepAxes is a struct array with fields:
%   Field, Values, Name, Label, Unit, ValueScale, ValueFormatter

if nargin < 3 || isempty(options)
    options = aeDefaultSweepOptions();
end
if nargin < 4 || isempty(sweepConfig)
    sweepConfig = struct();
end

sweepAxes = normalizeAxes(sweepAxes);
axisValues = {sweepAxes.Values};
[gridArrays{1:numel(axisValues)}] = ndgrid(axisValues{:});
numConditions = numel(gridArrays{1});

conditions = repmat(struct( ...
    'index', [], ...
    'params', [], ...
    'result', [], ...
    'quality', [], ...
    'diagnostics', [], ...
    'axisValues', [], ...
    'axisValueDisplays', []), 1, numConditions);
summaryRows = [];

for idx = 1:numConditions
    params = baseParams;
    axisValuesStruct = struct();
    axisDisplayStruct = struct();

    for a = 1:numel(sweepAxes)
        value = gridArrays{a}(idx);
        axisName = char(sweepAxes(a).Name);
        params = setNestedField(params, sweepAxes(a).Field, value);
        axisValuesStruct.(axisName) = value;
        axisDisplayStruct.(axisName) = formatAxisValue(value, sweepAxes(a));
    end

    result = solveAcoustoelasticIOPHGOBranch(params, options);

    conditions(idx).index = idx;
    conditions(idx).params = params;
    conditions(idx).result = result;
    conditions(idx).quality = result.quality;
    conditions(idx).diagnostics = result.diagnostics;
    conditions(idx).axisValues = axisValuesStruct;
    conditions(idx).axisValueDisplays = axisDisplayStruct;

    row = makeSummaryRow(idx, sweepAxes, axisValuesStruct, axisDisplayStruct, result);
    summaryRows = [summaryRows; row]; %#ok<AGROW>

    fprintf('Grid sweep condition %d/%d complete: %s\n', idx, numConditions, joinDisplayValues(axisDisplayStruct));
end

sweepResult = struct();
sweepResult.name = getStructField(sweepConfig, 'Name', "grid_sweep");
sweepResult.label = getStructField(sweepConfig, 'Label', "Grid sweep");
sweepResult.axes = sweepAxes;
sweepResult.options = options;
sweepResult.baseParams = baseParams;
sweepResult.conditions = conditions;
sweepResult.gridSize = cellfun(@numel, axisValues);

if isempty(summaryRows)
    sweepResult.summaryTable = table();
else
    sweepResult.summaryTable = struct2table(summaryRows);
end
end

function axesOut = normalizeAxes(axesIn)
axesOut = axesIn(:).';
for i = 1:numel(axesOut)
    if ~isfield(axesOut(i), 'Field') || isempty(axesOut(i).Field)
        error('Each sweep axis requires a Field.');
    end
    if ~isfield(axesOut(i), 'Values') || isempty(axesOut(i).Values)
        error('Each sweep axis requires Values.');
    end
    axesOut(i).Field = string(axesOut(i).Field);
    axesOut(i).Values = axesOut(i).Values(:).';
    if ~isfield(axesOut(i), 'Name') || isempty(axesOut(i).Name)
        axesOut(i).Name = matlab.lang.makeValidName(char(axesOut(i).Field));
    end
    axesOut(i).Name = string(matlab.lang.makeValidName(char(axesOut(i).Name)));
    if ~isfield(axesOut(i), 'Label') || isempty(axesOut(i).Label)
        axesOut(i).Label = string(axesOut(i).Name);
    end
    if ~isfield(axesOut(i), 'Unit') || isempty(axesOut(i).Unit)
        axesOut(i).Unit = "";
    end
    if ~isfield(axesOut(i), 'ValueScale') || isempty(axesOut(i).ValueScale)
        axesOut(i).ValueScale = 1;
    end
    if ~isfield(axesOut(i), 'ValueFormatter') || isempty(axesOut(i).ValueFormatter)
        axesOut(i).ValueFormatter = "%.6g";
    end
end
end

function params = setNestedField(params, fieldPath, value)
parts = split(string(fieldPath), '.');
parts = cellstr(parts);
params = setNestedFieldRecursive(params, parts, value);
end

function s = setNestedFieldRecursive(s, parts, value)
fieldName = parts{1};
if numel(parts) == 1
    s.(fieldName) = value;
    return;
end
if ~isfield(s, fieldName) || isempty(s.(fieldName))
    s.(fieldName) = struct();
end
s.(fieldName) = setNestedFieldRecursive(s.(fieldName), parts(2:end), value);
end

function text = formatAxisValue(value, axisSpec)
scaledValue = value ./ axisSpec.ValueScale;
text = string(sprintf(axisSpec.ValueFormatter, scaledValue));
if strlength(string(axisSpec.Unit)) > 0
    text = text + " " + string(axisSpec.Unit);
end
end

function row = makeSummaryRow(index, axesSpec, axisValues, axisDisplays, result)
quality = result.quality;
row = struct();
row.ConditionIndex = index;
for a = 1:numel(axesSpec)
    name = char(axesSpec(a).Name);
    row.(name) = axisValues.(name);
    row.([name 'Scaled']) = axisValues.(name) ./ axesSpec(a).ValueScale;
    row.([name 'Display']) = axisDisplays.(name);
end
row.PolicyName = getStructField(quality, 'policyName', string(missing));
row.ValidFraction = getStructField(quality, 'validFraction', nan);
row.ValidPoints = getStructField(quality, 'validCount', nan);
row.MissingPoints = getStructField(quality, 'missingCount', nan);
row.TotalPoints = getStructField(quality, 'pointCount', nan);
row.FirstValidFrequency_kHz = getStructField(quality, 'firstValidFrequency_kHz', nan);
row.LastValidFrequency_kHz = getStructField(quality, 'lastValidFrequency_kHz', nan);
row.A0StartFilterPassed = getStructField(quality, 'a0StartFilterPassed', false);
row.SelectionFallbackUsed = getStructField(quality, 'selectionFallbackUsed', false);
row.YStart = getStructField(quality, 'yStart', nan);
row.StartRank = getStructField(quality, 'startRank', nan);
row.CpStart_mps = getStructField(quality, 'cpStart_mps', nan);
row.MaxBranchRelativeCpDrop = getStructField(quality, 'maxBranchRelativeCpDrop', nan);
end

function text = joinDisplayValues(axisDisplayStruct)
names = fieldnames(axisDisplayStruct);
parts = strings(1, numel(names));
for i = 1:numel(names)
    parts(i) = string(names{i}) + "=" + string(axisDisplayStruct.(names{i}));
end
text = strjoin(parts, ', ');
end

function value = getStructField(s, fieldName, defaultValue)
if isstruct(s) && isfield(s, fieldName)
    value = s.(fieldName);
else
    value = defaultValue;
end
end
