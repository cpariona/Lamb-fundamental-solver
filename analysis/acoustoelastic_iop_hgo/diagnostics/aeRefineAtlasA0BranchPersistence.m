function refinement = aeRefineAtlasA0BranchPersistence(result, varargin)
%AEREFINEATLASA0BRANCHPERSISTENCE Create a separate diagnostic continuation.
%
%   This function does not edit the maintained atlasA0 fields. It returns a
%   separate CpCandidate vector for inspection.

analysis = aeAnalyzeBranchPersistenceCandidates(result, varargin{:});
classification = classifyPersistence(analysis.summary);

candidateCp = result.Cp(:);
candidateValid = logical(result.validCp(:)) & isfinite(candidateCp);
candidateMode = repmat("official_missing", size(candidateCp));
candidateMode(candidateValid) = "official_atlasA0";

T = analysis.candidateTable;
if ~isempty(T)
    accept = logical(T.PersistenceCandidateAccepted);
    for i = find(accept(:)).'
        k = T.Index(i);
        if k >= 1 && k <= numel(candidateCp)
            candidateCp(k) = T.ContiguousRecoveredCp_mps(i);
            candidateValid(k) = isfinite(candidateCp(k));
            candidateMode(k) = "diagnostic_branch_persistence";
        end
    end
end

refinement = struct();
refinement.options = analysis.options;
refinement.analysis = analysis;
refinement.classification = classification;
refinement.CpCandidate = reshape(candidateCp, size(result.Cp));
refinement.validCandidate = reshape(candidateValid, size(result.Cp));
refinement.candidateMode = reshape(candidateMode, size(result.Cp));
refinement.summary = buildSummary(result, refinement);
end

function decision = classifyPersistence(summary)
numContiguous = getField(summary, 'NumContiguousPersistenceCandidates', 0);
extension = getField(summary, 'PersistenceExtension_kHz', 0);
medianRank = getField(summary, 'MedianAcceptedCandidateRank', nan);
numAfterBreak = getField(summary, 'NumPointwiseCandidatesAfterContiguousBreak', 0);
strongCount = getField(summary, 'NumStrongAcceptedCandidates', 0);
weakCount = getField(summary, 'NumLowRankOrWeakAcceptedCandidates', 0);

if numContiguous == 0 || ~isfinite(extension) || extension <= 0
    cls = "not_recommended";
    conf = "high";
    useText = "Keep maintained atlasA0 output unchanged.";
elseif numContiguous < 3 || extension < 5 || numAfterBreak > 0
    cls = "weak_partial_extension";
    conf = "medium";
    useText = "Partial diagnostic continuation.";
elseif weakCount > 0 || (isfinite(medianRank) && medianRank > 3)
    cls = "caution_low_rank_branch";
    conf = "medium";
    useText = "Use as diagnostic evidence only.";
elseif strongCount >= numContiguous
    cls = "accepted_contiguous_extension";
    conf = "medium";
    useText = "Locally coherent diagnostic continuation.";
else
    cls = "weak_partial_extension";
    conf = "low";
    useText = "Mixed diagnostic evidence.";
end

decision = struct();
decision.DecisionClass = cls;
decision.DecisionConfidence = conf;
decision.RecommendedUse = useText;
decision.NumContiguousPersistenceCandidates = numContiguous;
decision.PersistenceExtension_kHz = extension;
decision.MedianAcceptedCandidateRank = medianRank;
decision.NumStrongAcceptedCandidates = strongCount;
decision.NumLowRankOrWeakAcceptedCandidates = weakCount;
decision.NumPointwiseCandidatesAfterContiguousBreak = numAfterBreak;
decision.PolicyNote = "Diagnostic classification only; atlasA0 remains maintained.";
end

function summary = buildSummary(result, refinement)
officialValid = logical(result.validCp(:)) & isfinite(result.Cp(:));
candidateValid = logical(refinement.validCandidate(:)) & isfinite(refinement.CpCandidate(:));
summary = refinement.analysis.summary;
summary.Classification = refinement.classification.DecisionClass;
summary.DecisionConfidence = refinement.classification.DecisionConfidence;
summary.RecommendedUse = refinement.classification.RecommendedUse;
summary.OfficialValidPoints = nnz(officialValid);
summary.CandidateValidPoints = nnz(candidateValid);
summary.AddedCandidatePoints = nnz(candidateValid & ~officialValid);
summary.OfficialCpPreserved = true;
summary.Note = "CpCandidate is diagnostic only; maintained atlasA0 fields are unchanged.";
end

function value = getField(s, name, defaultValue)
if isstruct(s) && isfield(s, name)
    value = s.(name);
else
    value = defaultValue;
end
end
