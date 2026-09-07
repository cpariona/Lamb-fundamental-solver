function analysis = aeAnalyzeSweepReliability(inputData, varargin)
%AEANALYZESWEEPRELIABILITY Analyze reliability and monotonicity of AE sweeps.

opts = parseOptions(varargin{:});
[summary, sweepResult] = normalizeInput(inputData);

conditionTable = getStructField(summary, 'conditionTable', table());
dispersionTable = getStructField(summary, 'dispersionTable', table());
branchTable = getStructField(summary, 'branchTable', table());

analysis = struct();
analysis.label = opts.Label;
analysis.expectedDirection = opts.ExpectedDirection;
analysis.tolerance = opts.Tolerance;
analysis.minFrequencyForMonotonicity_kHz = opts.MinFrequencyForMonotonicity_kHz;
analysis.conditionTable = conditionTable;
analysis.truncationTable = buildTruncationTable(conditionTable, dispersionTable);
analysis.branchConsistencyTable = buildBranchConsistencyTable(conditionTable, dispersionTable, branchTable);
analysis.monotonicityTable = buildMonotonicityTable(dispersionTable, opts.ExpectedDirection, opts.Tolerance, opts.MinFrequencyForMonotonicity_kHz);
analysis.monotonicitySummary = summarizeMonotonicity(analysis.monotonicityTable);
analysis.overallSummary = buildOverallSummary(analysis, sweepResult);
end

function opts = parseOptions(varargin)
opts = struct();
opts.ExpectedDirection = "increasing";
opts.Tolerance = 1e-9;
opts.MinFrequencyForMonotonicity_kHz = -inf;
opts.Label = "";

if mod(numel(varargin), 2) ~= 0
    error('Options must be supplied as name-value pairs.');
end
for i = 1:2:numel(varargin)
    name = lower(string(varargin{i}));
    value = varargin{i+1};
    switch name
        case "expecteddirection"
            opts.ExpectedDirection = string(value);
        case "tolerance"
            opts.Tolerance = value;
        case "minfrequencyformonotonicity_khz"
            opts.MinFrequencyForMonotonicity_kHz = value;
        case "label"
            opts.Label = string(value);
        otherwise
            error('Unknown aeAnalyzeSweepReliability option: %s', name);
    end
end
opts.ExpectedDirection = lower(opts.ExpectedDirection);
if ~(opts.ExpectedDirection == "increasing" || opts.ExpectedDirection == "decreasing")
    error('ExpectedDirection must be "increasing" or "decreasing".');
end
end

function [summary, sweepResult] = normalizeInput(inputData)
sweepResult = struct();
if isstruct(inputData) && isfield(inputData, 'results') && isfield(inputData, 'spec')
    sweepResult = inputData;
    summary = summarizeAcoustoelasticSensitivity(inputData);
elseif isstruct(inputData) && isfield(inputData, 'dispersionTable')
    summary = inputData;
else
    error('Input must be canonical runAcoustoelasticSensitivity output or an summarizeAcoustoelasticSensitivity summary.');
end
end

function T = buildTruncationTable(conditionTable, dispersionTable)
if isempty(conditionTable)
    T = table(); return;
end
rows = [];
for i = 1:height(conditionTable)
    row = tableRowToStruct(conditionTable, i);
    idx = dispersionTable.ConditionIndex == conditionTable.ConditionIndex(i);
    D = sortrows(dispersionTable(idx, :), 'Frequency_Hz');
    valid = logical(D.validCp) & isfinite(D.Cp_mps);
    freq = D.Frequency_kHz;
    validIdx = find(valid);
    if isempty(validIdx)
        row.FirstValidFrequency_kHz_FromDispersion = nan;
        row.LastValidFrequency_kHz_FromDispersion = nan;
        row.FirstMissingFrequency_kHz_FromDispersion = nan;
    else
        row.FirstValidFrequency_kHz_FromDispersion = freq(validIdx(1));
        row.LastValidFrequency_kHz_FromDispersion = freq(validIdx(end));
        missingAfterStart = find(~valid & freq >= freq(validIdx(1)), 1, 'first');
        if isempty(missingAfterStart)
            row.FirstMissingFrequency_kHz_FromDispersion = nan;
        else
            row.FirstMissingFrequency_kHz_FromDispersion = freq(missingAfterStart);
        end
    end
    [runLength, runStart, runEnd] = longestTrueRun(valid);
    row.LongestValidRunPoints = runLength;
    if runLength > 0
        row.LongestValidRunStart_kHz = freq(runStart);
        row.LongestValidRunEnd_kHz = freq(runEnd);
        row.LongestValidRunBandwidth_kHz = freq(runEnd) - freq(runStart);
    else
        row.LongestValidRunStart_kHz = nan;
        row.LongestValidRunEnd_kHz = nan;
        row.LongestValidRunBandwidth_kHz = nan;
    end
    row.HasInternalGap = hasInternalGap(valid);
    rows = [rows; row]; %#ok<AGROW>
end
T = struct2table(rows);
end

