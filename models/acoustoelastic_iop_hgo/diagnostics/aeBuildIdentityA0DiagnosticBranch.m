function identity = aeBuildIdentityA0DiagnosticBranch(result, varargin)
%AEBUILDIDENTITYA0DIAGNOSTICBRANCH Build a separate identity-scored A0 candidate branch.
%
% The candidate branch starts from the official atlasA0 output and fills only
% missing frequencies where aeScoreBranchIdentityCandidates finds a strong or
% caution candidate. It never modifies the official result.

score = aeScoreBranchIdentityCandidates(result, varargin{:});

f = result.frequency_Hz(:);
officialCp = result.phaseVelocity_mps(:);
officialValid = logical(result.validMask(:));

CpCandidate = officialCp;
validCandidate = officialValid;
addedFromIdentityScore = false(size(officialValid));
branchIdentityScore = nan(size(officialCp));
candidateRank = nan(size(officialCp));
candidateClass = repmat("official_atlasA0", size(officialCp));
candidateSource = repmat("official_atlasA0", size(officialCp));

T = score.candidateTable;
if ~isempty(T)
    B = T(logical(T.IsBestAtFrequency), :);
    for i = 1:height(B)
        k = B.Index(i);
        if k < 1 || k > numel(CpCandidate)
            continue;
        end
        cls = string(B.ScoreClass(i));
        acceptable = cls == "strong_diagnostic_candidate" || cls == "caution_diagnostic_candidate";
        if ~officialValid(k) && acceptable
            CpCandidate(k) = B.CandidateCp_mps(i);
            validCandidate(k) = true;
            addedFromIdentityScore(k) = true;
            branchIdentityScore(k) = B.BranchIdentityScore(i);
            candidateRank(k) = B.CandidateRank(i);
            candidateClass(k) = cls;
            candidateSource(k) = string(B.CandidateSource(i));
        elseif officialValid(k)
            branchIdentityScore(k) = B.BranchIdentityScore(i);
            candidateRank(k) = B.CandidateRank(i);
        end
    end
end

identity = struct();
identity.policyName = "identityA0Diagnostic";
identity.officialPolicyEquivalent = "atlasA0";
identity.note = "Diagnostic only. Canonical phaseVelocity_mps and validMask remain the official atlasA0 output.";
identity.frequency = f;
identity.CpCandidate = CpCandidate;
identity.validCandidate = validCandidate;
identity.addedFromIdentityScore = addedFromIdentityScore;
identity.branchIdentityScore = branchIdentityScore;
identity.candidateRank = candidateRank;
identity.candidateClass = candidateClass;
identity.candidateSource = candidateSource;
identity.score = score;
identity.summary = summarizeIdentityBranch(f, officialValid, validCandidate, addedFromIdentityScore, branchIdentityScore, candidateRank);
end

function summary = summarizeIdentityBranch(f, officialValid, validCandidate, added, score, rank)
summary = struct();
summary.TotalPoints = numel(f);
summary.OfficialValidPoints = nnz(officialValid);
summary.CandidateValidPoints = nnz(validCandidate);
summary.AddedCandidatePoints = nnz(added);
summary.OfficialValidFraction = nnz(officialValid) / max(numel(f), 1);
summary.CandidateValidFraction = nnz(validCandidate) / max(numel(f), 1);
summary.FirstOfficialMissingFrequency_kHz = firstMissingAfterStart(f, officialValid);
summary.FirstCandidateMissingFrequency_kHz = firstMissingAfterStart(f, validCandidate);
summary.LastOfficialValidFrequency_kHz = lastValidFrequency(f, officialValid);
summary.LastCandidateValidFrequency_kHz = lastValidFrequency(f, validCandidate);
summary.MedianAddedScore = median(score(added), 'omitnan');
summary.MedianAddedRank = median(rank(added), 'omitnan');
summary.ValidityNote = "Candidate branch is diagnostic. Use for inspection and validation, not as official dispersion output.";
end

function value = firstMissingAfterStart(f, valid)
firstValid = find(valid, 1, 'first');
value = nan;
if isempty(firstValid)
    return;
end
idx = find(~valid & (1:numel(valid)).' >= firstValid, 1, 'first');
if ~isempty(idx)
    value = f(idx) / 1e3;
end
end

function value = lastValidFrequency(f, valid)
idx = find(valid, 1, 'last');
if isempty(idx)
    value = nan;
else
    value = f(idx) / 1e3;
end
end
