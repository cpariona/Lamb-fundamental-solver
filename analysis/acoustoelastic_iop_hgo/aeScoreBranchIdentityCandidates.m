function score = aeScoreBranchIdentityCandidates(result, varargin)
%AESCOREBRANCHIDENTITYCANDIDATES Score local minima as diagnostic branch-continuation candidates.
%
%   This helper is diagnostic only. It does not modify result.Cp,
%   result.validCp, or the maintained atlasA0 branch policy.
%
%   The score combines numerical continuity, slope continuity, local-minimum
%   rank, objective depth, crowding, and a soft high-frequency physical prior.
%   By default it recomputes deeper local minima from result.objectiveMap so the
%   diagnostic is not limited by the production atlasTopNMinima value.

opts = parseOptions(varargin{:});
f = result.frequency(:);
cp = result.Cp(:);
valid = logical(result.validCp(:)) & isfinite(cp);

[firstTerminalMissing, lastValid, firstInternalGap] = findTerminalBreak(valid);
center = firstTerminalMissing;
if isnan(center)
    center = lastValid;
end
idx = buildWindow(center, numel(f), opts.WindowPoints);

candidateTable = buildCandidateTable(result, f, cp, valid, idx, opts);
summary = buildSummary(candidateTable, f, valid, firstTerminalMissing, lastValid, firstInternalGap, opts);

score = struct();
score.options = opts;
score.summary = summary;
score.candidateTable = candidateTable;
end

function opts = parseOptions(varargin)
opts = struct();
opts.Label = "";
opts.WindowPoints = 6;
opts.HistoryPoints = 4;
opts.UseObjectiveMapMinima = true;
opts.DeepMinimaTopN = 80;
opts.MaxRankScale = 40;
opts.RelativeDistanceScale = 0.05;
opts.SlopeMismatchScale = 0.15;
opts.DropPenaltyScale = 0.05;
opts.CrowdingRelativeCp = 0.05;
opts.ObjectiveRatioScale = 3.0;
opts.WeightRelativeDistance = 2.0;
opts.WeightSlopeMismatch = 1.2;
opts.WeightRank = 0.8;
opts.WeightObjectiveDepth = 0.7;
opts.WeightCrowding = 0.8;
opts.WeightHighFrequencyDrop = 1.0;
opts.WeightHighFrequencyOscillation = 0.6;
opts.MinimaFrequencyTolerance_Hz = 1e-6;
opts.AcceptanceScoreThreshold = 3.0;
opts.StrongScoreThreshold = 1.5;
if mod(numel(varargin), 2) ~= 0
    error('Options must be supplied as name-value pairs.');
end
for i = 1:2:numel(varargin)
    name = lower(string(varargin{i}));
    value = varargin{i+1};
    switch name
        case 'label'
            opts.Label = string(value);
        case 'windowpoints'
            opts.WindowPoints = value;
        case 'historypoints'
            opts.HistoryPoints = value;
        case 'useobjectivemapminima'
            opts.UseObjectiveMapMinima = logical(value);
        case 'deepminimatopn'
            opts.DeepMinimaTopN = value;
        case 'maxrankscale'
            opts.MaxRankScale = value;
        case 'relativedistancescale'
            opts.RelativeDistanceScale = value;
        case 'slopemismatchscale'
            opts.SlopeMismatchScale = value;
        case 'droppenaltyscale'
            opts.DropPenaltyScale = value;
        case 'crowdingrelativecp'
            opts.CrowdingRelativeCp = value;
        case 'objectiveratioscale'
            opts.ObjectiveRatioScale = value;
        case 'weightrelativedistance'
            opts.WeightRelativeDistance = value;
        case 'weightslopemismatch'
            opts.WeightSlopeMismatch = value;
        case 'weightrank'
            opts.WeightRank = value;
        case 'weightobjectivedepth'
            opts.WeightObjectiveDepth = value;
        case 'weightcrowding'
            opts.WeightCrowding = value;
        case 'weighthighfrequencydrop'
            opts.WeightHighFrequencyDrop = value;
        case 'weighthighfrequencyoscillation'
            opts.WeightHighFrequencyOscillation = value;
        case 'minimafrequencytolerance_hz'
            opts.MinimaFrequencyTolerance_Hz = value;
        case 'acceptancescorethreshold'
            opts.AcceptanceScoreThreshold = value;
        case 'strongscorethreshold'
            opts.StrongScoreThreshold = value;
        otherwise
            error('Unknown aeScoreBranchIdentityCandidates option: %s', name);
    end
