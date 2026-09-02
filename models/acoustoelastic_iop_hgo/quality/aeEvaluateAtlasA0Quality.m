function quality = aeEvaluateAtlasA0Quality(result, varargin)
%AEEVALUATEATLASA0QUALITY Summarize decided AE output on its public grid.
%
% This function does not select, reconnect, interpolate, or invalidate a
% branch. An optional existing reliability struct preserves tracking-policy
% metadata while the requested-grid counts and frequency limits are updated.

baseReliability = struct();
validityNote = "";
firstMissingAtStartWhenInvalid = false;
if nargin >= 2 && ~isempty(varargin{1})
    baseReliability = varargin{1};
end
if nargin >= 3 && ~isempty(varargin{2})
    validityNote = string(varargin{2});
end
if nargin >= 4 && ~isempty(varargin{3})
    firstMissingAtStartWhenInvalid = logical(varargin{3});
end

valid = result.validMask & isfinite(result.phaseVelocity_mps);
frequency = result.frequency_Hz;
quality = baseReliability;

if isempty(fieldnames(quality))
    quality.PolicyName = string(result.options.atlasBranchPolicy);
end
quality.TotalPoints = numel(result.phaseVelocity_mps);
quality.ValidPoints = nnz(valid);
quality.MissingPoints = nnz(~valid);
quality.ValidFraction = nnz(valid) / max(numel(result.phaseVelocity_mps), 1);
quality.InterpolatedPoints = nnz(result.interpolatedCp);
quality.ExplicitBranchPoints = nnz(result.branchExistsAtFrequency);

if ~isfield(quality, 'SelectedBranchID')
    quality.SelectedBranchID = result.selectedBranchID;
end

if any(valid)
    validFrequency = frequency(valid);
    quality.FirstValidFrequency_Hz = validFrequency(1);
    quality.FirstValidFrequency_kHz = validFrequency(1) / 1e3;
    quality.LastValidFrequency_Hz = validFrequency(end);
    quality.LastValidFrequency_kHz = validFrequency(end) / 1e3;
else
    quality.FirstValidFrequency_Hz = nan;
    quality.FirstValidFrequency_kHz = nan;
    quality.LastValidFrequency_Hz = nan;
    quality.LastValidFrequency_kHz = nan;
end

missingAfterStart = find(~valid & frequency >= quality.FirstValidFrequency_Hz, 1, 'first');
if isempty(missingAfterStart)
    quality.FirstMissingFrequency_Hz = nan;
    quality.FirstMissingFrequency_kHz = nan;
else
    quality.FirstMissingFrequency_Hz = frequency(missingAfterStart);
    quality.FirstMissingFrequency_kHz = frequency(missingAfterStart) / 1e3;
end
if ~any(valid) && firstMissingAtStartWhenInvalid && ~isempty(frequency)
    quality.FirstMissingFrequency_Hz = frequency(1);
    quality.FirstMissingFrequency_kHz = frequency(1) / 1e3;
end

if ~isfield(quality, 'A0StartFilterPassed')
    if ~isempty(result.selectedBranch)
        quality.A0StartFilterPassed = logical(result.selectedBranch.A0StartFilterPassed);
        quality.SelectionFallbackUsed = logical(result.selectedBranch.SelectionFallbackUsed);
        quality.YStart = result.selectedBranch.YStart;
        quality.StartRank = result.selectedBranch.StartRank;
        quality.CpStart_mps = result.selectedBranch.CpStart_mps;
        quality.MaxBranchRelativeCpDrop = result.selectedBranch.MaxRelativeCpDrop;
    else
        quality.A0StartFilterPassed = false;
        quality.SelectionFallbackUsed = false;
        quality.YStart = nan;
        quality.StartRank = nan;
        quality.CpStart_mps = nan;
        quality.MaxBranchRelativeCpDrop = nan;
    end
end

if strlength(validityNote) == 0
    validityNote = "Cp is considered reliable only where validCp is true; high-frequency NaNs mean the selected atlasA0 branch is not explicitly traceable under the current atlas criteria.";
end
quality.ValidityNote = validityNote;
end
