function caseAnalysis = aeAnalyzeTruncationCase(result, varargin)
%AEANALYZETRUNCATIONCASE Analyze where an atlasA0 branch becomes untraceable.
%
%   caseAnalysis = aeAnalyzeTruncationCase(result)
%
%   The input is one condition result from aeRunSweep, typically:
%
%       sweepResult.conditions(i).result
%
%   The helper focuses on the first missing point and its neighborhood. It
%   reports the last explicit valid point, the first missing frequency, nearby
%   selected-branch samples, and the closest atlas minima at frequencies around
%   the truncation limit.

opts = parseOptions(varargin{:});

frequency = result.frequency(:);
Cp = result.Cp(:);
validCp = logical(result.validCp(:)) & isfinite(Cp);
pointStatus = getResultVector(result, 'pointStatus', strings(size(frequency)));
nearestRank = getResultVector(result, 'nearestRank', nan(size(frequency)));
nearestBranchID = getResultVector(result, 'nearestBranchID', nan(size(frequency)));
objective = getResultVector(result, 'objective', nan(size(frequency)));

firstMissingIdx = find(~validCp, 1, 'first');
lastValidIdx = find(validCp, 1, 'last');
if isempty(firstMissingIdx)
    firstMissingIdx = nan;
end
if isempty(lastValidIdx)
    lastValidIdx = nan;
end

if isnan(firstMissingIdx)
    centerIdx = lastValidIdx;
else
    centerIdx = firstMissingIdx;
end
if isnan(centerIdx)
    idxWindow = [];
else
    idxWindow = max(1, centerIdx - opts.WindowPoints):min(numel(frequency), centerIdx + opts.WindowPoints);
end

summary = buildSummary(result, frequency, Cp, validCp, firstMissingIdx, lastValidIdx);
neighborhoodTable = buildNeighborhoodTable(result, frequency, Cp, validCp, pointStatus, nearestRank, nearestBranchID, objective, idxWindow);
firstMissingMinimaTable = buildFirstMissingMinimaTable(result, frequency, Cp, validCp, firstMissingIdx, opts.MinimaFrequencyTolerance_Hz);
branchCandidateTable = buildBranchCandidateTable(result);

caseAnalysis = struct();
caseAnalysis.label = opts.Label;
caseAnalysis.summary = summary;
caseAnalysis.neighborhoodTable = neighborhoodTable;
caseAnalysis.firstMissingMinimaTable = firstMissingMinimaTable;
caseAnalysis.branchCandidateTable = branchCandidateTable;
end

function opts = parseOptions(varargin)
opts = struct();
opts.Label = "";
opts.WindowPoints = 5;
opts.MinimaFrequencyTolerance_Hz = 1e-6;
if mod(numel(varargin), 2) ~= 0
    error('Options must be supplied as name-value pairs.');
end
for i = 1:2:numel(varargin)
    name = lower(string(varargin{i}));
    value = varargin{i+1};
    switch name
        case "label"
            opts.Label = string(value);
        case "windowpoints"
            opts.WindowPoints = value;
        case "minimafrequencytolerance_hz"
            opts.MinimaFrequencyTolerance_Hz = value;
        otherwise
            error('Unknown aeAnalyzeTruncationCase option: %s', name);
    end
end
end

function summary = buildSummary(result, frequency, Cp, validCp, firstMissingIdx, lastValidIdx)
summary = struct();
summary.TotalPoints = numel(frequency);
summary.ValidPoints = nnz(validCp);
summary.MissingPoints = nnz(~validCp);
summary.ValidFraction = nnz(validCp) / max(numel(validCp), 1);
summary.HasMissingPoints = any(~validCp);
summary.HasInternalGap = hasInternalGap(validCp);

if isnan(firstMissingIdx)
    summary.FirstMissingIndex = nan;
    summary.FirstMissingFrequency_kHz = nan;
else
    summary.FirstMissingIndex = firstMissingIdx;
    summary.FirstMissingFrequency_kHz = frequency(firstMissingIdx) / 1e3;
end

if isnan(lastValidIdx)
    summary.LastValidIndex = nan;
    summary.LastValidFrequency_kHz = nan;
    summary.LastValidCp_mps = nan;
else
    summary.LastValidIndex = lastValidIdx;
    summary.LastValidFrequency_kHz = frequency(lastValidIdx) / 1e3;
    summary.LastValidCp_mps = Cp(lastValidIdx);
end

