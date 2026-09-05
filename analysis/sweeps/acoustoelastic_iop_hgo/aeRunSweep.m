function sweepResult = aeRunSweep(baseParams, sweepField, sweepValues, options, sweepConfig)
%AERUNSWEEP Run a maintained acoustoelastic IOP/HGO parameter sweep.
%
%   sweepResult = aeRunSweep(baseParams, sweepField, sweepValues, options)
%   runs solveAcoustoelasticIOPHGOBranch once per value in sweepValues.

if nargin < 4 || isempty(options)
    options = defaultAcoustoelasticIOPHGOOptions();
end
if nargin < 5 || isempty(sweepConfig)
    sweepConfig = struct();
end

sweepField = string(sweepField);
sweepValues = sweepValues(:).';
sweepConfig = fillSweepConfigDefaults(sweepConfig, sweepField);

conditions = repmat(struct( ...
    'index', [], ...
    'sweepField', [], ...
    'sweepValue', [], ...
    'sweepValueDisplay', [], ...
    'params', [], ...
    'result', [], ...
    'quality', [], ...
    'diagnostics', []), 1, numel(sweepValues));

spec = struct( ...
    'parameter', sweepField, ...
    'parameterPath', "params." + sweepField, ...
    'values', sweepValues, ...
    'label', string(sweepConfig.Label), ...
    'units', string(sweepConfig.Unit), ...
    'displayScale', sweepConfig.ValueScale);
workflow = runParametricSweep(baseParams, options, spec, ...
    @(params, pointOptions)solveAcoustoelasticIOPHGOBranch(params, pointOptions));

summaryRows = [];
for i = 1:numel(sweepValues)
    params = workflow.params{i};
    result = workflow.results{i};

    conditions(i).index = i;
    conditions(i).sweepField = sweepField;
    conditions(i).sweepValue = sweepValues(i);
    conditions(i).sweepValueDisplay = formatSweepValue(sweepValues(i), sweepConfig);
    conditions(i).params = params;
    conditions(i).result = result;
    conditions(i).quality = result.quality;
    conditions(i).diagnostics = result.diagnostics;

    row = makeSummaryRow(i, sweepField, sweepValues(i), sweepConfig, result);
    summaryRows = [summaryRows; row]; %#ok<AGROW>
end

sweepResult = struct();
sweepResult.name = string(sweepConfig.Name);
sweepResult.label = string(sweepConfig.Label);
sweepResult.sweepField = sweepField;
sweepResult.sweepValues = sweepValues;
sweepResult.options = options;
sweepResult.baseParams = baseParams;
sweepResult.conditions = conditions;
sweepResult.elapsedSeconds = workflow.elapsedSeconds;
sweepResult.points = workflow.points;

if isempty(summaryRows)
    sweepResult.summaryTable = table();
else
    sweepResult.summaryTable = struct2table(summaryRows);
end
end

function sweepConfig = fillSweepConfigDefaults(sweepConfig, sweepField)
if ~isfield(sweepConfig, 'Name') || isempty(sweepConfig.Name)
    sweepConfig.Name = char(sweepField);
end
if ~isfield(sweepConfig, 'Label') || isempty(sweepConfig.Label)
    sweepConfig.Label = char(sweepField);
end
if ~isfield(sweepConfig, 'Unit') || isempty(sweepConfig.Unit)
    sweepConfig.Unit = '';
end
if ~isfield(sweepConfig, 'ValueScale') || isempty(sweepConfig.ValueScale)
    sweepConfig.ValueScale = 1;
end
if ~isfield(sweepConfig, 'ValueFormatter') || isempty(sweepConfig.ValueFormatter)
    sweepConfig.ValueFormatter = '%.6g';
end
end

function text = formatSweepValue(value, sweepConfig)
scaledValue = value ./ sweepConfig.ValueScale;
text = string(sprintf(sweepConfig.ValueFormatter, scaledValue));
if strlength(string(sweepConfig.Unit)) > 0
    text = text + " " + string(sweepConfig.Unit);
end
end

function row = makeSummaryRow(index, sweepField, sweepValue, sweepConfig, result)
quality = result.quality;
row = struct();
row.ConditionIndex = index;
row.SweepName = string(sweepConfig.Name);
row.SweepLabel = string(sweepConfig.Label);
row.SweepField = string(sweepField);
row.SweepValue = sweepValue;
row.SweepValueScaled = sweepValue ./ sweepConfig.ValueScale;
row.SweepUnit = string(sweepConfig.Unit);
row.SweepValueDisplay = formatSweepValue(sweepValue, sweepConfig);
row.PolicyName = getStructField(quality, 'policyName', missingString());
row.ValidFraction = getStructField(quality, 'validFraction', nan);
row.ValidPoints = getStructField(quality, 'validCount', nan);
row.MissingPoints = getStructField(quality, 'missingCount', nan);
row.TotalPoints = getStructField(quality, 'pointCount', nan);
row.FirstValidFrequency_kHz = getStructField(quality, 'firstValidFrequency_kHz', nan);
row.LastValidFrequency_kHz = getStructField(quality, 'lastValidFrequency_kHz', nan);
row.FirstMissingFrequency_kHz = getStructField(quality, 'firstMissingFrequency_kHz', nan);
row.A0StartFilterPassed = getStructField(quality, 'a0StartFilterPassed', false);
row.SelectionFallbackUsed = getStructField(quality, 'selectionFallbackUsed', false);
row.YStart = getStructField(quality, 'yStart', nan);
row.StartRank = getStructField(quality, 'startRank', nan);
row.CpStart_mps = getStructField(quality, 'cpStart_mps', nan);
row.MaxBranchRelativeCpDrop = getStructField(quality, 'maxBranchRelativeCpDrop', nan);
end

function value = getStructField(s, fieldName, defaultValue)
if isstruct(s) && isfield(s, fieldName)
    value = s.(fieldName);
else
    value = defaultValue;
end
end

function value = missingString()
value = string(missing);
end
