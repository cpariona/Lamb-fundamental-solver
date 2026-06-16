function quality = aeAssessThresholdRelaxedBranchQuality(result, thresholdRelaxedComparison, varargin)
%AEASSESSTHRESHOLDRELAXEDBRANCHQUALITY Assess quality of threshold-relaxed additions.
%
%   quality = aeAssessThresholdRelaxedBranchQuality(result, thresholdRelaxedComparison)
%
%   Inspects only the points added by the diagnostic threshold-relaxed branch.
%   Each added point is matched against the stored minima table at the same
%   frequency and Cp. The helper reports MinRank, Objective, depth, and spacing
%   metrics where available. It is diagnostic only and does not alter atlasA0.

opts = parseOptions(varargin{:});
T = thresholdRelaxedComparison.comparisonTable;
addedIdx = find(T.AddedByRelaxed);
rows = [];

for ii = 1:numel(addedIdx)
    k = addedIdx(ii);
    fHz = result.frequency(k);
    cp = T.RelaxedCp_mps(k);
    match = findMatchingMinimum(result, fHz, cp, opts);

    row = struct();
    row.Index = k;
    row.Frequency_kHz = fHz/1e3;
    row.RelaxedCp_mps = cp;
    row.RelaxedRecoveryMode = T.RelaxedRecoveryMode(k);
    row.RelaxedRecoveryConfidence = T.RelaxedRecoveryConfidence(k);
    row.HasMatchedMinimum = match.HasMatchedMinimum;
    row.MatchedMinRank = match.MinRank;
    row.MatchedObjective = match.Objective;
    row.MatchedDepthRelativeToMedian = match.DepthRelativeToMedian;
    row.MatchedDepthRelativeToDeepest = match.DepthRelativeToDeepest;
    row.MatchedSpacingToNearestLogY = match.SpacingToNearestLogY;
    row.MatchedBranchID = match.BranchID;
    row.MatchedRelativeCpError = match.RelativeCpError;
    row.MatchedAbsoluteCpError_mps = match.AbsoluteCpError_mps;
    row.QualityClass = classifyPoint(match, opts);
    rows = [rows; row]; %#ok<AGROW>
end

if isempty(rows)
    addedQualityTable = table();
else
    addedQualityTable = struct2table(rows);
end

quality = struct();
quality.options = opts;
quality.addedQualityTable = addedQualityTable;
quality.summary = buildQualitySummary(addedQualityTable, thresholdRelaxedComparison.summary);
end

function opts = parseOptions(varargin)
opts = struct();
opts.MinimaFrequencyTolerance_Hz = 1e-6;
opts.CpMatchRelativeTolerance = 1e-6;
opts.StrongMaxRank = 3;
opts.AcceptableMaxRank = 6;
opts.StrongMaxObjective = inf;
opts.AcceptableMaxObjective = inf;
opts.StrongMinDepthRelativeToMedian = 0.5;
opts.AcceptableMinDepthRelativeToMedian = 0.1;
opts.StrongMinSpacingToNearestLogY = 0.02;
opts.AcceptableMinSpacingToNearestLogY = 0.005;
if mod(numel(varargin), 2) ~= 0
    error('Options must be supplied as name-value pairs.');
end
for i = 1:2:numel(varargin)
    name = lower(string(varargin{i}));
    value = varargin{i+1};
    switch name
        case "minimafrequencytolerance_hz"
            opts.MinimaFrequencyTolerance_Hz = value;
        case "cpmatchrelativetolerance"
            opts.CpMatchRelativeTolerance = value;
        case "strongmaxrank"
            opts.StrongMaxRank = value;
        case "acceptablemaxrank"
            opts.AcceptableMaxRank = value;
        case "strongmaxobjective"
            opts.StrongMaxObjective = value;
        case "acceptablemaxobjective"
            opts.AcceptableMaxObjective = value;
        case "strongmindepthrelativetomedian"
            opts.StrongMinDepthRelativeToMedian = value;
        case "acceptablemindepthrelativetomedian"
            opts.AcceptableMinDepthRelativeToMedian = value;
        case "strongminspacingtonearestlogy"
            opts.StrongMinSpacingToNearestLogY = value;
        case "acceptableminspacingtonearestlogy"
            opts.AcceptableMinSpacingToNearestLogY = value;
        otherwise
            error('Unknown aeAssessThresholdRelaxedBranchQuality option: %s', name);
    end
end
end

function match = findMatchingMinimum(result, fHz, cp, opts)
match = emptyMatch();
if ~isfield(result, 'minimaTable') || isempty(result.minimaTable) || ~isfinite(cp)
    return;
end
M = result.minimaTable;
idx = abs(M.Frequency_Hz - fHz) <= opts.MinimaFrequencyTolerance_Hz * max(abs(fHz), 1);
Mf = M(idx, :);
if isempty(Mf)
    return;
end
absErr = abs(Mf.Cp_mps - cp);
relErr = absErr ./ max(abs(cp), eps);
[bestRelErr, j] = min(relErr);
if bestRelErr > opts.CpMatchRelativeTolerance
    return;
end
match.HasMatchedMinimum = true;
match.MinRank = getTableValue(Mf, 'MinRank', j, nan);
match.Objective = getTableValue(Mf, 'Objective', j, nan);
match.DepthRelativeToMedian = getTableValue(Mf, 'DepthRelativeToMedian', j, nan);
match.DepthRelativeToDeepest = getTableValue(Mf, 'DepthRelativeToDeepest', j, nan);
match.SpacingToNearestLogY = getTableValue(Mf, 'SpacingToNearestLogY', j, nan);
match.BranchID = getTableValue(Mf, 'BranchID', j, nan);
match.RelativeCpError = bestRelErr;
match.AbsoluteCpError_mps = absErr(j);
end

