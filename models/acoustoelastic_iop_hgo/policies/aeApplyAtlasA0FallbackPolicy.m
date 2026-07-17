function [result, applied] = aeApplyAtlasA0FallbackPolicy(result)
%AEAPPLYATLASA0FALLBACKPOLICY Decide the official fallback-invalidated surface.
%
% Result and quality rebuilding remain with aeBuildResult and
% aeEvaluateAtlasA0Quality. This owner changes only the already-decided
% official fields and preserves the rejected candidate evidence.

applied = false;
if ~isfield(result, 'options') || ~isfield(result.options, 'invalidateAtlasFallbackOutput') || ...
        ~logical(result.options.invalidateAtlasFallbackOutput)
    return;
end

if ~isfield(result, 'reliability') || ~isfield(result.reliability, 'SelectionFallbackUsed') || ...
        ~logical(result.reliability.SelectionFallbackUsed)
    return;
end

applied = true;
result.fallbackCandidateCp = result.Cp;
result.fallbackCandidateValidCp = result.validCp;
result.fallbackCandidateBranchExistsAtFrequency = result.branchExistsAtFrequency;
result.fallbackCandidateInterpolatedCp = result.interpolatedCp;
result.fallbackCandidatePointStatus = result.pointStatus;

result.Cp(:) = nan;
result.validCp(:) = false;
result.branchExistsAtFrequency(:) = false;
result.interpolatedCp(:) = false;
result.objective(:) = nan;
result.nearestRank(:) = nan;
result.nearestBranchID(:) = nan;
result.pointStatus(:) = "fallbackRejectedA0StartFilter";
end
