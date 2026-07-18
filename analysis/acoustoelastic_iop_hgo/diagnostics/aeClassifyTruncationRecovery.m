function classification = aeClassifyTruncationRecovery(truncationSummary, recoverySummary)
%AECLASSIFYTRUNCATIONRECOVERY Classify diagnostic recovery of atlasA0 truncations.
%
%   classification = aeClassifyTruncationRecovery(truncationSummary, recoverySummary)
%
%   This helper converts truncation and recovery summary metrics into a compact
%   interpretation. It does not alter Cp values or the maintained atlasA0 output.
%
%   Classes:
%     no_truncation
%     fully_contiguous_recovered
%     partially_contiguous_recovered
%     pointwise_only_after_break
%     not_recovered

classification = struct();

firstMissing = getFieldOrNaN(truncationSummary, 'FirstMissingFrequency_kHz');
lastOriginal = getFieldOrNaN(truncationSummary, 'LastValidFrequency_kHz');
lastBeforeFirstMissing = getFieldOrNaN(truncationSummary, 'LastValidBeforeFirstMissingFrequency_kHz');
validFraction = getFieldOrNaN(truncationSummary, 'ValidFraction');

numPointwise = getFieldOrNaN(recoverySummary, 'NumRecoveredPoints');
numContiguous = getFieldOrNaN(recoverySummary, 'NumContiguousRecoveredPoints');
numAfterBreak = getFieldOrNaN(recoverySummary, 'NumPointwiseRecoveriesAfterContiguousBreak');
firstMissingContiguous = getFieldOrNaN(recoverySummary, 'FirstMissingAfterContiguousRecovery_kHz');
lastContiguous = getFieldOrNaN(recoverySummary, 'LastContiguousRecoveredFrequency_kHz');
contiguousFraction = getFieldOrNaN(recoverySummary, 'ContiguousRecoveredValidFraction');

classification.FirstMissingFrequency_kHz = firstMissing;
classification.LastOriginalValidFrequency_kHz = lastOriginal;
classification.LastValidBeforeFirstMissingFrequency_kHz = lastBeforeFirstMissing;
classification.LastContiguousRecoveredFrequency_kHz = lastContiguous;
classification.FirstMissingAfterContiguousRecovery_kHz = firstMissingContiguous;
classification.OriginalValidFraction = validFraction;
classification.ContiguousRecoveredValidFraction = contiguousFraction;
classification.NumPointwiseRecoveredPoints = numPointwise;
classification.NumContiguousRecoveredPoints = numContiguous;
classification.NumPointwiseRecoveriesAfterContiguousBreak = numAfterBreak;

if ~isfinite(firstMissing)
    classification.RecoveryClass = "no_truncation";
    classification.InitialBreakRecovered = false;
    classification.ContiguousExtension_kHz = 0;
    classification.PointwiseOnly = false;
    classification.Interpretation = "No missing point was detected in the maintained atlasA0 branch.";
    return;
end

if isfinite(lastBeforeFirstMissing) && isfinite(lastContiguous)
    classification.ContiguousExtension_kHz = max(0, lastContiguous - lastBeforeFirstMissing);
else
    classification.ContiguousExtension_kHz = 0;
end

classification.InitialBreakRecovered = isfinite(lastContiguous) && lastContiguous >= firstMissing;
classification.PointwiseOnly = numPointwise > 0 && numContiguous == 0;

if classification.InitialBreakRecovered && ~isfinite(firstMissingContiguous)
    classification.RecoveryClass = "fully_contiguous_recovered";
    classification.Interpretation = "The diagnostic recovery propagates continuously through all missing atlasA0 points without leaving a remaining contiguous break.";
elseif classification.InitialBreakRecovered && isfinite(firstMissingContiguous) && firstMissingContiguous > firstMissing
    classification.RecoveryClass = "partially_contiguous_recovered";
    classification.Interpretation = "The first atlasA0 break is recovered and the branch is extended continuously, but a later unrecovered break remains.";
elseif numPointwise > 0 && numContiguous == 0
    classification.RecoveryClass = "pointwise_only_after_break";
    classification.Interpretation = "Pointwise minima are found after the break, but the first atlasA0 break is not recovered; this should not be interpreted as continuous branch recovery.";
elseif numPointwise > 0 && numAfterBreak > 0 && ~classification.InitialBreakRecovered
    classification.RecoveryClass = "pointwise_only_after_break";
    classification.Interpretation = "Pointwise minima are found after an unresolved contiguous break; they are diagnostic candidates only.";
else
    classification.RecoveryClass = "not_recovered";
    classification.Interpretation = "The diagnostic recovery does not recover the first atlasA0 break under the current conservative continuity criteria.";
end
end

function value = getFieldOrNaN(s, name)
if isfield(s, name)
    value = s.(name);
else
    value = nan;
end
end
