function caseAnalysis = aeAnalyzeTruncationCase(result, varargin)
%AEANALYZETRUNCATIONCASE Analyze where an atlasA0 branch becomes untraceable.

opts = parseOptions(varargin{:});
f = result.frequency(:);
cp = result.Cp(:);
valid = logical(result.validCp(:)) & isfinite(cp);
status = getVector(result, 'pointStatus', strings(size(f)));
rank = getVector(result, 'nearestRank', nan(size(f)));
branchID = getVector(result, 'nearestBranchID', nan(size(f)));
obj = getVector(result, 'objective', nan(size(f)));

firstMissing = find(~valid, 1, 'first');
lastValid = find(valid, 1, 'last');
if isempty(firstMissing), firstMissing = nan; end
if isempty(lastValid), lastValid = nan; end

if isnan(firstMissing), center = lastValid; else, center = firstMissing; end
if isnan(center)
    win = [];
else
    win = max(1, center-opts.WindowPoints):min(numel(f), center+opts.WindowPoints);
end

caseAnalysis = struct();
caseAnalysis.label = opts.Label;
caseAnalysis.summary = buildSummary(result, f, cp, valid, firstMissing, lastValid);
caseAnalysis.neighborhoodTable = buildNeighborhoodTable(result, f, cp, valid, status, rank, branchID, obj, win);
caseAnalysis.firstMissingMinimaTable = buildFirstMissingMinimaTable(result, f, cp, valid, firstMissing, opts.MinimaFrequencyTolerance_Hz);
caseAnalysis.branchCandidateTable = buildBranchCandidateTable(result);
end

function opts = parseOptions(varargin)
opts = struct('Label', "", 'WindowPoints', 5, 'MinimaFrequencyTolerance_Hz', 1e-6);
if mod(numel(varargin),2) ~= 0, error('Options must be name-value pairs.'); end
for i = 1:2:numel(varargin)
    name = lower(string(varargin{i})); value = varargin{i+1};
    switch name
        case "label", opts.Label = string(value);
        case "windowpoints", opts.WindowPoints = value;
        case "minimafrequencytolerance_hz", opts.MinimaFrequencyTolerance_Hz = value;
        otherwise, error('Unknown aeAnalyzeTruncationCase option: %s', name);
    end
end
end

function summary = buildSummary(result, f, cp, valid, firstMissing, lastValid)
summary = struct();
summary.TotalPoints = numel(f);
summary.ValidPoints = nnz(valid);
summary.MissingPoints = nnz(~valid);
summary.ValidFraction = nnz(valid)/max(numel(valid),1);
summary.HasMissingPoints = any(~valid);
summary.HasInternalGap = hasInternalGap(valid);

if isnan(firstMissing)
    summary.FirstMissingIndex = nan; summary.FirstMissingFrequency_kHz = nan;
else
    summary.FirstMissingIndex = firstMissing; summary.FirstMissingFrequency_kHz = f(firstMissing)/1e3;
end
if isnan(lastValid)
    summary.LastValidIndex = nan; summary.LastValidFrequency_kHz = nan; summary.LastValidCp_mps = nan;
else
    summary.LastValidIndex = lastValid; summary.LastValidFrequency_kHz = f(lastValid)/1e3; summary.LastValidCp_mps = cp(lastValid);
end