function match = emptyMatch()
match = struct();
match.HasMatchedMinimum = false;
match.MinRank = nan;
match.Objective = nan;
match.DepthRelativeToMedian = nan;
match.DepthRelativeToDeepest = nan;
match.SpacingToNearestLogY = nan;
match.BranchID = nan;
match.RelativeCpError = nan;
match.AbsoluteCpError_mps = nan;
end

function value = getTableValue(T, name, idx, defaultValue)
if ismember(name, T.Properties.VariableNames)
    value = T.(name)(idx);
else
    value = defaultValue;
end
end

function cls = classifyPoint(match, opts)
if ~match.HasMatchedMinimum
    cls = "unmatched_minimum";
    return;
end
rankStrong = isfinite(match.MinRank) && match.MinRank <= opts.StrongMaxRank;
rankAcceptable = isfinite(match.MinRank) && match.MinRank <= opts.AcceptableMaxRank;
objectiveStrong = ~isfinite(match.Objective) || match.Objective <= opts.StrongMaxObjective;
objectiveAcceptable = ~isfinite(match.Objective) || match.Objective <= opts.AcceptableMaxObjective;
depthStrong = ~isfinite(match.DepthRelativeToMedian) || match.DepthRelativeToMedian >= opts.StrongMinDepthRelativeToMedian;
depthAcceptable = ~isfinite(match.DepthRelativeToMedian) || match.DepthRelativeToMedian >= opts.AcceptableMinDepthRelativeToMedian;
spacingStrong = ~isfinite(match.SpacingToNearestLogY) || match.SpacingToNearestLogY >= opts.StrongMinSpacingToNearestLogY;
spacingAcceptable = ~isfinite(match.SpacingToNearestLogY) || match.SpacingToNearestLogY >= opts.AcceptableMinSpacingToNearestLogY;

if rankStrong && objectiveStrong && depthStrong && spacingStrong
    cls = "strong_minimum";
elseif rankAcceptable && objectiveAcceptable && depthAcceptable && spacingAcceptable
    cls = "acceptable_minimum";
elseif rankAcceptable
    cls = "weak_or_crowded_minimum";
else
    cls = "low_rank_minimum";
end
end

function summary = buildQualitySummary(T, relaxedSummary)
summary = struct();
summary.RelaxedThreshold = relaxedSummary.RelaxedThreshold;
summary.RelaxedBranchClass = relaxedSummary.RelaxedBranchClass;
summary.AddedByRelaxedPoints = relaxedSummary.AddedByRelaxedPoints;
summary.AddedQualityRows = height(T);
summary.MatchedMinimumPoints = 0;
summary.UnmatchedMinimumPoints = 0;
summary.StrongMinimumPoints = 0;
summary.AcceptableMinimumPoints = 0;
summary.WeakOrCrowdedMinimumPoints = 0;
summary.LowRankMinimumPoints = 0;
summary.MedianAddedMinRank = nan;
summary.MedianAddedObjective = nan;
summary.MedianAddedDepthRelativeToMedian = nan;
summary.MedianAddedSpacingToNearestLogY = nan;
summary.RelaxedQualityClass = "no_added_points";
summary.Interpretation = "The relaxed branch adds no points beyond the official atlasA0 branch.";

if isempty(T)
    return;
end
summary.MatchedMinimumPoints = nnz(T.HasMatchedMinimum);
summary.UnmatchedMinimumPoints = nnz(~T.HasMatchedMinimum);
summary.StrongMinimumPoints = nnz(T.QualityClass == "strong_minimum");
summary.AcceptableMinimumPoints = nnz(T.QualityClass == "acceptable_minimum");
summary.WeakOrCrowdedMinimumPoints = nnz(T.QualityClass == "weak_or_crowded_minimum");
summary.LowRankMinimumPoints = nnz(T.QualityClass == "low_rank_minimum");
summary.MedianAddedMinRank = medianOrNaN(T.MatchedMinRank);
summary.MedianAddedObjective = medianOrNaN(T.MatchedObjective);
summary.MedianAddedDepthRelativeToMedian = medianOrNaN(T.MatchedDepthRelativeToMedian);
summary.MedianAddedSpacingToNearestLogY = medianOrNaN(T.MatchedSpacingToNearestLogY);

if summary.UnmatchedMinimumPoints > 0
    summary.RelaxedQualityClass = "unmatched_additions";
    summary.Interpretation = "At least one relaxed addition could not be matched to a stored local minimum.";
elseif summary.StrongMinimumPoints == height(T)
    summary.RelaxedQualityClass = "all_strong_minima";
    summary.Interpretation = "All relaxed additions are matched to strong local minima under the current diagnostic criteria.";
elseif summary.StrongMinimumPoints + summary.AcceptableMinimumPoints == height(T)
    summary.RelaxedQualityClass = "all_acceptable_minima";
    summary.Interpretation = "All relaxed additions are matched to acceptable or strong local minima.";
elseif summary.LowRankMinimumPoints > 0
    summary.RelaxedQualityClass = "contains_low_rank_minima";
    summary.Interpretation = "Some relaxed additions rely on low-rank local minima and require manual inspection.";
else
    summary.RelaxedQualityClass = "contains_weak_or_crowded_minima";
    summary.Interpretation = "Some relaxed additions are matched to weak or crowded minima and require manual inspection.";
end
summary.Interpretation = string(summary.Interpretation);
end

function value = medianOrNaN(x)
x = x(isfinite(x));
if isempty(x)
    value = nan;
else
    value = median(x);
end
end
