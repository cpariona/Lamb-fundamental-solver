function decision = aeClassifyThresholdRelaxedBranchDecision(relaxedComparisonSummary, relaxedQualitySummary, varargin)
%AECLASSIFYTHRESHOLDRELAXEDBRANCHDECISION Classify diagnostic usefulness of relaxed branch.
%
%   decision = aeClassifyThresholdRelaxedBranchDecision(relaxedComparisonSummary, relaxedQualitySummary)
%
%   Produces a compact diagnostic decision for the threshold-relaxed branch.
%   This does not alter atlasA0 or any maintained solver output.

opts = parseOptions(varargin{:});

addedPoints = getField(relaxedComparisonSummary, 'AddedByRelaxedPoints', 0);
relaxedClass = string(getField(relaxedComparisonSummary, 'RelaxedBranchClass', "unknown"));
qualityClass = string(getField(relaxedQualitySummary, 'RelaxedQualityClass', "unknown"));
strongPoints = getField(relaxedQualitySummary, 'StrongMinimumPoints', 0);
acceptablePoints = getField(relaxedQualitySummary, 'AcceptableMinimumPoints', 0);
weakPoints = getField(relaxedQualitySummary, 'WeakOrCrowdedMinimumPoints', 0);
lowRankPoints = getField(relaxedQualitySummary, 'LowRankMinimumPoints', 0);
unmatchedPoints = getField(relaxedQualitySummary, 'UnmatchedMinimumPoints', 0);
medianRank = getField(relaxedQualitySummary, 'MedianAddedMinRank', nan);
lastOfficial = getField(relaxedComparisonSummary, 'LastOfficialValidFrequency_kHz', nan);
lastRelaxed = getField(relaxedComparisonSummary, 'LastRelaxedValidFrequency_kHz', nan);
relaxedThreshold = getField(relaxedComparisonSummary, 'RelaxedThreshold', nan);

if addedPoints <= 0
    decisionClass = "not_recommended";
    confidence = "high";
    interpretation = "The threshold-relaxed branch does not add points beyond the official atlasA0 branch.";
    recommendation = "Keep atlasA0; no relaxed diagnostic branch is useful for this case.";
elseif unmatchedPoints > 0
    decisionClass = "not_recommended";
    confidence = "medium";
    interpretation = "At least one relaxed addition cannot be matched to a stored local minimum.";
    recommendation = "Do not use the relaxed branch except for manual inspection of the bridge or unmatched point.";
elseif relaxedClass ~= "extends_official_branch"
    decisionClass = "weak_partial_extension";
    confidence = "medium";
    interpretation = "The relaxed branch adds points but does not clearly extend the official contiguous frequency range.";
    recommendation = "Keep the branch as an internal diagnostic only.";
elseif lowRankPoints == 0 && weakPoints == 0 && addedPoints >= opts.MinPointsForUsableBranch
    decisionClass = "usable_diagnostic_branch";
    confidence = "medium";
    interpretation = "The relaxed branch extends atlasA0 and all added points are acceptable or strong minima.";
    recommendation = "Use as a diagnostic branch for interpretation plots; do not replace atlasA0 without a separate validation step.";
elseif addedPoints >= opts.MinPointsForCautionBranch && medianRank <= opts.MaxMedianRankForCaution
    decisionClass = "caution_low_rank_branch";
    confidence = "medium";
    interpretation = "The relaxed branch gives a useful extension, but several added points are low-rank or crowded minima.";
    recommendation = "Use only as a cautionary diagnostic branch and inspect residual landscapes before relying on it.";
else
    decisionClass = "weak_partial_extension";
    confidence = "medium";
    interpretation = "The relaxed branch only gives a weak or low-quality extension.";
    recommendation = "Keep as diagnostic evidence only; do not use for quantitative conclusions.";
end

decision = struct();
decision.DecisionClass = string(decisionClass);
decision.DecisionConfidence = string(confidence);
decision.Interpretation = string(interpretation);
decision.RecommendedUse = string(recommendation);
decision.RelaxedThreshold = relaxedThreshold;
decision.AddedByRelaxedPoints = addedPoints;
decision.LastOfficialValidFrequency_kHz = lastOfficial;
decision.LastRelaxedValidFrequency_kHz = lastRelaxed;
decision.RelaxedBranchClass = relaxedClass;
decision.RelaxedQualityClass = qualityClass;
decision.StrongMinimumPoints = strongPoints;
decision.AcceptableMinimumPoints = acceptablePoints;
decision.WeakOrCrowdedMinimumPoints = weakPoints;
decision.LowRankMinimumPoints = lowRankPoints;
decision.UnmatchedMinimumPoints = unmatchedPoints;
decision.MedianAddedMinRank = medianRank;
decision.Extension_kHz = lastRelaxed - lastOfficial;
end

function opts = parseOptions(varargin)
opts = struct();
opts.MinPointsForUsableBranch = 3;
opts.MinPointsForCautionBranch = 3;
opts.MaxMedianRankForCaution = 12;
if mod(numel(varargin), 2) ~= 0
    error('Options must be supplied as name-value pairs.');
end
for i = 1:2:numel(varargin)
    name = lower(string(varargin{i}));
    value = varargin{i+1};
    switch name
        case "minpointsforusablebranch"
            opts.MinPointsForUsableBranch = value;
        case "minpointsforcautionbranch"
            opts.MinPointsForCautionBranch = value;
        case "maxmedianrankforcaution"
            opts.MaxMedianRankForCaution = value;
        otherwise
            error('Unknown aeClassifyThresholdRelaxedBranchDecision option: %s', name);
    end
end
end

function value = getField(s, name, defaultValue)
if isfield(s, name)
    value = s.(name);
else
    value = defaultValue;
end
end
