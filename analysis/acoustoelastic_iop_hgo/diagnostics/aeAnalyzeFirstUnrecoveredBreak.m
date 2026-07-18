function breakAnalysis = aeAnalyzeFirstUnrecoveredBreak(result, recovery, varargin)
%AEANALYZEFIRSTUNRECOVEREDBREAK Inspect the first unrecovered contiguous break.
%
%   breakAnalysis = aeAnalyzeFirstUnrecoveredBreak(result, recovery)
%
%   Focuses on the first frequency where contiguous recovery fails. It reports
%   local minima at that frequency, compares them against the previous
%   contiguous Cp, and classifies whether the break looks like a threshold miss,
%   a distant candidate, or a missing-minima case. This is diagnostic only and
%   does not alter atlasA0 or recovered branches.

opts = parseOptions(varargin{:});
f = result.frequency(:);
cp = result.Cp(:);
valid = logical(result.validCp(:)) & isfinite(cp);
contiguousValid = logical(recovery.contiguousRecoveredValid(:));
contiguousCp = recovery.contiguousRecoveredCp(:);

breakAnalysis = struct();
breakAnalysis.options = opts;
breakAnalysis.summary = emptySummary();
breakAnalysis.breakMinimaTable = table();
breakAnalysis.localWindowTable = table();

firstContiguous = find(contiguousValid, 1, 'first');
if isempty(firstContiguous)
    breakAnalysis.summary.BreakClass = "no_contiguous_start";
    breakAnalysis.summary.Interpretation = "No contiguous branch start was found.";
    return;
end

