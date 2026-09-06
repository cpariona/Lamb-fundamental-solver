function test_mrlfe_production_core_contract()
%TEST_MRLFE_PRODUCTION_CORE_CONTRACT Validate production-core ownership and metadata.

fprintf('\nRunning mRLFE production core contract test...\n');
fprintf('---------------------------------------------\n');

assertFunctionsOnPath({ ...
    'lamb.models.mrlfe.core.mrlfeBuildProblem', ...
    'lamb.models.mrlfe.solvers.mrlfeSolveBranch', ...
    'lamb.models.mrlfe.solvers.mrlfeSolveElasticBranch', ...
    'lamb.models.mrlfe.solvers.mrlfeSolveViscoelasticBranch', ...
    'lamb.models.mrlfe.tracking.mrlfeBuildSeed', ...
    'lamb.models.mrlfe.tracking.mrlfeTrackBranchAdaptive', ...
    'lamb.models.mrlfe.policies.mrlfeApplyTerminationPolicy'});

root = testRepositoryRoot();
solveText = fileread(fullfile(root, 'src', '+lamb', '+models', '+mrlfe', 'mrlfeSolve.m'));
assert(~contains(solveText, 'mrlfeEvaluateAtlasFitModel'), ...
    'lamb.models.mrlfe.mrlfeSolve must not call mrlfeEvaluateAtlasFitModel.');
assert(~contains(solveText, 'mrlfeEvaluateFitModel'), ...
    'lamb.models.mrlfe.mrlfeSolve must not call mrlfeEvaluateFitModel.');

problemText = fileread(fullfile(root, 'src', '+lamb', '+models', '+mrlfe', '+core', 'mrlfeBuildProblem.m'));
seedText = fileread(fullfile(root, 'src', '+lamb', '+models', '+mrlfe', '+tracking', 'mrlfeBuildSeed.m'));
assert(~contains(problemText, 'lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes'), ...
    'lamb.models.mrlfe.core.mrlfeBuildProblem must not own Rayleigh-Lamb seed generation.');
assert(contains(seedText, 'lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes'), ...
    'lamb.models.mrlfe.tracking.mrlfeBuildSeed must own the explicit mRLFE -> Rayleigh-Lamb seed dependency.');

rlRoot = fullfile(root, 'src', '+lamb', '+models', '+rayleigh_lamb');
rlFiles = dir(fullfile(rlRoot, '**', '*.m'));
for i = 1:numel(rlFiles)
    text = lower(string(fileread(fullfile(rlFiles(i).folder, rlFiles(i).name))));
    assert(~contains(text, 'mrlfe'), ...
        'Rayleigh-Lamb must not depend on mRLFE: %s.', fullfile(rlFiles(i).folder, rlFiles(i).name));
end

productionFiles = [ ...
    string(fullfile(root, 'src', '+lamb', '+models', '+mrlfe', '+core', 'mrlfeBuildProblem.m')); ...
    string(fullfile(root, 'src', '+lamb', '+models', '+mrlfe', '+solvers', 'mrlfeSolveBranch.m')); ...
    string(fullfile(root, 'src', '+lamb', '+models', '+mrlfe', '+solvers', 'mrlfeSolveElasticBranch.m')); ...
    string(fullfile(root, 'src', '+lamb', '+models', '+mrlfe', '+solvers', 'mrlfeSolveViscoelasticBranch.m')); ...
    string(fullfile(root, 'src', '+lamb', '+models', '+mrlfe', '+tracking', 'mrlfeBuildSeed.m')); ...
    string(fullfile(root, 'src', '+lamb', '+models', '+mrlfe', '+tracking', 'mrlfeTrackBranchAdaptive.m')); ...
    string(fullfile(root, 'src', '+lamb', '+models', '+mrlfe', '+policies', 'mrlfeApplyTerminationPolicy.m'))];

for i = 1:numel(productionFiles)
    text = fileread(productionFiles(i));
    assert(~contains(text, 'mrlfeEvaluateAtlasFitModel'), ...
        'Production core must not call mrlfeEvaluateAtlasFitModel: %s', productionFiles(i));
    assert(~contains(text, 'mrlfeEvaluateFitModel'), ...
        'Production core must not call mrlfeEvaluateFitModel: %s', productionFiles(i));
    assert(~contains(text, 'guiRunMRLFEModel') && ~contains(text, 'guiFitMRLFESolver'), ...
        'Production core must not call GUI adapters: %s', productionFiles(i));
end

request = localRequest("A0Like", 0.05, "fast", "physicalTail");
result = lamb.models.mrlfe.mrlfeSolve(request);
assert(result.execution.internalEngine == "viscoelastic_adaptive", ...
    'Effective engine name must be neutral for viscoelastic cases.');
assert(~contains(result.execution.internalEngine, "Fit") && ...
    ~contains(result.execution.internalEngine, "GUI") && ...
    ~contains(result.execution.internalEngine, "Unified"), ...
    'Effective engine must not expose historical route naming.');
assert(result.execution.requestedPreset == "fast", 'Requested preset metadata changed.');
assert(result.execution.effectivePreset == "fast", 'Effective preset metadata changed.');
assert(result.fallback.applied == false, 'Production core must not apply fallback.');

elastic = lamb.models.mrlfe.mrlfeSolve(localRequest("S0Like", 0, "fast", "none"));
assert(elastic.execution.internalEngine == "elastic_adaptive", ...
    'Effective engine name must be neutral for zero-viscosity cases.');

fprintf('mRLFE production core contract test passed.\n');
end

function assertFunctionsOnPath(functionNames)
for i = 1:numel(functionNames)
    assert(~isempty(which(functionNames{i})), 'Missing function on path: %s.', functionNames{i});
end
end

function request = localRequest(branch, etaS, preset, terminationPolicy)
request = struct();
request.branch = string(branch);
request.frequency_Hz = linspace(1000, 6000, 10).';
request.material = struct('mu_Pa', 75e3, 'etaS_Pas', etaS, 'rho_kgm3', 1000, 'nu', 0.4999);
request.geometry = struct('thickness_m', 0.5e-3);
request.fluid = struct('density_kgm3', 1000, 'soundSpeed_mps', 1500);
request.numerics = struct('preset', string(preset));
request.selection = struct('strategy', "adaptive");
request.termination = struct('policy', string(terminationPolicy));
request.fallback = struct('policy', "none");
end
