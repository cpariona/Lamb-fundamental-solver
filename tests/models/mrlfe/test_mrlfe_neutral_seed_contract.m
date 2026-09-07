function test_mrlfe_neutral_seed_contract()
%TEST_MRLFE_NEUTRAL_SEED_CONTRACT Validate the neutral seed contract.

fprintf('\nRunning mRLFE neutral seed contract test...\n');
fprintf('------------------------------------------\n');

for branch = ["A0Like" "S0Like"]
    configuration = lamb.models.mrlfe.configuration.mrlfeResolveConfiguration(localRequest(branch, 0.05, "fast"));
    problem = lamb.models.mrlfe.core.mrlfeBuildProblem(configuration);
    seed = lamb.models.mrlfe.tracking.mrlfeBuildSeed(problem, configuration);

    assert(isfield(seed, 'frequency'), 'Seed must expose frequency.');
    assert(isfield(seed, 'Cp'), 'Seed must expose Cp.');
    assert(isfield(seed, 'k'), 'Seed must expose k.');
    assert(isfield(seed, 'valid'), 'Seed must expose validity.');
    assert(isfield(seed, 'family'), 'Seed must expose branch family.');
    assert(isfield(seed, 'seedSource'), 'Seed must expose seed source metadata.');
    assert(isequal(seed.frequency(:), problem.frequencySolve_Hz(:)), ...
        'Seed frequency must match the solve grid.');
    assert(all(isfinite(seed.Cp(seed.valid)) & seed.Cp(seed.valid) > 0), ...
        'Valid seed points must have positive finite Cp.');
    assert(string(seed.family) == branch, 'Seed branch family changed.');
end

fprintf('mRLFE neutral seed contract test passed.\n');
end

function request = localRequest(branch, etaS, preset)
request = struct();
request.branch = string(branch);
request.frequency_Hz = linspace(1000, 12000, 20).';
request.material = struct('mu_Pa', 75e3, 'etaS_Pas', etaS, 'rho_kgm3', 1000, 'nu', 0.4999);
request.geometry = struct('thickness_m', 0.5e-3);
request.fluid = struct('density_kgm3', 1000, 'soundSpeed_mps', 1500);
request.numerics = struct('preset', string(preset));
request.selection = struct('strategy', "adaptive");
if branch == "A0Like"
    request.termination = struct('policy', "physicalTail");
else
    request.termination = struct('policy', "none");
end
request.fallback = struct('policy', "none");
end
