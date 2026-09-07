function quality = aeEvaluateAtlasA0Quality(result, varargin)
%AEEVALUATEATLASA0QUALITY Summarize decided AE output on its public grid.
%
% This function does not select, reconnect, interpolate, or invalidate a
% branch. An optional existing quality struct preserves tracking-policy
% metadata while requested-grid counts and frequency limits are updated.

baseQuality = struct();
validityNote = "";
firstMissingAtStartWhenInvalid = false;
if nargin >= 2 && ~isempty(varargin{1})
    baseQuality = varargin{1};
end
if nargin >= 3 && ~isempty(varargin{2})
    validityNote = string(varargin{2});
end
if nargin >= 4 && ~isempty(varargin{3})
    firstMissingAtStartWhenInvalid = logical(varargin{3});
end

valid = logical(result.validMask(:)) & isfinite(result.phaseVelocity_mps(:));
frequency = result.frequency_Hz(:);
quality = baseQuality;

if isempty(fieldnames(quality))
    quality.policyName = string(result.options.atlasBranchPolicy);
end
quality.pointCount = numel(result.phaseVelocity_mps);
quality.validCount = nnz(valid);
quality.missingCount = nnz(~valid);
quality.validFraction = quality.validCount / max(quality.pointCount, 1);
quality.interpolatedCount = nnz(result.interpolatedCp);
quality.explicitBranchCount = nnz(result.branchExistsAtFrequency);

if ~isfield(quality, 'selectedBranchID')
    quality.selectedBranchID = result.selectedBranchID;
end

if any(valid)
    validFrequency = frequency(valid);
    quality.firstValidFrequency_Hz = validFrequency(1);
    quality.firstValidFrequency_kHz = validFrequency(1) / 1e3;
    quality.lastValidFrequency_Hz = validFrequency(end);
    quality.lastValidFrequency_kHz = validFrequency(end) / 1e3;
else
    quality.firstValidFrequency_Hz = nan;
    quality.firstValidFrequency_kHz = nan;
    quality.lastValidFrequency_Hz = nan;
    quality.lastValidFrequency_kHz = nan;
end

missingAfterStart = find(~valid & frequency >= quality.firstValidFrequency_Hz, 1, 'first');
if isempty(missingAfterStart)
    quality.firstMissingFrequency_Hz = nan;
    quality.firstMissingFrequency_kHz = nan;
else
    quality.firstMissingFrequency_Hz = frequency(missingAfterStart);
    quality.firstMissingFrequency_kHz = frequency(missingAfterStart) / 1e3;
end
if ~any(valid) && firstMissingAtStartWhenInvalid && ~isempty(frequency)
    quality.firstMissingFrequency_Hz = frequency(1);
    quality.firstMissingFrequency_kHz = frequency(1) / 1e3;
end

if ~isfield(quality, 'a0StartFilterPassed')
    if ~isempty(result.selectedBranch)
        quality.a0StartFilterPassed = logical(result.selectedBranch.A0StartFilterPassed);
        quality.selectionFallbackUsed = logical(result.selectedBranch.SelectionFallbackUsed);
        quality.yStart = result.selectedBranch.YStart;
        quality.startRank = result.selectedBranch.StartRank;
        quality.cpStart_mps = result.selectedBranch.CpStart_mps;
        quality.maxBranchRelativeCpDrop = result.selectedBranch.MaxRelativeCpDrop;
    else
        quality.a0StartFilterPassed = false;
        quality.selectionFallbackUsed = false;
        quality.yStart = nan;
        quality.startRank = nan;
        quality.cpStart_mps = nan;
        quality.maxBranchRelativeCpDrop = nan;
    end
end

quality.accepted = quality.validCount > 0;
if quality.accepted
    if quality.selectionFallbackUsed
        quality.reason = "accepted_with_selection_fallback";
    else
        quality.reason = "accepted";
    end
else
    quality.reason = "no_valid_points";
end

if strlength(validityNote) == 0
    validityNote = "Cp is considered reliable only where validMask is true; high-frequency NaNs mean the selected atlasA0 branch is not explicitly traceable under the current atlas criteria.";
end
quality.validityNote = validityNote;
end
