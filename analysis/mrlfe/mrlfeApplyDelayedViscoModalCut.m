function [branch, cutSummary] = mrlfeApplyDelayedViscoModalCut(branch, options)
%MRLFEAPPLYDELAYEDVISCOMODALCUT Apply delayed post-start modal cut to a direct-visco branch.
%
% The acoustoelastic atlas-A0 workflow separates branch identity from the first
% requested output frequency and reports untraceable low-frequency points as
% missing instead of using them as the branch anchor. This helper applies the
% same conservative idea to direct viscous mRLFE atlas diagnostics:
%
%   1. allow an initial missing region;
%   2. wait for a stable valid run;
%   3. only then cut the tail on missing candidates, residual failure, or large
%      phase-speed jumps.
%
% This function is diagnostic infrastructure only. It does not change the
% maintained mRLFE route.

if nargin < 2 || isempty(options)
    options = struct();
end

cutSummary = emptyCutSummary();
if ~isstruct(branch) || ~isfield(branch, 'Cp')
    return;
end

Cp = branch.Cp(:);
n = numel(Cp);
frequency = getVectorField(branch, 'frequency', n, (1:n).');
residual = getVectorField(branch, 'residual', n, nan(n, 1));
validCandidate = isfinite(Cp) & Cp > 0;
if isfield(branch, 'candidateIndex')
    candidateIndex = branch.candidateIndex(:);
    if numel(candidateIndex) == n
        validCandidate = validCandidate & isfinite(candidateIndex);
    end
end
if isfield(branch, 'validCp')
    validCandidate = validCandidate & logical(branch.validCp(:));
elseif isfield(branch, 'valid')
    validCandidate = validCandidate & logical(branch.valid(:));
end

residualTolerance = getOption(options, 'mrlfeDelayedCutResidualTolerance', getOption(options, 'mrlfeResidualTolerance', inf));
validByResidual = true(n, 1);
if isfinite(residualTolerance)
    validByResidual = isfinite(residual) & residual <= residualTolerance;
end
candidateOk = validCandidate & validByResidual;

minValidRun = getOption(options, 'mrlfeDelayedCutMinValidRun', 8);
minValidRun = max(1, round(minValidRun));
firstStableStart = findFirstStableRun(candidateOk, minValidRun);
cutSummary.InitialMissingPoints = nnz(~candidateOk(1:max(firstStableStart-1, 0)));
cutSummary.MinValidRun = minValidRun;
cutSummary.ResidualTolerance = residualTolerance;

if isempty(firstStableStart)
    branch = invalidateFrom(branch, 1, "no_stable_valid_run");
    cutSummary.FirstStableStartIndex = nan;
    cutSummary.FirstStableStartFrequency = nan;
    cutSummary.FirstCutIndex = 1;
    cutSummary.FirstCutFrequency = frequency(1);
    cutSummary.CutReason = "no_stable_valid_run";
    return;
end

cutSummary.FirstStableStartIndex = firstStableStart;
cutSummary.FirstStableStartFrequency = frequency(firstStableStart);

firstAfterStable = firstStableStart + minValidRun;
firstCut = [];
reason = "none";

stopOnMissing = getOption(options, 'mrlfeDelayedCutStopAtFirstMissingAfterValidRun', true);
if stopOnMissing && firstAfterStable <= n
    missingAfterStable = find(~candidateOk(firstAfterStable:end), 1, 'first');
    if ~isempty(missingAfterStable)
        firstCut = firstAfterStable + missingAfterStable - 1;
        reason = "missing_after_stable_valid_run";
    end
end

maxJump = getOption(options, 'mrlfeDelayedCutPreviousCpMaxRelativeJump', getOption(options, 'mrlfeViscoPreviousCpMaxRelativeJump', inf));
if isfinite(maxJump) && maxJump > 0
    jumpIdx = findFirstLargeJump(Cp, candidateOk, firstStableStart + 1, maxJump);
    if ~isempty(jumpIdx) && (isempty(firstCut) || jumpIdx < firstCut)
        firstCut = jumpIdx;
        reason = "cp_jump_after_stable_valid_run";
    end
end

if isempty(firstCut)
    branch.firstMissingModalMinimumIndex = nan;
    branch.firstMissingModalMinimumFrequency = nan;
    branch.modalCutReason = "none";
    cutSummary.FirstCutIndex = nan;
    cutSummary.FirstCutFrequency = nan;
    cutSummary.CutReason = "none";
else
    branch = invalidateFrom(branch, firstCut, reason);
    cutSummary.FirstCutIndex = firstCut;
    cutSummary.FirstCutFrequency = frequency(firstCut);
    cutSummary.CutReason = reason;
end

cutSummary.ValidPointsAfterCut = nnz(getBranchValid(branch));
branch.delayedViscoModalCut = cutSummary;
end

function idx = findFirstStableRun(mask, minRun)
idx = [];
mask = logical(mask(:));
if numel(mask) < minRun
    return;
end
runLength = 0;
for i = 1:numel(mask)
    if mask(i)
        runLength = runLength + 1;
        if runLength >= minRun
            idx = i - minRun + 1;
            return;
        end
    else
        runLength = 0;
    end
end
end

function idx = findFirstLargeJump(Cp, validMask, startIndex, maxJump)
idx = [];
Cp = Cp(:);
validMask = logical(validMask(:));
for i = max(2, startIndex):numel(Cp)
    if ~validMask(i-1) || ~validMask(i)
        continue;
    end
    relJump = abs(Cp(i) - Cp(i-1)) / max(abs(Cp(i-1)), eps);
    if relJump > maxJump
        idx = i;
        return;
    end
end
end

function branch = invalidateFrom(branch, firstCut, reason)
Cp = branch.Cp(:);
n = numel(Cp);
fieldsToNan = {'k', 'kReal', 'kImag', 'attenuation', 'Cp', 'kThickness', 'residual', 'score', 'candidateRank', 'dpPathCost'};
for i = 1:numel(fieldsToNan)
    fieldName = fieldsToNan{i};
    if isfield(branch, fieldName)
        values = branch.(fieldName);
        if numel(values) == n
            values(firstCut:end) = nan;
            branch.(fieldName) = values;
        end
    end
end
fieldsToFalse = {'validResidual', 'validReference', 'validSmooth', 'validCp', 'validAttenuation', 'valid'};
for i = 1:numel(fieldsToFalse)
    fieldName = fieldsToFalse{i};
    if isfield(branch, fieldName)
        values = branch.(fieldName);
        if numel(values) == n
            values(firstCut:end) = false;
            branch.(fieldName) = values;
        end
    end
end
if isfield(branch, 'candidateIndex') && numel(branch.candidateIndex) == n
    branch.candidateIndex(firstCut:end) = nan;
end
frequency = getVectorField(branch, 'frequency', n, (1:n).');
branch.firstMissingModalMinimumIndex = firstCut;
branch.firstMissingModalMinimumFrequency = frequency(firstCut);
branch.modalCutReason = string(reason);
end

function valid = getBranchValid(branch)
cp = branch.Cp(:);
valid = isfinite(cp) & cp > 0;
if isfield(branch, 'validCp')
    valid = valid & logical(branch.validCp(:));
elseif isfield(branch, 'valid')
    valid = valid & logical(branch.valid(:));
end
end

function x = getVectorField(s, fieldName, n, defaultValue)
x = defaultValue;
if isstruct(s) && isfield(s, fieldName)
    candidate = s.(fieldName);
    if numel(candidate) == n
        x = candidate(:);
    end
end
end

function summary = emptyCutSummary()
summary = struct();
summary.PolicyName = "delayedViscoModalCut";
summary.InitialMissingPoints = 0;
summary.MinValidRun = nan;
summary.ResidualTolerance = nan;
summary.FirstStableStartIndex = nan;
summary.FirstStableStartFrequency = nan;
summary.FirstCutIndex = nan;
summary.FirstCutFrequency = nan;
summary.CutReason = "none";
summary.ValidPointsAfterCut = nan;
end

function value = getOption(options, fieldName, defaultValue)
if isstruct(options) && isfield(options, fieldName) && ~isempty(options.(fieldName))
    value = options.(fieldName);
else
    value = defaultValue;
end
end