end
end

function [firstTerminalMissing, lastValid, firstInternalGap] = findTerminalBreak(valid)
idx = (1:numel(valid)).';
firstValid = find(valid, 1, 'first');
lastValid = find(valid, 1, 'last');
firstTerminalMissing = nan;
firstInternalGap = nan;
if isempty(firstValid) || isempty(lastValid)
    lastValid = nan;
    return;
end
firstInternalGap = find(~valid & idx >= firstValid & idx <= lastValid, 1, 'first');
if isempty(firstInternalGap)
    firstInternalGap = nan;
end
if lastValid < numel(valid)
    firstTerminalMissing = lastValid + 1;
end
end

function idx = buildWindow(centerIdx, n, windowPoints)
if isempty(centerIdx) || isnan(centerIdx)
    idx = (1:n).';
else
    idx = (max(1, centerIdx-windowPoints):min(n, centerIdx+windowPoints)).';
end
end

function T = buildCandidateTable(result, f, cp, valid, idx, opts)
rows = [];
for ii = 1:numel(idx)
    k = idx(ii);
    minima = minimaAtFrequency(result, f(k), k, opts);
    if isempty(minima)
        continue;
    end
    context = branchContext(f, cp, valid, k, opts.HistoryPoints);
    crowding = computeCrowding(minima, context.PreviousCp_mps, opts.CrowdingRelativeCp);
    deepestObjective = min(minima.Objective, [], 'omitnan');

    for m = 1:height(minima)
        row = struct();
        row.Index = k;
        row.Frequency_kHz = f(k) / 1e3;
        row.OfficialValid = valid(k);
        row.OfficialCp_mps = cp(k);
        row.PreviousValidIndex = context.PreviousIndex;
        row.PreviousValidFrequency_kHz = context.PreviousFrequency_kHz;
        row.PreviousCp_mps = context.PreviousCp_mps;
        row.PreviousRelativeSlope = context.RelativeSlope;
        row.CandidateCp_mps = minima.Cp_mps(m);
        row.CandidateY = getColumn(minima, 'y', m, nan);
        row.CandidateRank = getColumn(minima, 'MinRank', m, nan);
        row.CandidateObjective = getColumn(minima, 'Objective', m, nan);
        row.CandidateBranchID = getColumn(minima, 'BranchID', m, nan);
        row.CandidateSource = string(getColumn(minima, 'Source', m, "unknown"));
        row.RelativeDistanceToPreviousCp = abs(row.CandidateCp_mps - context.PreviousCp_mps) ./ max(abs(context.PreviousCp_mps), eps);
        row.RelativeCandidateSlope = candidateRelativeSlope(row.CandidateCp_mps, context.PreviousCp_mps, f(k), context.PreviousFrequency_Hz);
        row.SlopeMismatch = abs(row.RelativeCandidateSlope - context.RelativeSlope);
        row.RankPenalty = min(row.CandidateRank ./ max(opts.MaxRankScale, eps), 1);
        row.ObjectiveDepthPenalty = objectiveDepthPenalty(row.CandidateObjective, deepestObjective, opts.ObjectiveRatioScale);
        row.CrowdingWithin5pct = crowding;
        row.CrowdingPenalty = min(crowding ./ 25, 1);
        row.HighFrequencyDropPenalty = max(0, context.PreviousCp_mps - row.CandidateCp_mps) ./ max(abs(context.PreviousCp_mps), eps);
        row.HighFrequencyOscillationPenalty = highFrequencyOscillationPenalty(context.RelativeSlope, row.RelativeCandidateSlope);
        row.BranchIdentityScore = computeScore(row, opts);
        row.ScoreClass = classifyScore(row.BranchIdentityScore, opts);
        rows = [rows; row]; %#ok<AGROW>
    end
end

if isempty(rows)
    T = table();
    return;
end
T = struct2table(rows);
T = sortrows(T, {'Index', 'BranchIdentityScore', 'CandidateRank'});
T.IsBestAtFrequency = false(height(T), 1);
indices = unique(T.Index, 'stable');
for i = 1:numel(indices)
    j = find(T.Index == indices(i), 1, 'first');
    T.IsBestAtFrequency(j) = true;
