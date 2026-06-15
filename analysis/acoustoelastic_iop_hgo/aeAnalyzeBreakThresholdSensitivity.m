function sensitivity = aeAnalyzeBreakThresholdSensitivity(result, varargin)
%AEANALYZEBREAKTHRESHOLDSENSITIVITY Test diagnostic recovery sensitivity to Cp thresholds.
%
% This diagnostic runs aeAnalyzeTruncationRecovery for several
% MaxRelativeCpDistance values. It is diagnostic only and does not alter
% atlasA0 or any maintained branch policy.

opts = parseOptions(varargin{:});
thresholds = opts.RelativeCpDistanceValues(:);
rows = [];
recoveryByThreshold = struct();
truncationSummary = buildTruncationSummaryFromResult(result);

for i = 1:numel(thresholds)
    threshold = thresholds(i);
    recovery = aeAnalyzeTruncationRecovery(result, ...
        'MaxRelativeCpDistance', threshold, ...
        'MaxRelativeBridgeMismatch', opts.MaxRelativeBridgeMismatch, ...
        'MaxGapPoints', opts.MaxGapPoints, ...
        'MaxGapFrequencyRatio', opts.MaxGapFrequencyRatio, ...
        'MinimaFrequencyTolerance_Hz', opts.MinimaFrequencyTolerance_Hz);
    firstBreak = aeAnalyzeFirstUnrecoveredBreak(result, recovery, ...
        'MaxRelativeCpDistance', threshold, ...
        'NearMissRelativeCpDistance', opts.NearMissRelativeCpDistance, ...
        'MinimaFrequencyTolerance_Hz', opts.MinimaFrequencyTolerance_Hz, ...
        'WindowPoints', opts.WindowPoints);
    classification = aeClassifyTruncationRecovery(truncationSummary, recovery.summary);

    row = struct();
    row.RelativeCpDistanceThreshold = threshold;
    row.RecoveredValidFraction = recovery.summary.RecoveredValidFraction;
    row.NumRecoveredPoints = recovery.summary.NumRecoveredPoints;
    row.ContiguousRecoveredValidFraction = recovery.summary.ContiguousRecoveredValidFraction;
    row.NumContiguousRecoveredPoints = recovery.summary.NumContiguousRecoveredPoints;
    row.FirstMissingAfterContiguousRecovery_kHz = recovery.summary.FirstMissingAfterContiguousRecovery_kHz;
    row.LastContiguousRecoveredFrequency_kHz = recovery.summary.LastContiguousRecoveredFrequency_kHz;
    row.NumPointwiseRecoveriesAfterContiguousBreak = recovery.summary.NumPointwiseRecoveriesAfterContiguousBreak;
    row.RecoveryClass = classification.RecoveryClass;
    row.InitialBreakRecovered = classification.InitialBreakRecovered;
    row.ContiguousExtension_kHz = classification.ContiguousExtension_kHz;
    row.FirstUnrecoveredBreakClass = firstBreak.summary.BreakClass;
    row.FirstUnrecoveredBreakFrequency_kHz = firstBreak.summary.BreakFrequency_kHz;
    row.FirstUnrecoveredBreakNearestRelativeDistance = firstBreak.summary.NearestRelativeDistanceToPreviousCp;
    row.FirstUnrecoveredBreakRelativeDistanceMargin = firstBreak.summary.RelativeDistanceMargin;
    rows = [rows; row]; %#ok<AGROW>

    key = matlab.lang.makeValidName(sprintf('relCp_%0.3f', threshold));
    recoveryByThreshold.(key).threshold = threshold;
    recoveryByThreshold.(key).recovery = recovery;
    recoveryByThreshold.(key).firstUnrecoveredBreak = firstBreak;
    recoveryByThreshold.(key).classification = classification;
end

if isempty(rows)
    sensitivityTable = table();
else
    sensitivityTable = struct2table(rows);
end

