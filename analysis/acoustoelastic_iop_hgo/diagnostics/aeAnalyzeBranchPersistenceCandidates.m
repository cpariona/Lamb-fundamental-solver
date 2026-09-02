function analysis = aeAnalyzeBranchPersistenceCandidates(result, varargin)
%AEANALYZEBRANCHPERSISTENCECANDIDATES Build diagnostic A0 persistence candidates.
%
%   This helper reuses the maintained truncation-recovery logic, then exposes
%   the first-break candidate sequence as a branch-persistence table. It is a
%   diagnostic layer only and never changes result.Cp or result.validCp.

opts = parseOptions(varargin{:});
recovery = aeAnalyzeTruncationRecovery(result, ...
    'MaxRelativeCpDistance', opts.MaxRelativeCpJump, ...
    'MaxRelativeBridgeMismatch', opts.MaxRelativeBridgeMismatch, ...
    'MaxGapPoints', opts.MaxGapPoints, ...
    'MaxGapFrequencyRatio', opts.MaxGapFrequencyRatio);

candidateTable = recovery.recoveryTable;
if ~isempty(candidateTable)
    candidateTable = enrichCandidateTable(candidateTable, opts);
end

analysis = struct();
analysis.options = opts;
analysis.recovery = recovery;
analysis.candidateTable = candidateTable;
analysis.summary = buildSummary(result, recovery, candidateTable, opts);
end

function opts = parseOptions(varargin)
opts = struct();
opts.MaxRelativeCpJump = 0.15;
opts.MaxRelativeBridgeMismatch = 0.03;
opts.MaxGapPoints = 2;
opts.MaxGapFrequencyRatio = 1.12;
opts.MaxCandidateRank = 12;
opts.StrongCandidateRank = 3;
opts.MinContiguousPointsForAccepted = 3;
opts.MinExtensionForAccepted_kHz = 5;
if mod(numel(varargin), 2) ~= 0
    error('Options must be supplied as name-value pairs.');
end
for i = 1:2:numel(varargin)
    name = lower(string(varargin{i}));
    value = varargin{i+1};
    switch name
        case 'maxrelativecpjump'
            opts.MaxRelativeCpJump = value;
        case 'maxrelativebridgemismatch'
            opts.MaxRelativeBridgeMismatch = value;
        case 'maxgappoints'
            opts.MaxGapPoints = value;
        case 'maxgapfrequencyratio'
            opts.MaxGapFrequencyRatio = value;
        case 'maxcandidaterank'
            opts.MaxCandidateRank = value;
        case 'strongcandidaterank'
            opts.StrongCandidateRank = value;
        case 'mincontiguouspointsforaccepted'
            opts.MinContiguousPointsForAccepted = value;
        case 'minextensionforaccepted_khz'
            opts.MinExtensionForAccepted_kHz = value;
        otherwise
            error('Unknown aeAnalyzeBranchPersistenceCandidates option: %s', name);
    end
end
end

function T = enrichCandidateTable(T, opts)
mode = string(T.ContiguousRecoveryMode);
T.PointwisePersistenceCandidate = logical(T.Recovered);
T.ContiguousPersistenceCandidate = logical(T.ContiguousRecovered) & mode ~= "originalValid";

hasLocalMinimum = isfinite(T.LocalCandidateRank);
T.RankAcceptable = ~hasLocalMinimum | T.LocalCandidateRank <= opts.MaxCandidateRank;
T.RankStrong = hasLocalMinimum & T.LocalCandidateRank <= opts.StrongCandidateRank;
T.RelativeCpAcceptable = isnan(T.LocalRelativeDistance) | T.LocalRelativeDistance <= opts.MaxRelativeCpJump;
T.HasFiniteCandidateCp = isfinite(T.ContiguousRecoveredCp_mps);

T.PersistenceCandidateAccepted = T.ContiguousPersistenceCandidate & ...
    T.HasFiniteCandidateCp & T.RankAcceptable & T.RelativeCpAcceptable;