end
end

function minima = minimaAtFrequency(result, f0, k, opts)
if opts.UseObjectiveMapMinima && isfield(result, 'objectiveMap') && isfield(result, 'cGrid') && size(result.objectiveMap, 2) >= k
    minima = minimaFromObjectiveMap(result, k, opts.DeepMinimaTopN);
    if ~isempty(minima)
        return;
    end
end

if ~isfield(result, 'minimaTable') || isempty(result.minimaTable)
    minima = table();
    return;
end
M = result.minimaTable;
minima = M(abs(M.Frequency_Hz - f0) <= opts.MinimaFrequencyTolerance_Hz * max(abs(f0), 1), :);
if ~isempty(minima)
    minima.Source = repmat("storedMinimaTable", height(minima), 1);
    minima = sortrows(minima, 'MinRank');
end
end

function minima = minimaFromObjectiveMap(result, k, topN)
obj = result.objectiveMap(:, k);
cGrid = result.cGrid(:);
yGrid = result.yGrid(:);
idx = [];
for i = 2:numel(obj)-1
    if isfinite(obj(i-1)) && isfinite(obj(i)) && isfinite(obj(i+1)) && obj(i) <= obj(i-1) && obj(i) <= obj(i+1)
        idx(end+1) = i; %#ok<AGROW>
    end
end
if isempty(idx)
    minima = table();
    return;
end
objective = obj(idx(:));
[objective, order] = sort(objective, 'ascend');
idx = idx(order);
keep = 1:min(topN, numel(idx));
idx = idx(keep);
objective = objective(keep);
minima = table();
minima.Frequency_Hz = repmat(result.frequency(k), numel(idx), 1);
minima.Frequency_kHz = repmat(result.frequency(k) / 1e3, numel(idx), 1);
minima.MinRank = (1:numel(idx)).';
minima.Cp_mps = cGrid(idx);
minima.y = yGrid(idx);
minima.log10y = log10(minima.y);
minima.Objective = objective(:);
minima.BranchID = nan(numel(idx), 1);
minima.Source = repmat("objectiveMap", numel(idx), 1);
end