function T = buildBranchConsistencyTable(conditionTable, dispersionTable, branchTable)
if isempty(conditionTable)
    T = table(); return;
end
rows = [];
for i = 1:height(conditionTable)
    ci = conditionTable.ConditionIndex(i);
    D = sortrows(dispersionTable(dispersionTable.ConditionIndex == ci, :), 'Frequency_Hz');
    valid = logical(D.validCp) & isfinite(D.Cp_mps);
    Dv = D(valid, :);
    row = struct();
    row.ConditionIndex = ci;
    row.SweepName = string(conditionTable.SweepName(i));
    row.SweepField = string(conditionTable.SweepField(i));
    row.SweepValue = conditionTable.SweepValue(i);
    row.SweepValueDisplay = string(conditionTable.SweepValueDisplay(i));
    row.ValidPoints = height(Dv);
    row.TotalPoints = height(D);
    if isempty(Dv)
        row.MedianNearestRank = nan; row.MinNearestRank = nan; row.MaxNearestRank = nan;
        row.NumNearestRankChanges = nan; row.MedianObjective = nan; row.MinObjective = nan; row.MaxObjective = nan;
        row.MaxRelativeCpJump = nan; row.MedianRelativeCpJump = nan;
    else
        row.MedianNearestRank = median(Dv.nearestRank, 'omitnan');
        row.MinNearestRank = min(Dv.nearestRank, [], 'omitnan');
        row.MaxNearestRank = max(Dv.nearestRank, [], 'omitnan');
        row.NumNearestRankChanges = nnz(diff(Dv.nearestRank) ~= 0);
        row.MedianObjective = median(Dv.objective, 'omitnan');
        row.MinObjective = min(Dv.objective, [], 'omitnan');
        row.MaxObjective = max(Dv.objective, [], 'omitnan');
        relJump = abs(diff(Dv.Cp_mps)) ./ max(abs(Dv.Cp_mps(1:end-1)), eps);
        if isempty(relJump)
            row.MaxRelativeCpJump = 0; row.MedianRelativeCpJump = 0;
        else
            row.MaxRelativeCpJump = max(relJump, [], 'omitnan');
            row.MedianRelativeCpJump = median(relJump, 'omitnan');
        end
    end
    if ~isempty(branchTable) && any(branchTable.ConditionIndex == ci)
        B = branchTable(branchTable.ConditionIndex == ci, :);
        row.SelectedBranchPointCount = height(B);
        row.SelectedBranchMinRank = min(B.MinRank, [], 'omitnan');
        row.SelectedBranchMaxRank = max(B.MinRank, [], 'omitnan');
        row.SelectedBranchMedianRank = median(B.MinRank, 'omitnan');
    else
        row.SelectedBranchPointCount = 0;
        row.SelectedBranchMinRank = nan;
        row.SelectedBranchMaxRank = nan;
        row.SelectedBranchMedianRank = nan;
    end
    rows = [rows; row]; %#ok<AGROW>
end
T = struct2table(rows);
end

function T = buildMonotonicityTable(dispersionTable, expectedDirection, tol, minFrequency_kHz)
if isempty(dispersionTable)
    T = table(); return;
end
conditionMeta = unique(dispersionTable(:, {'ConditionIndex','SweepValue','SweepValueDisplay'}), 'rows');
conditionMeta = sortrows(conditionMeta, 'SweepValue');
conditionOrder = conditionMeta.ConditionIndex(:).';
freqList = unique(dispersionTable.Frequency_Hz, 'stable');
freqList = freqList(freqList/1e3 >= minFrequency_kHz);
rows = [];
for k = 1:numel(freqList)
    f = freqList(k);
    cp = nan(1, numel(conditionOrder));
    valid = false(1, numel(conditionOrder));
    for j = 1:numel(conditionOrder)
        idx = find(dispersionTable.Frequency_Hz == f & dispersionTable.ConditionIndex == conditionOrder(j), 1, 'first');
        if ~isempty(idx)
            cp(j) = dispersionTable.Cp_mps(idx);
            valid(j) = logical(dispersionTable.validCp(idx)) && isfinite(cp(j));
        end
    end
    sharedValid = all(valid);
    if sharedValid
        dCp = diff(cp);
        if expectedDirection == "increasing"
            isMonotonic = all(dCp >= -tol);
            worstViolation = min(dCp);
            numViolations = nnz(dCp < -tol);
        else
            isMonotonic = all(dCp <= tol);
            worstViolation = max(dCp);
            numViolations = nnz(dCp > tol);
        end
    else
        dCp = nan(1, max(numel(cp)-1, 0));
        isMonotonic = false;
        worstViolation = nan;
        numViolations = nan;
    end
    row = struct();
    row.Frequency_Hz = f;
    row.Frequency_kHz = f/1e3;
    row.MinFrequencyForMonotonicity_kHz = minFrequency_kHz;
    row.Tolerance_mps = tol;
    row.SharedValid = sharedValid;
    row.IsMonotonic = isMonotonic;
    row.NumViolations = numViolations;
    row.WorstSignedDifference_mps = worstViolation;
    row.MinCp_mps = min(cp, [], 'omitnan');
    row.MaxCp_mps = max(cp, [], 'omitnan');
    row.CpRange_mps = row.MaxCp_mps - row.MinCp_mps;
    row.NumConditions = numel(conditionOrder);
    row.NumValidConditions = nnz(valid);
    row.CpValues_mps = string(mat2str(cp, 5));
    row.DeltaCpValues_mps = string(mat2str(dCp, 5));
    rows = [rows; row]; %#ok<AGROW>
