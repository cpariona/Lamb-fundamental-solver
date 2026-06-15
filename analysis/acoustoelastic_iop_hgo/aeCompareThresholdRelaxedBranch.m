function comparison = aeCompareThresholdRelaxedBranch(result, varargin)
%AECOMPARETHRESHOLDRELAXEDBRANCH Compare atlasA0 with a diagnostic relaxed branch.
%
%   comparison = aeCompareThresholdRelaxedBranch(result)
%
%   Builds a diagnostic branch from contiguous truncation recovery using a
%   relaxed MaxRelativeCpDistance threshold. The maintained atlasA0 output is
%   not modified. The relaxed branch is intended for debugging only.

opts = parseOptions(varargin{:});
recovery = aeAnalyzeTruncationRecovery(result, ...
    'MaxRelativeCpDistance', opts.MaxRelativeCpDistance, ...
    'MaxRelativeBridgeMismatch', opts.MaxRelativeBridgeMismatch, ...
    'MaxGapPoints', opts.MaxGapPoints, ...
    'MaxGapFrequencyRatio', opts.MaxGapFrequencyRatio, ...
    'MinimaFrequencyTolerance_Hz', opts.MinimaFrequencyTolerance_Hz);

f = result.frequency(:);
officialCp = result.Cp(:);
officialValid = logical(result.validCp(:)) & isfinite(officialCp);
relaxedCp = recovery.contiguousRecoveredCp(:);
relaxedValid = recovery.contiguousRecoveredValid(:);
addedByRelaxed = relaxedValid & ~officialValid;
sharedValid = relaxedValid & officialValid;

T = table();
T.Index = (1:numel(f)).';
T.Frequency_kHz = f/1e3;
T.OfficialCp_mps = officialCp;
T.OfficialValid = officialValid;
T.RelaxedCp_mps = relaxedCp;
T.RelaxedValid = relaxedValid;
T.AddedByRelaxed = addedByRelaxed;
T.RelaxedRecoveryMode = recovery.contiguousRecoveryMode(:);
T.RelaxedRecoveryConfidence = recovery.contiguousRecoveryConfidence(:);
T.CpDifference_mps = relaxedCp - officialCp;
T.RelativeCpDifference = abs(T.CpDifference_mps) ./ max(abs(officialCp), eps);
T.RelativeCpDifference(~sharedValid) = nan;

comparison = struct();
comparison.options = opts;
comparison.recovery = recovery;
comparison.comparisonTable = T;
comparison.summary = buildSummary(T, opts);
end

function opts = parseOptions(varargin)
opts = struct();
opts.MaxRelativeCpDistance = 0.15;
opts.MaxRelativeBridgeMismatch = 0.03;
opts.MaxGapPoints = 2;
opts.MaxGapFrequencyRatio = 1.12;
opts.MinimaFrequencyTolerance_Hz = 1e-6;
if mod(numel(varargin), 2) ~= 0
    error('Options must be supplied as name-value pairs.');
end
for i = 1:2:numel(varargin)
    name = lower(string(varargin{i}));
    value = varargin{i+1};
    switch name
        case "maxrelativecpdistance"
            opts.MaxRelativeCpDistance = value;
        case "maxrelativebridgemismatch"
            opts.MaxRelativeBridgeMismatch = value;
        case "maxgappoints"
            opts.MaxGapPoints = value;
        case "maxgapfrequencyratio"
            opts.MaxGapFrequencyRatio = value;
        case "minimafrequencytolerance_hz"
            opts.MinimaFrequencyTolerance_Hz = value;
        otherwise
            error('Unknown aeCompareThresholdRelaxedBranch option: %s', name);
    end
end
end

function summary = buildSummary(T, opts)
summary = struct();
summary.RelaxedThreshold = opts.MaxRelativeCpDistance;
summary.TotalPoints = height(T);
summary.OfficialValidPoints = nnz(T.OfficialValid);
summary.RelaxedValidPoints = nnz(T.RelaxedValid);
summary.AddedByRelaxedPoints = nnz(T.AddedByRelaxed);
summary.OfficialValidFraction = summary.OfficialValidPoints / max(height(T), 1);
summary.RelaxedValidFraction = summary.RelaxedValidPoints / max(height(T), 1);
summary.AddedByRelaxedFraction = summary.AddedByRelaxedPoints / max(height(T), 1);
summary.FirstAddedFrequency_kHz = firstValue(T.Frequency_kHz(T.AddedByRelaxed));
summary.LastAddedFrequency_kHz = lastValue(T.Frequency_kHz(T.AddedByRelaxed));
summary.LastOfficialValidFrequency_kHz = lastValue(T.Frequency_kHz(T.OfficialValid));
summary.LastRelaxedValidFrequency_kHz = lastValue(T.Frequency_kHz(T.RelaxedValid));
summary.MaxSharedRelativeCpDifference = maxOrNaN(T.RelativeCpDifference(T.OfficialValid & T.RelaxedValid));
summary.NumLocalMinimumAdditions = nnz(T.AddedByRelaxed & T.RelaxedRecoveryMode == "localMinimumNearPreviousCp");
summary.NumSmallGapBridgeAdditions = nnz(T.AddedByRelaxed & T.RelaxedRecoveryMode == "smallGapBridge");
if summary.AddedByRelaxedPoints == 0
    summary.RelaxedBranchClass = "no_extension";
    summary.Interpretation = "The relaxed threshold does not add any contiguous points beyond the official atlasA0 branch.";
elseif isnan(summary.LastOfficialValidFrequency_kHz) || summary.LastRelaxedValidFrequency_kHz > summary.LastOfficialValidFrequency_kHz
    summary.RelaxedBranchClass = "extends_official_branch";
    summary.Interpretation = "The relaxed threshold extends the contiguous diagnostic branch beyond the official atlasA0 truncation.";
else
    summary.RelaxedBranchClass = "fills_internal_gaps";
    summary.Interpretation = "The relaxed threshold adds points but does not extend the final contiguous frequency beyond the official branch.";
end
summary.Interpretation = string(summary.Interpretation);
end

function value = firstValue(x)
if isempty(x)
    value = nan;
else
    value = x(1);
end
end

function value = lastValue(x)
if isempty(x)
    value = nan;
else
    value = x(end);
end
end

function value = maxOrNaN(x)
if isempty(x)
    value = nan;
else
    value = max(x);
end
end
