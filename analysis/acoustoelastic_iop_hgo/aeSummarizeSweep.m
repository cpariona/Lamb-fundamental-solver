function summary = aeSummarizeSweep(sweepResult)
%AESUMMARIZESWEEP Summarize an acoustoelastic IOP/HGO sweep result.
%
%   summary = aeSummarizeSweep(sweepResult) builds analysis tables from the
%   structure returned by aeRunSweep.
%
%   This helper is intentionally analysis-only. It does not call the solver and
%   does not encode a particular branch policy in the file name. Branch-policy
%   details remain in the result.options and reliability fields.
%
%   Output fields
%   -------------
%   summary.conditionTable  : one row per sweep condition.
%   summary.dispersionTable : long table with one row per frequency-condition.
%   summary.branchTable     : selected branch points decorated by condition.

if nargin < 1 || isempty(sweepResult)
    error('aeSummarizeSweep requires a sweepResult structure returned by aeRunSweep.');
end

summary = struct();
summary.name = getStructField(sweepResult, 'name', "");
summary.label = getStructField(sweepResult, 'label', "");
summary.sweepField = getStructField(sweepResult, 'sweepField', "");
summary.options = getStructField(sweepResult, 'options', struct());

if isfield(sweepResult, 'summaryTable')
    summary.conditionTable = sweepResult.summaryTable;
else
    summary.conditionTable = table();
end

summary.dispersionTable = buildDispersionTable(sweepResult);
summary.branchTable = buildSelectedBranchTable(sweepResult);
end

function dispersionTable = buildDispersionTable(sweepResult)
rows = [];
if ~isfield(sweepResult, 'conditions') || isempty(sweepResult.conditions)
    dispersionTable = table();
    return;
end

for i = 1:numel(sweepResult.conditions)
    condition = sweepResult.conditions(i);
    if ~isfield(condition, 'result') || isempty(condition.result)
        continue;
    end
    result = condition.result;
    frequency = result.frequency(:);
    Cp = result.Cp(:);
    validCp = result.validCp(:);

    for k = 1:numel(frequency)
        row = struct();
        row.ConditionIndex = condition.index;
        row.SweepName = string(getStructField(sweepResult, 'name', ""));
        row.SweepField = string(condition.sweepField);
        row.SweepValue = condition.sweepValue;
        row.SweepValueDisplay = string(condition.sweepValueDisplay);
        row.Frequency_Hz = frequency(k);
        row.Frequency_kHz = frequency(k) / 1e3;
        row.Cp_mps = Cp(k);
        row.validCp = validCp(k);
        row.pointStatus = getVectorValue(result, 'pointStatus', k, "");
        row.objective = getVectorValue(result, 'objective', k, nan);
        row.nearestRank = getVectorValue(result, 'nearestRank', k, nan);
        row.nearestBranchID = getVectorValue(result, 'nearestBranchID', k, nan);
        rows = [rows; row]; %#ok<AGROW>
    end
end

if isempty(rows)
    dispersionTable = table();
else
    dispersionTable = struct2table(rows);
end
end

function branchTable = buildSelectedBranchTable(sweepResult)
branchTable = table();
if ~isfield(sweepResult, 'conditions') || isempty(sweepResult.conditions)
    return;
end

for i = 1:numel(sweepResult.conditions)
    condition = sweepResult.conditions(i);
    if ~isfield(condition, 'result') || isempty(condition.result)
        continue;
    end
    result = condition.result;
    if ~isfield(result, 'selectedBranchPoints') || isempty(result.selectedBranchPoints)
        continue;
    end

    T = result.selectedBranchPoints;
    T.ConditionIndex = repmat(condition.index, height(T), 1);
    T.SweepName = repmat(string(getStructField(sweepResult, 'name', "")), height(T), 1);
    T.SweepField = repmat(string(condition.sweepField), height(T), 1);
    T.SweepValue = repmat(condition.sweepValue, height(T), 1);
    T.SweepValueDisplay = repmat(string(condition.sweepValueDisplay), height(T), 1);
    T = movevars(T, {'ConditionIndex','SweepName','SweepField','SweepValue','SweepValueDisplay'}, 'Before', 1);
    branchTable = [branchTable; T]; %#ok<AGROW>
end
end

function value = getVectorValue(s, fieldName, index, defaultValue)
if isstruct(s) && isfield(s, fieldName)
    v = s.(fieldName);
    if numel(v) >= index
        value = v(index);
        return;
    end
end
value = defaultValue;
end

function value = getStructField(s, fieldName, defaultValue)
if isstruct(s) && isfield(s, fieldName)
    value = s.(fieldName);
else
    value = defaultValue;
end
end