end
if isempty(rows)
    T = table();
else
    T = struct2table(rows);
end
end

function S = summarizeMonotonicity(T)
S = struct();
if isempty(T)
    S.SharedValidFrequencyCount = 0;
    S.MonotonicSharedFrequencyCount = 0;
    S.MonotonicSharedFraction = nan;
    S.FirstNonMonotonicFrequency_kHz = nan;
    S.MinSharedFrequency_kHz = nan;
    S.MaxSharedFrequency_kHz = nan;
    return;
end
shared = logical(T.SharedValid);
mono = logical(T.IsMonotonic) & shared;
S.SharedValidFrequencyCount = nnz(shared);
S.MonotonicSharedFrequencyCount = nnz(mono);
S.MonotonicSharedFraction = nnz(mono) / max(nnz(shared), 1);
if any(shared)
    f = T.Frequency_kHz(shared);
    S.MinSharedFrequency_kHz = min(f);
    S.MaxSharedFrequency_kHz = max(f);
else
    S.MinSharedFrequency_kHz = nan;
    S.MaxSharedFrequency_kHz = nan;
end
idx = find(shared & ~mono, 1, 'first');
if isempty(idx)
    S.FirstNonMonotonicFrequency_kHz = nan;
else
    S.FirstNonMonotonicFrequency_kHz = T.Frequency_kHz(idx);
end
end

function S = buildOverallSummary(analysis, sweepResult)
S = struct();
S.Label = analysis.label;
S.ExpectedDirection = analysis.expectedDirection;
S.Tolerance_mps = analysis.tolerance;
S.MinFrequencyForMonotonicity_kHz = analysis.minFrequencyForMonotonicity_kHz;
S.NumConditions = height(analysis.conditionTable);
S.NumMonotonicSharedFrequencies = analysis.monotonicitySummary.MonotonicSharedFrequencyCount;
S.NumSharedValidFrequencies = analysis.monotonicitySummary.SharedValidFrequencyCount;
S.MonotonicSharedFraction = analysis.monotonicitySummary.MonotonicSharedFraction;
S.SharedFrequencyMin_kHz = analysis.monotonicitySummary.MinSharedFrequency_kHz;
S.SharedFrequencyMax_kHz = analysis.monotonicitySummary.MaxSharedFrequency_kHz;
if ~isempty(analysis.truncationTable)
    S.MinValidFraction = min(analysis.truncationTable.ValidFraction, [], 'omitnan');
    S.MaxValidFraction = max(analysis.truncationTable.ValidFraction, [], 'omitnan');
    S.MinLastValidFrequency_kHz = min(analysis.truncationTable.LastValidFrequency_kHz, [], 'omitnan');
    S.MaxLastValidFrequency_kHz = max(analysis.truncationTable.LastValidFrequency_kHz, [], 'omitnan');
else
    S.MinValidFraction = nan; S.MaxValidFraction = nan;
    S.MinLastValidFrequency_kHz = nan; S.MaxLastValidFrequency_kHz = nan;
end
S.PolicyName = sweepPolicy(sweepResult);
end

function value = sweepPolicy(sweepResult)
value = "";
if ~isstruct(sweepResult) || ~isfield(sweepResult, 'options') || ...
        ~iscell(sweepResult.options) || isempty(sweepResult.options)
    return;
end
options = sweepResult.options{1};
if isstruct(options) && isfield(options, 'atlasBranchPolicy')
    value = string(options.atlasBranchPolicy);
end
end

function [runLength, runStart, runEnd] = longestTrueRun(mask)
mask = logical(mask(:)); runLength = 0; runStart = nan; runEnd = nan;
currentStart = nan; currentLength = 0;
for i = 1:numel(mask)
    if mask(i)
        if currentLength == 0, currentStart = i; end
        currentLength = currentLength + 1;
        if currentLength > runLength
            runLength = currentLength; runStart = currentStart; runEnd = i;
        end
    else
        currentLength = 0; currentStart = nan;
    end
end
end

function tf = hasInternalGap(valid)
idx = find(logical(valid(:)));
tf = numel(idx) >= 2 && any(~valid(idx(1):idx(end)));
end

function row = tableRowToStruct(T, i)
row = struct();
for k = 1:numel(T.Properties.VariableNames)
    name = T.Properties.VariableNames{k};
    value = T.(name)(i, :);
    if iscell(value) && numel(value) == 1, value = value{1}; end
    row.(name) = value;
end
end

function value = getStructField(s, fieldName, defaultValue)
if isstruct(s) && isfield(s, fieldName)
    value = s.(fieldName);
else
    value = defaultValue;
end
end
