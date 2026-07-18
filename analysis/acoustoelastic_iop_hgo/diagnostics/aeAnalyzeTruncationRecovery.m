function recovery = aeAnalyzeTruncationRecovery(result, varargin)
%AEANALYZETRUNCATIONRECOVERY Diagnose whether missing atlasA0 points are recoverable.
%
%   recovery = aeAnalyzeTruncationRecovery(result)
%
%   This helper does not change the maintained atlasA0 result. It evaluates
%   diagnostic recoverability of missing Cp samples using two conservative
%   ideas:
%
%   1. local-minimum recovery: a minimum at the missing frequency is accepted
%      only if it is close to the previous valid Cp;
%   2. gap bridging: a missing point is marked bridgeable if a nearby valid
%      point after the gap is consistent with the previous valid Cp.
%
%   Two recovery levels are reported:
%
%   - pointwise recovery: each missing point is tested against the nearest
%     original valid neighbors;
%   - contiguous recovery: recovery is propagated sequentially from the first
%     valid point and stops at the first unrecovered gap.
%
%   The output is intended for diagnostics, not for replacing atlasA0.

opts = parseOptions(varargin{:});
f = result.frequency(:);
cp = result.Cp(:);
valid = logical(result.validCp(:)) & isfinite(cp);

[recoveredCp, recoveryMode, recoveryConfidence, selectedMinRank, selectedMinObjective, selectedMinBranchID, rows] = ...
    buildPointwiseRecovery(result, f, cp, valid, opts);
recoveredValid = valid | isfinite(recoveredCp);

[contiguousRecoveredCp, contiguousRecoveredValid, contiguousRecoveryMode, contiguousRecoveryConfidence] = ...
    buildContiguousRecovery(result, f, cp, valid, opts);

recovery = struct();
recovery.options = opts;
recovery.recoveredCp = recoveredCp;
recovery.recoveredValid = recoveredValid;
recovery.recoveryMode = recoveryMode;
recovery.recoveryConfidence = recoveryConfidence;
recovery.selectedMinRank = selectedMinRank;
recovery.selectedMinObjective = selectedMinObjective;
recovery.selectedMinBranchID = selectedMinBranchID;
recovery.contiguousRecoveredCp = contiguousRecoveredCp;
recovery.contiguousRecoveredValid = contiguousRecoveredValid;
recovery.contiguousRecoveryMode = contiguousRecoveryMode;
recovery.contiguousRecoveryConfidence = contiguousRecoveryConfidence;
if isempty(rows)
    recovery.recoveryTable = table();
else
    recovery.recoveryTable = struct2table(rows);
    recovery.recoveryTable.ContiguousRecovered = contiguousRecoveredValid(recovery.recoveryTable.Index);
    recovery.recoveryTable.ContiguousRecoveryMode = contiguousRecoveryMode(recovery.recoveryTable.Index);
    recovery.recoveryTable.ContiguousRecoveredCp_mps = contiguousRecoveredCp(recovery.recoveryTable.Index);
    recovery.recoveryTable.ContiguousRecoveryConfidence = contiguousRecoveryConfidence(recovery.recoveryTable.Index);
end
recovery.summary = buildRecoverySummary(valid, recoveredValid, recoveryMode, contiguousRecoveredValid, contiguousRecoveryMode, recovery.recoveryTable, f);
end

function opts = parseOptions(varargin)
opts = struct();
opts.MaxRelativeCpDistance = 0.08;
opts.MaxAbsoluteCpDistance_mps = inf;
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
        case "maxabsolutecpdistance_mps"
            opts.MaxAbsoluteCpDistance_mps = value;
        case "maxrelativebridgemismatch"
            opts.MaxRelativeBridgeMismatch = value;
        case "maxgappoints"
            opts.MaxGapPoints = value;
        case "maxgapfrequencyratio"
            opts.MaxGapFrequencyRatio = value;
        case "minimafrequencytolerance_hz"
            opts.MinimaFrequencyTolerance_Hz = value;
        otherwise
            error('Unknown aeAnalyzeTruncationRecovery option: %s', name);
    end
