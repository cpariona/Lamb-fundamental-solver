clear; clc;
if isempty(which('mrlfeSolve'))
    configureTestPath;
end

%TEST_ACOUSTOELASTIC_IOP_HGO_BRANCH_PERSISTENCE_REFINEMENT
% Lightweight synthetic test for diagnostic branch-persistence refinement.

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

refinement = aeRefineAtlasA0BranchPersistence(result, ...
    'MaxRelativeCpJump', 0.15, ...
    'MaxRelativeBridgeMismatch', 0.03, ...
    'MaxGapPoints', 0, ...
    'MaxGapFrequencyRatio', 1.12, ...
    'MaxCandidateRank', 12, ...
    'StrongCandidateRank', 3);

assert(isequaln(result.phaseVelocity_mps, [10 11 12 nan nan nan]), ...
    'The maintained result.Cp must remain unchanged.');

assert(isfield(refinement, 'CpCandidate'), ...
    'Missing CpCandidate output.');

assert(isfield(refinement, 'classification'), ...
    'Missing classification output.');

assert(nnz(refinement.validCandidate & ~result.validMask) >= 1, ...
    'Expected at least one diagnostic candidate point.');

expectedClasses = ["caution_low_rank_branch","weak_partial_extension","accepted_contiguous_extension"];
assert(any(refinement.classification.DecisionClass == expectedClasses), ...
    'Unexpected branch-persistence classification.');

fprintf('test_acoustoelastic_iop_hgo_branch_persistence_refinement passed.\n');

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
