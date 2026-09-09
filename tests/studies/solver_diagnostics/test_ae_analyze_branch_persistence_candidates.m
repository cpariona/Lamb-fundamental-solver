function test_ae_analyze_branch_persistence_candidates()
%TEST_AE_ANALYZE_BRANCH_PERSISTENCE_CANDIDATES Protect reusable evidence.

result = struct();
result.frequency_Hz = (1:6) * 1e3;
result.phaseVelocity_mps = [10 11 12 nan nan nan];
result.validMask = [true true true false false false];
result.cShear = 100;

rows = [];
rows = addMin(rows, 4e3, 12.5, 4, 1.0);
rows = addMin(rows, 5e3, 13.0, 4, 1.1);
rows = addMin(rows, 6e3, 20.0, 1, 0.5);
result.minimaTable = struct2table(rows);
source = result;

analysis = aeAnalyzeBranchPersistenceCandidates(result, ...
    'MaxRelativeCpJump', 0.15, ...
    'MaxRelativeBridgeMismatch', 0.03, ...
    'MaxGapPoints', 0, ...
    'MaxGapFrequencyRatio', 1.12, ...
    'MaxCandidateRank', 12, ...
    'StrongCandidateRank', 3);

assert(isequaln(result, source), ...
    'Persistence analysis must leave the official atlasA0 result unchanged.');
assert(~isempty(analysis.candidateTable), ...
    'Expected diagnostic candidate evidence.');
assert(nnz(analysis.candidateTable.PersistenceCandidateAccepted) >= 1, ...
    'Expected at least one accepted diagnostic persistence candidate.');
assert(nnz(analysis.candidateTable.ContiguousPersistenceCandidate) >= 1, ...
    'Expected explicit contiguous branch evidence.');
assert(analysis.summary.NumContiguousPersistenceCandidates >= 1, ...
    'The summary must retain accepted branch-continuity evidence.');
assert(contains(analysis.summary.Note, "do not replace maintained atlasA0"), ...
    'The diagnostic output must state its production-isolation contract.');
assert(~any(isfield(analysis, {'phaseVelocity_mps', 'validMask', 'branch'})), ...
    'Persistence analysis must not construct an alternate production branch.');

fprintf('test_ae_analyze_branch_persistence_candidates passed.\n');
end

function rows = addMin(rows, f, cp, rank, obj)
row = struct();
row.Frequency_Hz = f;
row.Frequency_kHz = f / 1e3;
row.MinRank = rank;
row.Cp_mps = cp;
row.y = cp / 100;
row.log10y = log10(row.y);
row.Objective = obj;
row.DepthRelativeToMedian = 1;
row.DepthRelativeToDeepest = 0;
row.SpacingToNearestLogY = 0.1;
row.BranchID = rank;
rows = [rows; row]; %#ok<AGROW>
end