end
end

function [recoveredCp, recoveryMode, recoveryConfidence, selectedMinRank, selectedMinObjective, selectedMinBranchID, rows] = ...
    buildPointwiseRecovery(result, f, cp, valid, opts)
recoveredCp = cp;
recoveryMode = repmat("originalMissing", size(cp));
recoveryMode(valid) = "originalValid";
recoveryConfidence = nan(size(cp));
selectedMinRank = nan(size(cp));
selectedMinObjective = nan(size(cp));
selectedMinBranchID = nan(size(cp));

rows = [];
missingIdx = find(~valid);
for ii = 1:numel(missingIdx)
    k = missingIdx(ii);
    left = find(valid & (1:numel(valid)).' < k, 1, 'last');
    right = find(valid & (1:numel(valid)).' > k, 1, 'first');
    prevCp = nan; nextCp = nan;
    if ~isempty(left), prevCp = cp(left); end
    if ~isempty(right), nextCp = cp(right); end

    [localCp, localRank, localObj, localBranchID, localRelDist] = chooseLocalMinimum(result, f(k), prevCp, opts);
    [bridgeCp, bridgeRelMismatch, bridgePoints] = chooseGapBridge(f, cp, valid, k, left, right, opts);

    accepted = false;
    mode = "notRecovered";
    candidateCp = nan;
    confidence = nan;

    if isfinite(localCp) && localRelDist <= opts.MaxRelativeCpDistance
        accepted = true;
        mode = "localMinimumNearPreviousCp";
        candidateCp = localCp;
        confidence = 1 - localRelDist/opts.MaxRelativeCpDistance;
        selectedMinRank(k) = localRank;
        selectedMinObjective(k) = localObj;
        selectedMinBranchID(k) = localBranchID;
    elseif isfinite(bridgeCp) && bridgeRelMismatch <= opts.MaxRelativeBridgeMismatch
        accepted = true;
        mode = "smallGapBridge";
        candidateCp = bridgeCp;
        confidence = 1 - bridgeRelMismatch/opts.MaxRelativeBridgeMismatch;
    end

    if accepted
        recoveredCp(k) = candidateCp;
        recoveryMode(k) = mode;
        recoveryConfidence(k) = confidence;
    else
        recoveryMode(k) = mode;
    end

    row = struct();
    row.Index = k;
    row.Frequency_kHz = f(k)/1e3;
    row.PreviousValidCp_mps = prevCp;
    row.NextValidCp_mps = nextCp;
    row.LocalCandidateCp_mps = localCp;
    row.LocalCandidateRank = localRank;
    row.LocalCandidateObjective = localObj;
    row.LocalRelativeDistance = localRelDist;
    row.BridgeCandidateCp_mps = bridgeCp;
    row.BridgeRelativeMismatch = bridgeRelMismatch;
    row.BridgePoints = bridgePoints;
    row.Recovered = accepted;
    row.RecoveryMode = mode;
    row.RecoveredCp_mps = recoveredCp(k);
    row.RecoveryConfidence = recoveryConfidence(k);
    rows = [rows; row]; %#ok<AGROW>
end
end

function [contiguousCp, contiguousValid, contiguousMode, contiguousConfidence] = buildContiguousRecovery(result, f, cp, valid, opts)
contiguousCp = nan(size(cp));
contiguousValid = false(size(cp));
contiguousMode = repmat("notReachedAfterContiguousBreak", size(cp));
contiguousConfidence = nan(size(cp));

firstValid = find(valid, 1, 'first');
if isempty(firstValid)
    return;
end

contiguousCp(firstValid) = cp(firstValid);
contiguousValid(firstValid) = true;
contiguousMode(firstValid) = "originalValid";
lastCp = cp(firstValid);

for k = firstValid+1:numel(cp)
    if valid(k)
        contiguousCp(k) = cp(k);
        contiguousValid(k) = true;
        contiguousMode(k) = "originalValid";
        lastCp = cp(k);
        continue;
    end

    [localCp, ~, ~, ~, localRelDist] = chooseLocalMinimum(result, f(k), lastCp, opts);
    [bridgeCp, bridgeRelMismatch] = chooseContiguousGapBridge(f, cp, valid, k, lastCp, opts);

    if isfinite(localCp) && localRelDist <= opts.MaxRelativeCpDistance
        contiguousCp(k) = localCp;
        contiguousValid(k) = true;
        contiguousMode(k) = "localMinimumNearPreviousCp";
        contiguousConfidence(k) = 1 - localRelDist/opts.MaxRelativeCpDistance;
        lastCp = localCp;
    elseif isfinite(bridgeCp) && bridgeRelMismatch <= opts.MaxRelativeBridgeMismatch
        contiguousCp(k) = bridgeCp;
        contiguousValid(k) = true;
        contiguousMode(k) = "smallGapBridge";
        contiguousConfidence(k) = 1 - bridgeRelMismatch/opts.MaxRelativeBridgeMismatch;
        lastCp = bridgeCp;
    else
        contiguousMode(k) = "firstUnrecoveredContiguousBreak";
        return;
    end
end
end

function [candidateCp, candidateRank, candidateObj, candidateBranchID, relDist] = chooseLocalMinimum(result, f0, prevCp, opts)
candidateCp = nan; candidateRank = nan; candidateObj = nan; candidateBranchID = nan; relDist = inf;
if ~isfinite(prevCp) || ~isfield(result, 'minimaTable') || isempty(result.minimaTable)
    return;
end
M = result.minimaTable;
idx = abs(M.Frequency_Hz - f0) <= opts.MinimaFrequencyTolerance_Hz * max(abs(f0), 1);
Mf = M(idx, :);
if isempty(Mf), return; end
absDist = abs(Mf.Cp_mps - prevCp);
rel = absDist ./ max(abs(prevCp), eps);
allowed = absDist <= opts.MaxAbsoluteCpDistance_mps | rel <= opts.MaxRelativeCpDistance;
if ~any(allowed), return; end
Mf = Mf(allowed, :);
rel = rel(allowed);
[~, j] = min(rel);
candidateCp = Mf.Cp_mps(j);
candidateRank = Mf.MinRank(j);
candidateObj = Mf.Objective(j);
if ismember('BranchID', Mf.Properties.VariableNames)
    candidateBranchID = Mf.BranchID(j);
end
relDist = rel(j);
end

function [bridgeCp, relMismatch, gapPoints] = chooseGapBridge(f, cp, valid, k, left, right, opts)
bridgeCp = nan; relMismatch = inf; gapPoints = nan;
if isempty(left) || isempty(right), return; end
gapPoints = right - left - 1;
if gapPoints < 1 || gapPoints > opts.MaxGapPoints, return; end
if f(right) / max(f(left), eps) > opts.MaxGapFrequencyRatio, return; end
relMismatch = abs(cp(right) - cp(left)) / max(abs(cp(left)), eps);
if relMismatch > opts.MaxRelativeBridgeMismatch, return; end
bridgeCp = interp1([f(left), f(right)], [cp(left), cp(right)], f(k), 'linear');
end

function [bridgeCp, relMismatch, gapPoints] = chooseContiguousGapBridge(f, cp, valid, k, lastCp, opts)
bridgeCp = nan; relMismatch = inf; gapPoints = nan;
right = find(valid & (1:numel(valid)).' > k, 1, 'first');
if isempty(right), return; end
gapPoints = right - k;
if gapPoints < 1 || gapPoints > opts.MaxGapPoints, return; end
if f(right) / max(f(k), eps) > opts.MaxGapFrequencyRatio, return; end
relMismatch = abs(cp(right) - lastCp) / max(abs(lastCp), eps);
if relMismatch > opts.MaxRelativeBridgeMismatch, return; end
bridgeCp = interp1([f(k-1), f(right)], [lastCp, cp(right)], f(k), 'linear');
end

function summary = buildRecoverySummary(originalValid, recoveredValid, recoveryMode, contiguousRecoveredValid, contiguousRecoveryMode, recoveryTable, f)
summary = struct();
summary.TotalPoints = numel(originalValid);
summary.OriginalValidPoints = nnz(originalValid);
summary.OriginalValidFraction = nnz(originalValid)/max(numel(originalValid),1);
summary.RecoveredValidPoints = nnz(recoveredValid);
summary.RecoveredValidFraction = nnz(recoveredValid)/max(numel(recoveredValid),1);
summary.NumRecoveredPoints = nnz(recoveredValid & ~originalValid);
summary.ContiguousRecoveredValidPoints = nnz(contiguousRecoveredValid);
summary.ContiguousRecoveredValidFraction = nnz(contiguousRecoveredValid)/max(numel(contiguousRecoveredValid),1);
summary.NumContiguousRecoveredPoints = nnz(contiguousRecoveredValid & ~originalValid);
summary.NumContiguousLocalMinimumRecoveries = nnz(contiguousRecoveryMode == "localMinimumNearPreviousCp");
summary.NumContiguousSmallGapBridgeRecoveries = nnz(contiguousRecoveryMode == "smallGapBridge");
summary.NumPointwiseRecoveriesAfterContiguousBreak = nnz((recoveredValid & ~originalValid) & ~contiguousRecoveredValid);
if isempty(recoveryTable)
    summary.NumLocalMinimumRecoveries = 0;
    summary.NumSmallGapBridgeRecoveries = 0;
else
    summary.NumLocalMinimumRecoveries = nnz(recoveryTable.RecoveryMode == "localMinimumNearPreviousCp");
    summary.NumSmallGapBridgeRecoveries = nnz(recoveryTable.RecoveryMode == "smallGapBridge");
end
if any(recoveredValid)
    summary.LastRecoveredValidFrequency_kHz = f(find(recoveredValid, 1, 'last'))/1e3;
else
    summary.LastRecoveredValidFrequency_kHz = nan;
end
if any(contiguousRecoveredValid)
    summary.LastContiguousRecoveredFrequency_kHz = f(find(contiguousRecoveredValid, 1, 'last'))/1e3;
else
    summary.LastContiguousRecoveredFrequency_kHz = nan;
end
firstRecovered = find(recoveredValid, 1, 'first');
if isempty(firstRecovered)
    summary.FirstMissingAfterRecovery_kHz = nan;
else
    firstMissingAfterRecovery = find(~recoveredValid & f >= f(firstRecovered), 1, 'first');
    if isempty(firstMissingAfterRecovery)
        summary.FirstMissingAfterRecovery_kHz = nan;
    else
        summary.FirstMissingAfterRecovery_kHz = f(firstMissingAfterRecovery)/1e3;
    end
end
firstContiguous = find(contiguousRecoveredValid, 1, 'first');
if isempty(firstContiguous)
    summary.FirstMissingAfterContiguousRecovery_kHz = nan;
else
    firstMissingAfterContiguous = find(~contiguousRecoveredValid & f >= f(firstContiguous), 1, 'first');
    if isempty(firstMissingAfterContiguous)
        summary.FirstMissingAfterContiguousRecovery_kHz = nan;
    else
        summary.FirstMissingAfterContiguousRecovery_kHz = f(firstMissingAfterContiguous)/1e3;
    end
end
summary.ContiguousRecoveryNote = "Contiguous recovery is propagated sequentially from the first valid point and stops at the first unrecovered gap; pointwise recoveries after that gap are not counted as continuous branch recovery.";
end
