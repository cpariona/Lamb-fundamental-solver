function reliability = aeEvaluateAtlasA0Quality(result, varargin)
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

valid = result.validCp & isfinite(result.Cp);
frequency = result.frequency;
reliability = baseReliability;

if isempty(fieldnames(reliability))
    reliability.PolicyName = string(result.options.atlasBranchPolicy);
end
reliability.TotalPoints = numel(result.Cp);
reliability.ValidPoints = nnz(valid);
reliability.MissingPoints = nnz(~valid);
reliability.ValidFraction = nnz(valid) / max(numel(result.Cp), 1);
reliability.InterpolatedPoints = nnz(result.interpolatedCp);
reliability.ExplicitBranchPoints = nnz(result.branchExistsAtFrequency);

if ~isfield(reliability, 'SelectedBranchID')
    reliability.SelectedBranchID = result.selectedBranchID;
end

if any(valid)
    validFrequency = frequency(valid);
    reliability.FirstValidFrequency_Hz = validFrequency(1);
    reliability.FirstValidFrequency_kHz = validFrequency(1) / 1e3;
    reliability.LastValidFrequency_Hz = validFrequency(end);
    reliability.LastValidFrequency_kHz = validFrequency(end) / 1e3;
else
    reliability.FirstValidFrequency_Hz = nan;
    reliability.FirstValidFrequency_kHz = nan;
    reliability.LastValidFrequency_Hz = nan;
    reliability.LastValidFrequency_kHz = nan;
end

missingAfterStart = find(~valid & frequency >= reliability.FirstValidFrequency_Hz, 1, 'first');
if isempty(missingAfterStart)
    reliability.FirstMissingFrequency_Hz = nan;
    reliability.FirstMissingFrequency_kHz = nan;
else
    reliability.FirstMissingFrequency_Hz = frequency(missingAfterStart);
    reliability.FirstMissingFrequency_kHz = frequency(missingAfterStart) / 1e3;
end
if ~any(valid) && firstMissingAtStartWhenInvalid && ~isempty(frequency)
    reliability.FirstMissingFrequency_Hz = frequency(1);
    reliability.FirstMissingFrequency_kHz = frequency(1) / 1e3;
end

if ~isfield(reliability, 'A0StartFilterPassed')
    if ~isempty(result.selectedBranch)
        reliability.A0StartFilterPassed = logical(result.selectedBranch.A0StartFilterPassed);
        reliability.SelectionFallbackUsed = logical(result.selectedBranch.SelectionFallbackUsed);
        reliability.YStart = result.selectedBranch.YStart;
        reliability.StartRank = result.selectedBranch.StartRank;
        reliability.CpStart_mps = result.selectedBranch.CpStart_mps;
        reliability.MaxBranchRelativeCpDrop = result.selectedBranch.MaxRelativeCpDrop;
    else
        reliability.A0StartFilterPassed = false;
        reliability.SelectionFallbackUsed = false;
        reliability.YStart = nan;
        reliability.StartRank = nan;
        reliability.CpStart_mps = nan;
        reliability.MaxBranchRelativeCpDrop = nan;
    end
end

if strlength(validityNote) == 0
    validityNote = "Cp is considered reliable only where validCp is true; high-frequency NaNs mean the selected atlasA0 branch is not explicitly traceable under the current atlas criteria.";
end
reliability.ValidityNote = validityNote;
end