beforeMissing = find(validCp & (1:numel(validCp)).' < firstMissingIdx, 1, 'last');
if isempty(beforeMissing)
    summary.LastValidBeforeFirstMissingIndex = nan;
    summary.LastValidBeforeFirstMissingFrequency_kHz = nan;
    summary.LastValidBeforeFirstMissingCp_mps = nan;
else
    summary.LastValidBeforeFirstMissingIndex = beforeMissing;
    summary.LastValidBeforeFirstMissingFrequency_kHz = frequency(beforeMissing) / 1e3;
    summary.LastValidBeforeFirstMissingCp_mps = Cp(beforeMissing);
end

relJump = abs(diff(Cp(validCp))) ./ max(abs(Cp(find(validCp, 1, 'first'):find(validCp, 1, 'last')-1)), eps); %#ok<FNDSB>
if nnz(validCp) < 2
    summary.MaxRelativeCpJumpAmongValidSequence = nan;
else
    validCpValues = Cp(validCp);
    validRelJump = abs(diff(validCpValues)) ./ max(abs(validCpValues(1:end-1)), eps);
    summary.MaxRelativeCpJumpAmongValidSequence = max(validRelJump, [], 'omitnan');
end

if isfield(result, 'reliability')
    rel = result.reliability;
    summary.PolicyName = string(getStructField(rel, 'PolicyName', ""));
    summary.A0StartFilterPassed = getStructField(rel, 'A0StartFilterPassed', false);
    summary.SelectionFallbackUsed = getStructField(rel, 'SelectionFallbackUsed', false);
    summary.YStart = getStructField(rel, 'YStart', nan);
    summary.StartRank = getStructField(rel, 'StartRank', nan);
else
    summary.PolicyName = "";
    summary.A0StartFilterPassed = false;
    summary.SelectionFallbackUsed = false;
    summary.YStart = nan;
    summary.StartRank = nan;
end
end

function T = buildNeighborhoodTable(result, frequency, Cp, validCp, pointStatus, nearestRank, nearestBranchID, objective, idxWindow)
if isempty(idxWindow)
    T = table(); return;
end
rows = [];
previousValidCp = nan;
for ii = 1:numel(idxWindow)
    idx = idxWindow(ii);
    if validCp(idx)
        previousValidCp = Cp(idx);
    end
    row = struct();
    row.Index = idx;
    row.Frequency_kHz = frequency(idx) / 1e3;
    row.Cp_mps = Cp(idx);
    row.ValidCp = validCp(idx);
    row.PointStatus = string(pointStatus(idx));
    row.NearestRank = nearestRank(idx);
    row.NearestBranchID = nearestBranchID(idx);
    row.Objective = objective(idx);
    row.PreviousValidCp_mps = previousValidCp;
    [row.NumMinimaAtFrequency, row.BestMinimaRank, row.BestMinimaCp_mps, row.BestMinimaObjective, ...
        row.ClosestMinimaRankToPreviousCp, row.ClosestMinimaCpToPreviousCp_mps, row.ClosestMinimaObjectiveToPreviousCp] = ...
        summarizeMinimaAtFrequency(result, frequency(idx), previousValidCp);
    rows = [rows; row]; %#ok<AGROW>
end
T = struct2table(rows);
end

function T = buildFirstMissingMinimaTable(result, frequency, Cp, validCp, firstMissingIdx, tolHz)
if isnan(firstMissingIdx) || ~isfield(result, 'minimaTable') || isempty(result.minimaTable)
    T = table(); return;
end
M = result.minimaTable;
f0 = frequency(firstMissingIdx);
idx = abs(M.Frequency_Hz - f0) <= tolHz * max(abs(f0), 1);
T = M(idx, :);
if isempty(T)
    return;
end
previousValidIdx = find(validCp & (1:numel(validCp)).' < firstMissingIdx, 1, 'last');
if isempty(previousValidIdx)
    previousCp = nan;
else
    previousCp = Cp(previousValidIdx);
end
T.DistanceToPreviousCp_mps = abs(T.Cp_mps - previousCp);
T.RelativeDistanceToPreviousCp = T.DistanceToPreviousCp_mps ./ max(abs(previousCp), eps);
T = sortrows(T, {'DistanceToPreviousCp_mps','Objective'});
end

function T = buildBranchCandidateTable(result)
if ~isfield(result, 'branchTable') || isempty(result.branchTable)
    T = table(); return;
end
T = result.branchTable;
if isfield(result, 'selectedBranchID') && ismember('BranchID', T.Properties.VariableNames)
    T.IsSelectedBranch = T.BranchID == result.selectedBranchID;
end
end

function [numMinima, bestRank, bestCp, bestObjective, closestRank, closestCp, closestObjective] = summarizeMinimaAtFrequency(result, f, previousCp)
numMinima = 0; bestRank = nan; bestCp = nan; bestObjective = nan;
closestRank = nan; closestCp = nan; closestObjective = nan;
if ~isfield(result, 'minimaTable') || isempty(result.minimaTable)
    return;
end
M = result.minimaTable;
idx = abs(M.Frequency_Hz - f) <= 1e-6 * max(abs(f), 1);
Mf = M(idx, :);
numMinima = height(Mf);
if isempty(Mf)
    return;
end
[~, bestIdx] = min(Mf.Objective);
bestRank = Mf.MinRank(bestIdx);
bestCp = Mf.Cp_mps(bestIdx);
bestObjective = Mf.Objective(bestIdx);
if isfinite(previousCp)
    [~, closeIdx] = min(abs(Mf.Cp_mps - previousCp));
    closestRank = Mf.MinRank(closeIdx);
    closestCp = Mf.Cp_mps(closeIdx);
    closestObjective = Mf.Objective(closeIdx);
end
end

function value = getResultVector(result, fieldName, defaultValue)
if isfield(result, fieldName)
    value = result.(fieldName)(:);
else
    value = defaultValue(:);
end
end

function tf = hasInternalGap(valid)
idx = find(logical(valid(:)));
tf = numel(idx) >= 2 && any(~valid(idx(1):idx(end)));
end

function value = getStructField(s, fieldName, defaultValue)
if isstruct(s) && isfield(s, fieldName)
    value = s.(fieldName);
else
    value = defaultValue;
end
end