firstBreak = find(~contiguousValid & (1:numel(contiguousValid)).' > firstContiguous, 1, 'first');
if isempty(firstBreak)
    breakAnalysis.summary.BreakClass = "no_unrecovered_break";
    breakAnalysis.summary.Interpretation = "No unrecovered contiguous break remains after diagnostic recovery.";
    breakAnalysis.localWindowTable = buildLocalWindowTable(f, cp, valid, contiguousCp, contiguousValid, nan, opts.WindowPoints);
    return;
end

previousIdx = find(contiguousValid & (1:numel(contiguousValid)).' < firstBreak, 1, 'last');
nextOriginalIdx = find(valid & (1:numel(valid)).' > firstBreak, 1, 'first');
previousCp = contiguousCp(previousIdx);
nextOriginalCp = nan;
if ~isempty(nextOriginalIdx)
    nextOriginalCp = cp(nextOriginalIdx);
end

[minimaAtBreak, nearest] = inspectMinimaAtFrequency(result, f(firstBreak), previousCp, opts);
windowTable = buildLocalWindowTable(f, cp, valid, contiguousCp, contiguousValid, firstBreak, opts.WindowPoints);

summary = emptySummary();
summary.BreakIndex = firstBreak;
summary.BreakFrequency_kHz = f(firstBreak)/1e3;
summary.PreviousContiguousIndex = previousIdx;
summary.PreviousContiguousFrequency_kHz = f(previousIdx)/1e3;
summary.PreviousContiguousCp_mps = previousCp;
summary.NextOriginalValidIndex = valueOrNaN(nextOriginalIdx);
summary.NextOriginalValidFrequency_kHz = valueOrNaNFrequency(f, nextOriginalIdx);
summary.NextOriginalValidCp_mps = nextOriginalCp;
summary.NumMinimaAtBreak = height(minimaAtBreak);
summary.NearestMinimaCp_mps = nearest.Cp_mps;
summary.NearestMinimaRank = nearest.MinRank;
summary.NearestMinimaObjective = nearest.Objective;
summary.NearestMinimaBranchID = nearest.BranchID;
summary.NearestRelativeDistanceToPreviousCp = nearest.RelativeDistanceToPreviousCp;
summary.NearestAbsoluteDistanceToPreviousCp_mps = nearest.AbsoluteDistanceToPreviousCp_mps;
summary.BestObjectiveMinimaCp_mps = nearest.BestObjectiveCp_mps;
summary.BestObjectiveMinimaRank = nearest.BestObjectiveRank;
summary.BestObjective = nearest.BestObjective;
summary.BestObjectiveRelativeDistanceToPreviousCp = nearest.BestObjectiveRelativeDistanceToPreviousCp;
summary.ThresholdRelativeCpDistance = opts.MaxRelativeCpDistance;
summary.ThresholdAbsoluteCpDistance_mps = opts.MaxAbsoluteCpDistance_mps;
summary.RelativeDistanceMargin = nearest.RelativeDistanceToPreviousCp - opts.MaxRelativeCpDistance;

if height(minimaAtBreak) == 0
    summary.BreakClass = "no_minima_at_break";
    summary.Interpretation = "No local minima were stored at the first unrecovered contiguous break frequency.";
elseif nearest.RelativeDistanceToPreviousCp <= opts.MaxRelativeCpDistance
    summary.BreakClass = "would_pass_relative_threshold";
    summary.Interpretation = "A local minimum close to the previous contiguous Cp exists and would pass the relative-distance threshold; inspect why it was not selected by contiguous recovery.";
elseif nearest.RelativeDistanceToPreviousCp <= opts.NearMissRelativeCpDistance
    summary.BreakClass = "near_threshold_miss";
    summary.Interpretation = "A local minimum exists near the previous contiguous Cp but lies just outside the conservative relative-distance threshold.";
else
    summary.BreakClass = "distant_local_minimum";
    summary.Interpretation = "Local minima exist at the break frequency, but the nearest one is too far from the previous contiguous Cp under the current continuity threshold.";
end

breakAnalysis.summary = summary;
breakAnalysis.breakMinimaTable = minimaAtBreak;
breakAnalysis.localWindowTable = windowTable;
end

function opts = parseOptions(varargin)
opts = struct();
opts.MaxRelativeCpDistance = 0.08;
opts.MaxAbsoluteCpDistance_mps = inf;
opts.NearMissRelativeCpDistance = 0.15;
opts.MinimaFrequencyTolerance_Hz = 1e-6;
opts.WindowPoints = 6;
if mod(numel(varargin), 2) ~= 0
    error('Options must be supplied as name-value pairs.');
end
for i = 1:2:numel(varargin)
    name = lower(string(varargin{i}));
    value = varargin{i+1};
    switch name
        case "maxrelativecpdistance"
            opts.MaxRelativeCpDistance = value;
        case "maxabsolutecpdistance_mps"
            opts.MaxAbsoluteCpDistance_mps = value;
        case "nearmissrelativecpdistance"
            opts.NearMissRelativeCpDistance = value;
        case "minimafrequencytolerance_hz"
            opts.MinimaFrequencyTolerance_Hz = value;
        case "windowpoints"
            opts.WindowPoints = value;
        otherwise
            error('Unknown aeAnalyzeFirstUnrecoveredBreak option: %s', name);
    end
end
end

function summary = emptySummary()
summary = struct();
summary.BreakIndex = nan;
summary.BreakFrequency_kHz = nan;
summary.PreviousContiguousIndex = nan;
summary.PreviousContiguousFrequency_kHz = nan;
summary.PreviousContiguousCp_mps = nan;
summary.NextOriginalValidIndex = nan;
summary.NextOriginalValidFrequency_kHz = nan;
summary.NextOriginalValidCp_mps = nan;
summary.NumMinimaAtBreak = nan;
summary.NearestMinimaCp_mps = nan;
summary.NearestMinimaRank = nan;
summary.NearestMinimaObjective = nan;
summary.NearestMinimaBranchID = nan;
summary.NearestRelativeDistanceToPreviousCp = nan;
summary.NearestAbsoluteDistanceToPreviousCp_mps = nan;
summary.BestObjectiveMinimaCp_mps = nan;
summary.BestObjectiveMinimaRank = nan;
summary.BestObjective = nan;
summary.BestObjectiveRelativeDistanceToPreviousCp = nan;
summary.ThresholdRelativeCpDistance = nan;
summary.ThresholdAbsoluteCpDistance_mps = nan;
summary.RelativeDistanceMargin = nan;
summary.BreakClass = "unknown";
summary.Interpretation = "No interpretation available.";
end

function [minimaAtBreak, nearest] = inspectMinimaAtFrequency(result, f0, previousCp, opts)
nearest = emptyNearest();
if ~isfield(result, 'minimaTable') || isempty(result.minimaTable)
    minimaAtBreak = table();
    return;
end

M = result.minimaTable;
idx = abs(M.Frequency_Hz - f0) <= opts.MinimaFrequencyTolerance_Hz * max(abs(f0), 1);
minimaAtBreak = M(idx, :);
if isempty(minimaAtBreak)
    return;
end

absDist = abs(minimaAtBreak.Cp_mps - previousCp);
relDist = absDist ./ max(abs(previousCp), eps);
minimaAtBreak.AbsoluteDistanceToPreviousCp_mps = absDist;
minimaAtBreak.RelativeDistanceToPreviousCp = relDist;
minimaAtBreak.PassRelativeThreshold = relDist <= opts.MaxRelativeCpDistance;
minimaAtBreak.PassAbsoluteThreshold = absDist <= opts.MaxAbsoluteCpDistance_mps;
minimaAtBreak.PassEitherThreshold = minimaAtBreak.PassRelativeThreshold | minimaAtBreak.PassAbsoluteThreshold;

[~, jNear] = min(relDist);
nearest.Cp_mps = minimaAtBreak.Cp_mps(jNear);
nearest.MinRank = getTableColumnValue(minimaAtBreak, 'MinRank', jNear, nan);
nearest.Objective = getTableColumnValue(minimaAtBreak, 'Objective', jNear, nan);
nearest.BranchID = getTableColumnValue(minimaAtBreak, 'BranchID', jNear, nan);
nearest.RelativeDistanceToPreviousCp = relDist(jNear);
nearest.AbsoluteDistanceToPreviousCp_mps = absDist(jNear);

if ismember('Objective', minimaAtBreak.Properties.VariableNames)
    [~, jBest] = min(minimaAtBreak.Objective);
else
    jBest = 1;
end
nearest.BestObjectiveCp_mps = minimaAtBreak.Cp_mps(jBest);
nearest.BestObjectiveRank = getTableColumnValue(minimaAtBreak, 'MinRank', jBest, nan);
nearest.BestObjective = getTableColumnValue(minimaAtBreak, 'Objective', jBest, nan);
nearest.BestObjectiveRelativeDistanceToPreviousCp = relDist(jBest);
end

function nearest = emptyNearest()
nearest = struct();
nearest.Cp_mps = nan;
nearest.MinRank = nan;
nearest.Objective = nan;
nearest.BranchID = nan;
nearest.RelativeDistanceToPreviousCp = nan;
nearest.AbsoluteDistanceToPreviousCp_mps = nan;
nearest.BestObjectiveCp_mps = nan;
nearest.BestObjectiveRank = nan;
nearest.BestObjective = nan;
nearest.BestObjectiveRelativeDistanceToPreviousCp = nan;
end

function value = getTableColumnValue(T, name, idx, defaultValue)
if ismember(name, T.Properties.VariableNames)
    value = T.(name)(idx);
else
    value = defaultValue;
end
end

function T = buildLocalWindowTable(f, cp, valid, contiguousCp, contiguousValid, centerIdx, windowPoints)
if isnan(centerIdx)
    idx = (1:numel(f)).';
else
    firstIdx = max(1, centerIdx - windowPoints);
    lastIdx = min(numel(f), centerIdx + windowPoints);
    idx = (firstIdx:lastIdx).';
end
T = table();
T.Index = idx;
T.Frequency_kHz = f(idx)/1e3;
T.OriginalCp_mps = cp(idx);
T.OriginalValid = valid(idx);
T.ContiguousRecoveredCp_mps = contiguousCp(idx);
T.ContiguousRecoveredValid = contiguousValid(idx);
end

function value = valueOrNaN(x)
if isempty(x)
    value = nan;
else
    value = x;
end
end

function value = valueOrNaNFrequency(f, idx)
if isempty(idx)
    value = nan;
else
    value = f(idx)/1e3;
end
end