T.PersistenceQuality = repmat("not_accepted", height(T), 1);
T.PersistenceQuality(T.PersistenceCandidateAccepted & T.RankStrong) = "strong";
T.PersistenceQuality(T.PersistenceCandidateAccepted & ~T.RankStrong) = "bridge_or_low_rank";
end

function summary = buildSummary(result, recovery, candidateTable, opts)
f = result.frequency_Hz(:);
cp = result.phaseVelocity_mps(:);
valid = logical(result.validMask(:)) & isfinite(cp);
summary = struct();
summary.TotalPoints = numel(valid);
summary.OriginalValidPoints = nnz(valid);
summary.OriginalValidFraction = nnz(valid) / max(numel(valid), 1);
summary.LastOfficialValidFrequency_kHz = lastFrequency(f, valid);
summary.FirstMissingFrequency_kHz = firstMissingFrequency(f, valid);
summary.RawRecoveredPoints = recovery.summary.NumRecoveredPoints;
summary.RawContiguousRecoveredPoints = recovery.summary.NumContiguousRecoveredPoints;
summary.NumPointwisePersistenceCandidates = 0;
summary.NumContiguousPersistenceCandidates = 0;
summary.LastContiguousPersistenceFrequency_kHz = nan;
summary.PersistenceExtension_kHz = 0;
summary.NumPointwiseCandidatesAfterContiguousBreak = 0;
summary.MedianAcceptedCandidateRank = nan;
summary.MaxAcceptedRelativeCpDistance = nan;
summary.NumStrongAcceptedCandidates = 0;
summary.NumLowRankOrWeakAcceptedCandidates = 0;
summary.MaxRelativeCpJump = opts.MaxRelativeCpJump;
summary.MaxCandidateRank = opts.MaxCandidateRank;
summary.StrongCandidateRank = opts.StrongCandidateRank;
summary.Note = "Diagnostic branch-persistence candidates do not replace maintained atlasA0 output.";

if isempty(candidateTable) || ~ismember('PersistenceCandidateAccepted', candidateTable.Properties.VariableNames)
    return;
end

accepted = logical(candidateTable.PersistenceCandidateAccepted);
A = candidateTable(accepted, :);
summary.NumPointwisePersistenceCandidates = nnz(logical(candidateTable.PointwisePersistenceCandidate) & accepted);
summary.NumContiguousPersistenceCandidates = height(A);
summary.NumPointwiseCandidatesAfterContiguousBreak = nnz(logical(candidateTable.PointwisePersistenceCandidate) & ~logical(candidateTable.ContiguousPersistenceCandidate));

if isempty(A)
    return;
end

summary.LastContiguousPersistenceFrequency_kHz = A.Frequency_kHz(end);
summary.PersistenceExtension_kHz = max(0, summary.LastContiguousPersistenceFrequency_kHz - summary.LastOfficialValidFrequency_kHz);
summary.MedianAcceptedCandidateRank = median(A.LocalCandidateRank, 'omitnan');
summary.MaxAcceptedRelativeCpDistance = max(A.LocalRelativeDistance, [], 'omitnan');
summary.NumStrongAcceptedCandidates = nnz(A.PersistenceQuality == "strong");
summary.NumLowRankOrWeakAcceptedCandidates = nnz(A.PersistenceQuality == "bridge_or_low_rank");
end

function fk = lastFrequency(f, mask)
idx = find(mask, 1, 'last');
if isempty(idx), fk = nan; else, fk = f(idx)/1e3; end
end

function fk = firstMissingFrequency(f, valid)
firstValid = find(valid, 1, 'first');
if isempty(firstValid), fk = nan; return; end
idx = find(~valid & f >= f(firstValid), 1, 'first');
if isempty(idx), fk = nan; else, fk = f(idx)/1e3; end
end
