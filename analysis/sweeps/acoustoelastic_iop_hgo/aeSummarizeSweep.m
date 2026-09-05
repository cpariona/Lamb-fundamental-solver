function summary = aeSummarizeSweep(sweepResult)
%AESUMMARIZESWEEP Build AE analysis tables from the canonical 1-D sweep result.

if nargin < 1 || isempty(sweepResult) || ~isfield(sweepResult, 'results')
    error('aeSummarizeSweep requires canonical runParametricSweep output.');
end

summary = struct();
summary.name = specField(sweepResult, 'name', "");
summary.label = specField(sweepResult, 'label', string(sweepResult.parameter));
summary.sweepField = string(sweepResult.parameter);
summary.options = firstCellValue(sweepResult, 'options', struct());
summary.conditionTable = buildConditionTable(sweepResult);
summary.dispersionTable = buildDispersionTable(sweepResult);
summary.branchTable = buildSelectedBranchTable(sweepResult);
end

function T = buildConditionTable(sweepResult)
rows = [];
for i = 1:numel(sweepResult.results)
    result = sweepResult.results{i};
    if isempty(result) || ~isstruct(result)
        continue;
    end
    quality = resultField(result, 'quality', struct());
    value = sweepResult.values(i);

    row = struct();
    row.ConditionIndex = i;
    row.SweepName = specField(sweepResult, 'name', "");
    row.SweepLabel = specField(sweepResult, 'label', string(sweepResult.parameter));
    row.SweepField = string(sweepResult.parameter);
    row.SweepValue = value;
    row.SweepValueScaled = sweepResult.displayValues(i);
    row.SweepUnit = specField(sweepResult, 'units', "");
    row.SweepValueDisplay = formatDisplayValue(sweepResult, i);
    row.PolicyName = qualityField(quality, 'policyName', string(missing));
    row.ValidFraction = qualityField(quality, 'validFraction', nan);
    row.ValidPoints = qualityField(quality, 'validCount', nan);
    row.MissingPoints = qualityField(quality, 'missingCount', nan);
    row.TotalPoints = qualityField(quality, 'pointCount', nan);
    row.FirstValidFrequency_kHz = qualityField(quality, 'firstValidFrequency_kHz', nan);
    row.LastValidFrequency_kHz = qualityField(quality, 'lastValidFrequency_kHz', nan);
    row.FirstMissingFrequency_kHz = qualityField(quality, 'firstMissingFrequency_kHz', nan);
    row.A0StartFilterPassed = qualityField(quality, 'a0StartFilterPassed', false);
    row.SelectionFallbackUsed = qualityField(quality, 'selectionFallbackUsed', false);
    row.YStart = qualityField(quality, 'yStart', nan);
    row.StartRank = qualityField(quality, 'startRank', nan);
    row.CpStart_mps = qualityField(quality, 'cpStart_mps', nan);
    row.MaxBranchRelativeCpDrop = qualityField(quality, 'maxBranchRelativeCpDrop', nan);
    rows = [rows; row]; %#ok<AGROW>
end

if isempty(rows)
    T = table();
else
    T = struct2table(rows);
end
end

function T = buildDispersionTable(sweepResult)
rows = [];
for i = 1:numel(sweepResult.results)
    result = sweepResult.results{i};
    if isempty(result) || ~isstruct(result) || ~isfield(result, 'frequency_Hz')
        continue;
    end
    frequency = result.frequency_Hz(:);
    cp = result.phaseVelocity_mps(:);
    valid = logical(result.validMask(:));

    for k = 1:numel(frequency)
        row = struct();
        row.ConditionIndex = i;
        row.SweepName = specField(sweepResult, 'name', "");
        row.SweepField = string(sweepResult.parameter);
        row.SweepValue = sweepResult.values(i);
        row.SweepValueDisplay = formatDisplayValue(sweepResult, i);
        row.Frequency_Hz = frequency(k);
        row.Frequency_kHz = frequency(k) / 1e3;
        row.Cp_mps = cp(k);
        row.validCp = valid(k);
        row.pointStatus = getVectorValue(result, 'pointStatus', k, "");
        row.objective = getVectorValue(result, 'objective', k, nan);
        row.nearestRank = getVectorValue(result, 'nearestRank', k, nan);
        row.nearestBranchID = getVectorValue(result, 'nearestBranchID', k, nan);
        rows = [rows; row]; %#ok<AGROW>
    end
end

if isempty(rows)
    T = table();
else
    T = struct2table(rows);
end
end

function T = buildSelectedBranchTable(sweepResult)
T = table();
for i = 1:numel(sweepResult.results)
    result = sweepResult.results{i};
    if isempty(result) || ~isstruct(result) || ...
            ~isfield(result, 'selectedBranchPoints') || isempty(result.selectedBranchPoints)
        continue;
    end

    B = result.selectedBranchPoints;
    B.ConditionIndex = repmat(i, height(B), 1);
    B.SweepName = repmat(specField(sweepResult, 'name', ""), height(B), 1);
    B.SweepField = repmat(string(sweepResult.parameter), height(B), 1);
    B.SweepValue = repmat(sweepResult.values(i), height(B), 1);
    B.SweepValueDisplay = repmat(formatDisplayValue(sweepResult, i), height(B), 1);
    B = movevars(B, {'ConditionIndex','SweepName','SweepField','SweepValue','SweepValueDisplay'}, 'Before', 1);
    T = [T; B]; %#ok<AGROW>
end
end

function text = formatDisplayValue(sweepResult, index)
value = sweepResult.displayValues(index);
formatSpec = specField(sweepResult, 'valueFormatter', "%.6g");
text = string(sprintf(char(formatSpec), value));
units = specField(sweepResult, 'units', "");
if strlength(units) > 0
    text = text + " " + units;
end
end

function value = getVectorValue(s, fieldName, index, defaultValue)
value = defaultValue;
if isstruct(s) && isfield(s, fieldName)
    vector = s.(fieldName);
    if numel(vector) >= index
        value = vector(index);
    end
end
end

function value = qualityField(quality, fieldName, defaultValue)
value = defaultValue;
if isstruct(quality) && isfield(quality, fieldName)
    value = quality.(fieldName);
end
end

function value = resultField(result, fieldName, defaultValue)
value = defaultValue;
if isstruct(result) && isfield(result, fieldName)
    value = result.(fieldName);
end
end

function value = specField(sweepResult, fieldName, defaultValue)
value = defaultValue;
if isfield(sweepResult, 'spec') && isstruct(sweepResult.spec) && ...
        isfield(sweepResult.spec, fieldName) && ~isempty(sweepResult.spec.(fieldName))
    value = string(sweepResult.spec.(fieldName));
end
end

function value = firstCellValue(s, fieldName, defaultValue)
value = defaultValue;
if isfield(s, fieldName) && iscell(s.(fieldName)) && ~isempty(s.(fieldName))
    value = s.(fieldName){1};
end
end