function context = branchContext(f, cp, valid, k, historyPoints)
previousIdx = find(valid & (1:numel(valid)).' < k, 1, 'last');
context = struct();
context.PreviousIndex = nan;
context.PreviousFrequency_Hz = nan;
context.PreviousFrequency_kHz = nan;
context.PreviousCp_mps = nan;
context.RelativeSlope = 0;
if isempty(previousIdx)
    return;
end
context.PreviousIndex = previousIdx;
context.PreviousFrequency_Hz = f(previousIdx);
context.PreviousFrequency_kHz = f(previousIdx) / 1e3;
context.PreviousCp_mps = cp(previousIdx);

histIdx = find(valid & (1:numel(valid)).' <= previousIdx, historyPoints, 'last');
if numel(histIdx) >= 2
    p = polyfit(f(histIdx), cp(histIdx), 1);
    df = median(diff(f(histIdx)), 'omitnan');
    context.RelativeSlope = p(1) * df / max(abs(context.PreviousCp_mps), eps);
end
end

function s = candidateRelativeSlope(candidateCp, previousCp, fCandidate, fPrevious)
if ~isfinite(previousCp) || ~isfinite(fPrevious) || fCandidate == fPrevious
    s = 0;
else
    s = (candidateCp - previousCp) ./ max(abs(previousCp), eps);
end
end

function crowding = computeCrowding(minima, previousCp, relativeWindow)
if ~isfinite(previousCp) || isempty(minima)
    crowding = 0;
    return;
end
rel = abs(minima.Cp_mps - previousCp) ./ max(abs(previousCp), eps);
crowding = nnz(rel <= relativeWindow);
end

function penalty = objectiveDepthPenalty(candidateObjective, deepestObjective, scale)
if ~isfinite(candidateObjective) || ~isfinite(deepestObjective) || deepestObjective <= 0
    penalty = 1;
else
    ratio = candidateObjective ./ deepestObjective;
    penalty = min(log10(max(ratio, 1)) ./ max(log10(scale), eps), 1);
end
end

function penalty = highFrequencyOscillationPenalty(previousSlope, candidateSlope)
if ~isfinite(previousSlope) || ~isfinite(candidateSlope)
    penalty = 0;
elseif sign(previousSlope) ~= 0 && sign(candidateSlope) ~= 0 && sign(previousSlope) ~= sign(candidateSlope)
    penalty = min(abs(candidateSlope - previousSlope) / 0.10, 1);
else
    penalty = 0;
end
end

function score = computeScore(row, opts)
score = 0;
score = score + opts.WeightRelativeDistance * min(row.RelativeDistanceToPreviousCp / opts.RelativeDistanceScale, 1);
score = score + opts.WeightSlopeMismatch * min(row.SlopeMismatch / opts.SlopeMismatchScale, 1);
score = score + opts.WeightRank * row.RankPenalty;
score = score + opts.WeightObjectiveDepth * row.ObjectiveDepthPenalty;
score = score + opts.WeightCrowding * row.CrowdingPenalty;
score = score + opts.WeightHighFrequencyDrop * min(row.HighFrequencyDropPenalty / opts.DropPenaltyScale, 1);
score = score + opts.WeightHighFrequencyOscillation * row.HighFrequencyOscillationPenalty;
end

function cls = classifyScore(score, opts)
if score <= opts.StrongScoreThreshold
    cls = "strong_diagnostic_candidate";
elseif score <= opts.AcceptanceScoreThreshold
    cls = "caution_diagnostic_candidate";
else
    cls = "not_recommended";
end
end

function summary = buildSummary(T, f, valid, firstTerminalMissing, lastValid, firstInternalGap, opts)
summary = struct();
summary.CaseLabel = opts.Label;
summary.TotalPoints = numel(f);
summary.OfficialValidPoints = nnz(valid);
summary.FirstTerminalMissingIndex = firstTerminalMissing;
summary.FirstTerminalMissingFrequency_kHz = valueFrequency(f, firstTerminalMissing);
summary.LastOfficialValidIndex = lastValid;
summary.LastOfficialValidFrequency_kHz = valueFrequency(f, lastValid);
summary.FirstInternalGapIndex = firstInternalGap;
summary.FirstInternalGapFrequency_kHz = valueFrequency(f, firstInternalGap);
summary.HasInternalGap = isfinite(firstInternalGap);
summary.NumCandidates = height(T);
summary.NumBestFrequencyCandidates = 0;
summary.NumStrongDiagnosticCandidates = 0;
summary.NumCautionDiagnosticCandidates = 0;
summary.MedianBestScore = nan;
summary.MedianBestRank = nan;
summary.MedianBestRelativeDistance = nan;
summary.MedianBestCrowding = nan;
summary.DominantBestScoreClass = "none";
summary.RecommendedUse = "Diagnostic only; do not replace atlasA0 output.";
if isempty(T)
    return;
end
B = T(logical(T.IsBestAtFrequency), :);
summary.NumBestFrequencyCandidates = height(B);
summary.NumStrongDiagnosticCandidates = nnz(string(B.ScoreClass) == "strong_diagnostic_candidate");
summary.NumCautionDiagnosticCandidates = nnz(string(B.ScoreClass) == "caution_diagnostic_candidate");
summary.MedianBestScore = median(B.BranchIdentityScore, 'omitnan');
summary.MedianBestRank = median(B.CandidateRank, 'omitnan');
summary.MedianBestRelativeDistance = median(B.RelativeDistanceToPreviousCp, 'omitnan');
summary.MedianBestCrowding = median(B.CrowdingWithin5pct, 'omitnan');
summary.DominantBestScoreClass = dominantString(B.ScoreClass);
end

function value = dominantString(labels)
labels = string(labels);
priority = ["strong_diagnostic_candidate", "caution_diagnostic_candidate", "not_recommended"];
for i = 1:numel(priority)
    if any(labels == priority(i))
        value = priority(i);
        return;
    end
end
if isempty(labels)
    value = "none";
else
    value = labels(1);
end
end

function value = getColumn(T, name, idx, defaultValue)
if ismember(name, T.Properties.VariableNames)
    value = T.(name)(idx);
else
    value = defaultValue;
end
end

function value = valueFrequency(f, idx)
if isempty(idx) || isnan(idx)
    value = nan;
else
    value = f(idx) / 1e3;
end
end
