function refinement = aeRefineAtlasA0BranchPersistence(result, varargin)
%AEREFINEATLASA0BRANCHPERSISTENCE Create a separate diagnostic continuation.
%
%   This function does not edit the maintained atlasA0 fields. It returns a
%   separate CpCandidate vector for inspection.

analysis = aeAnalyzeBranchPersistenceCandidates(result, varargin{:});
classification = aeClassifyBranchPersistenceRefinement(analysis.summary, analysis.candidateTable);

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