sensitivity = struct();
sensitivity.options = opts;
sensitivity.sensitivityTable = sensitivityTable;
sensitivity.recoveryByThreshold = recoveryByThreshold;
sensitivity.summary = buildSensitivitySummary(sensitivityTable);
end

function opts = parseOptions(varargin)
opts = struct();
opts.RelativeCpDistanceValues = [0.08 0.10 0.12 0.15];
opts.MaxRelativeBridgeMismatch = 0.03;
opts.MaxGapPoints = 2;
opts.MaxGapFrequencyRatio = 1.12;
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
        case "relativecpdistancevalues"
            opts.RelativeCpDistanceValues = value;
        case "maxrelativebridgemismatch"
            opts.MaxRelativeBridgeMismatch = value;
        case "maxgappoints"
            opts.MaxGapPoints = value;
        case "maxgapfrequencyratio"
            opts.MaxGapFrequencyRatio = value;
        case "nearmissrelativecpdistance"
            opts.NearMissRelativeCpDistance = value;
        case "minimafrequencytolerance_hz"
            opts.MinimaFrequencyTolerance_Hz = value;
        case "windowpoints"
            opts.WindowPoints = value;
        otherwise
            error('Unknown aeAnalyzeBreakThresholdSensitivity option: %s', name);
    end
end
end

function summary = buildTruncationSummaryFromResult(result)
f = result.frequency(:);
cp = result.Cp(:);
valid = logical(result.validCp(:)) & isfinite(cp);
summary = struct();
summary.TotalPoints = numel(valid);
summary.ValidPoints = nnz(valid);
summary.MissingPoints = nnz(~valid);
summary.ValidFraction = nnz(valid)/max(numel(valid), 1);
firstMissing = find(~valid, 1, 'first');
if isempty(firstMissing)
    summary.FirstMissingFrequency_kHz = nan;
else
    summary.FirstMissingFrequency_kHz = f(firstMissing)/1e3;
end
lastValid = find(valid, 1, 'last');
if isempty(lastValid)
    summary.LastValidFrequency_kHz = nan;
else
    summary.LastValidFrequency_kHz = f(lastValid)/1e3;
end
lastBefore = find(valid & (1:numel(valid)).' < firstMissing, 1, 'last');
if isempty(lastBefore)
    summary.LastValidBeforeFirstMissingFrequency_kHz = nan;
else
    summary.LastValidBeforeFirstMissingFrequency_kHz = f(lastBefore)/1e3;
end
end

function summary = buildSensitivitySummary(T)
summary = struct();
summary.ThresholdForInitialBreakRecovery = nan;
summary.ThresholdForFullContiguousRecovery = nan;
summary.MaxContiguousExtension_kHz = nan;
summary.MaxLastContiguousRecoveredFrequency_kHz = nan;
summary.BestThresholdByContiguousExtension = nan;
summary.NumThresholds = height(T);
summary.Interpretation = "No threshold sensitivity data available.";
if isempty(T), return; end
idxInitial = find(T.InitialBreakRecovered, 1, 'first');
if ~isempty(idxInitial)
    summary.ThresholdForInitialBreakRecovery = T.RelativeCpDistanceThreshold(idxInitial);
end
idxFull = find(T.RecoveryClass == "fully_contiguous_recovered", 1, 'first');
if ~isempty(idxFull)
    summary.ThresholdForFullContiguousRecovery = T.RelativeCpDistanceThreshold(idxFull);
end
[summary.MaxContiguousExtension_kHz, idxBest] = max(T.ContiguousExtension_kHz);
summary.MaxLastContiguousRecoveredFrequency_kHz = T.LastContiguousRecoveredFrequency_kHz(idxBest);
summary.BestThresholdByContiguousExtension = T.RelativeCpDistanceThreshold(idxBest);
if isfinite(summary.ThresholdForInitialBreakRecovery)
    summary.Interpretation = string(sprintf('The first break becomes recoverable at MaxRelativeCpDistance = %.3g.', summary.ThresholdForInitialBreakRecovery));
else
    summary.Interpretation = "The first break is not recovered for any tested MaxRelativeCpDistance value.";
end
end