beforeMissing = find(valid & (1:numel(valid)).' < firstMissing, 1, 'last');
if isempty(beforeMissing)
    summary.LastValidBeforeFirstMissingIndex = nan;
    summary.LastValidBeforeFirstMissingFrequency_kHz = nan;
    summary.LastValidBeforeFirstMissingCp_mps = nan;
else
    summary.LastValidBeforeFirstMissingIndex = beforeMissing;
    summary.LastValidBeforeFirstMissingFrequency_kHz = f(beforeMissing)/1e3;
    summary.LastValidBeforeFirstMissingCp_mps = cp(beforeMissing);
end

if nnz(valid) < 2
    summary.MaxRelativeCpJumpAmongValidSequence = nan;
else
    cpv = cp(valid);
    summary.MaxRelativeCpJumpAmongValidSequence = max(abs(diff(cpv))./max(abs(cpv(1:end-1)),eps), [], 'omitnan');
end

if isfield(result, 'reliability')
    rel = result.reliability;
    summary.PolicyName = string(getField(rel, 'PolicyName', ""));
    summary.A0StartFilterPassed = getField(rel, 'A0StartFilterPassed', false);
    summary.SelectionFallbackUsed = getField(rel, 'SelectionFallbackUsed', false);
    summary.YStart = getField(rel, 'YStart', nan);
    summary.StartRank = getField(rel, 'StartRank', nan);
else
    summary.PolicyName = ""; summary.A0StartFilterPassed = false; summary.SelectionFallbackUsed = false;
    summary.YStart = nan; summary.StartRank = nan;
end
end

function T = buildNeighborhoodTable(result, f, cp, valid, status, rank, branchID, obj, win)
if isempty(win), T = table(); return; end
rows = [];
previousCp = nan;
for ii = 1:numel(win)
    k = win(ii);
    if valid(k), previousCp = cp(k); end
    row = struct();
    row.Index = k;
    row.Frequency_kHz = f(k)/1e3;
    row.Cp_mps = cp(k);
    row.ValidCp = valid(k);
    row.PointStatus = string(status(k));
    row.NearestRank = rank(k);
    row.NearestBranchID = branchID(k);
    row.Objective = obj(k);
    row.PreviousValidCp_mps = previousCp;
    [row.NumMinimaAtFrequency, row.BestMinimaRank, row.BestMinimaCp_mps, row.BestMinimaObjective, row.ClosestMinimaRankToPreviousCp, row.ClosestMinimaCpToPreviousCp_mps, row.ClosestMinimaObjectiveToPreviousCp] = summarizeMinima(result, f(k), previousCp);
    rows = [rows; row]; %#ok<AGROW>
end
T = struct2table(rows);
end

function T = buildFirstMissingMinimaTable(result, f, cp, valid, firstMissing, tolHz)
if isnan(firstMissing) || ~isfield(result,'minimaTable') || isempty(result.minimaTable)
    T = table(); return;
end
M = result.minimaTable; f0 = f(firstMissing);
T = M(abs(M.Frequency_Hz - f0) <= tolHz*max(abs(f0),1), :);
if isempty(T), return; end
prevIdx = find(valid & (1:numel(valid)).' < firstMissing, 1, 'last');
if isempty(prevIdx), prevCp = nan; else, prevCp = cp(prevIdx); end
T.DistanceToPreviousCp_mps = abs(T.Cp_mps - prevCp);
T.RelativeDistanceToPreviousCp = T.DistanceToPreviousCp_mps ./ max(abs(prevCp), eps);
T = sortrows(T, {'DistanceToPreviousCp_mps','Objective'});
end

function T = buildBranchCandidateTable(result)
if ~isfield(result,'branchTable') || isempty(result.branchTable)
    T = table(); return;
end
T = result.branchTable;
if isfield(result,'selectedBranchID') && ismember('BranchID', T.Properties.VariableNames)
    T.IsSelectedBranch = T.BranchID == result.selectedBranchID;
end
end

function [n,bRank,bCp,bObj,cRank,cCp,cObj] = summarizeMinima(result, f0, previousCp)
n = 0; bRank = nan; bCp = nan; bObj = nan; cRank = nan; cCp = nan; cObj = nan;
if ~isfield(result,'minimaTable') || isempty(result.minimaTable), return; end
M = result.minimaTable;
Mf = M(abs(M.Frequency_Hz - f0) <= 1e-6*max(abs(f0),1), :);
n = height(Mf);
if isempty(Mf), return; end
[~, ib] = min(Mf.Objective); bRank = Mf.MinRank(ib); bCp = Mf.Cp_mps(ib); bObj = Mf.Objective(ib);
if isfinite(previousCp)
    [~, ic] = min(abs(Mf.Cp_mps - previousCp)); cRank = Mf.MinRank(ic); cCp = Mf.Cp_mps(ic); cObj = Mf.Objective(ic);
end
end

function value = getVector(result, fieldName, defaultValue)
if isfield(result, fieldName), value = result.(fieldName)(:); else, value = defaultValue(:); end
end

function tf = hasInternalGap(valid)
idx = find(logical(valid(:)));
tf = numel(idx) >= 2 && any(~valid(idx(1):idx(end)));
end

function value = getField(s, fieldName, defaultValue)
if isstruct(s) && isfield(s, fieldName), value = s.(fieldName); else, value = defaultValue; end
end
