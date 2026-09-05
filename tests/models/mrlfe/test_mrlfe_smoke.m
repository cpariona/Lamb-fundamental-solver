function test_mrlfe_smoke()
% Smoke test for both maintained public mRLFE branches.
params = rlDefaultParams();
frequency_Hz = linspace(500, 4000, 18).';

a0 = solveBranch(params, frequency_Hz, "A0Like");
s0 = solveBranch(params, frequency_Hz, "S0Like");

for result = {a0, s0}
    current = result{1};
    assert(current.model == "mrlfe", 'Public result must identify mRLFE.');
    assert(numel(current.frequency_Hz) == numel(frequency_Hz), ...
        'Public frequency length mismatch.');
    assert(any(current.validMask), 'Branch must contain at least one valid point.');
    assert(all(current.phaseVelocity_mps(current.validMask) > 0), ...
        'Valid phase velocities must be positive.');
    assert(current.fallback.policy == "none" && ~current.fallback.applied, ...
        'Public mRLFE smoke route must not use fallback.');
end

fprintf('test_mrlfe_smoke passed. A0Like valid: %d/%d. S0Like valid: %d/%d.\n', ...
    nnz(a0.validMask), numel(a0.validMask), nnz(s0.validMask), numel(s0.validMask));
end

function result = solveBranch(params, frequency_Hz, branchName)
options = mrlfeDefaultSweepOptions(branchName, 'EtaS', 0);
request = mrlfeBuildSolveRequest(params, frequency_Hz, branchName, options);
result = mrlfeSolve(request);
end
