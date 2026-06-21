function summary = aeSummarizeGridSweep(sweepResult)
%AESUMMARIZEGRIDSWEEP Summarize a multi-parameter AE IOP/HGO grid sweep.

if nargin < 1 || isempty(sweepResult)
    error('aeSummarizeGridSweep requires a sweepResult structure.');
end

summary = struct();
summary.name = getStructField(sweepResult, 'name', "");
summary.label = getStructField(sweepResult, 'label', "");
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
        row = addAxisFields(row, condition);
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

    names = fieldnames(condition.axisValues);
    displayVars = cell(size(names));
    for n = 1:numel(names)
        name = names{n};
        displayName = [name 'Display'];
        T.(name) = repmat(condition.axisValues.(name), height(T), 1);
        T.(displayName) = repmat(string(condition.axisValueDisplays.(name)), height(T), 1);
        displayVars{n} = displayName;
    end

    firstVars = [{'ConditionIndex','SweepName'}, names(:).'];
    T = movevars(T, [firstVars, displayVars(:).'], 'Before', 1);
    branchTable = [branchTable; T]; %#ok<AGROW>
end
end

function row = addAxisFields(row, condition)
names = fieldnames(condition.axisValues);
for n = 1:numel(names)
    name = names{n};
    row.(name) = condition.axisValues.(name);
    row.([name 'Display']) = string(condition.axisValueDisplays.(name));
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
