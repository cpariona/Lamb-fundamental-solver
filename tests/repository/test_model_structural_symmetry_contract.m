function test_model_structural_symmetry_contract()
%TEST_MODEL_STRUCTURAL_SYMMETRY_CONTRACT Guard common model-family ownership.

repoRoot = testRepositoryRoot();
modelsRoot = fullfile(repoRoot, 'src', '+lamb', '+models');
families = ["rayleigh_lamb", "mrlfe", "acoustoelastic_iop_hgo"];
roles = { ...
    ["approximations", "configuration", "core", "equations", "solvers", "tracking", "quality", "results"], ...
    ["configuration", "core", "solvers", "tracking", "policies", "quality", "results"], ...
    ["configuration", "constitutive", "core", "diagnostics", "solvers", "tracking", "policies", "quality", "results"]};

for familyIndex = 1:numel(families)
    family = families(familyIndex);
    familyRoot = fullfile(modelsRoot, '+' + family);
    assert(isfolder(familyRoot), 'Missing model family package: %s.', family);
    for role = roles{familyIndex}
        rolePath = fullfile(familyRoot, '+' + role);
        assert(isfolder(rolePath) && ~isempty(dir(fullfile(rolePath, '*.m'))), ...
            'Model %s has a missing or empty responsibility package %s.', family, role);
    end
    assert(~isfolder(fullfile(familyRoot, '+options')), ...
        'Generic options ownership is forbidden for model %s; use configuration.', family);
    assert(~isfolder(fullfile(familyRoot, '+api')), ...
        'Public APIs must live at the family package root, not in a nested api package.');
end

assertOwner(repoRoot, 'lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes', ...
    'src/+lamb/+models/+rayleigh_lamb/rlComputeFundamentalLambModes.m');
assertOwner(repoRoot, 'lamb.models.mrlfe.mrlfeSolve', ...
    'src/+lamb/+models/+mrlfe/mrlfeSolve.m');
assertOwner(repoRoot, 'lamb.models.mrlfe.configuration.mrlfeBuildSolveRequest', ...
    'src/+lamb/+models/+mrlfe/+configuration/mrlfeBuildSolveRequest.m');
assertOwner(repoRoot, 'lamb.models.acoustoelastic_iop_hgo.solveAcoustoelasticIOPHGOBranch', ...
    'src/+lamb/+models/+acoustoelastic_iop_hgo/solveAcoustoelasticIOPHGOBranch.m');

frequencyOwner = fullfile(repoRoot, 'src', '+lamb', '+grids', 'buildFrequencyVector.m');
assert(isfile(frequencyOwner), ...
    'Generic frequency-grid construction must have neutral grids ownership.');
assert(strcmp(which('lamb.grids.buildFrequencyVector'), frequencyOwner));
assert(isempty(which('rlBuildFrequencyVector')), ...
    'The retired Rayleigh-Lamb frequency wrapper must not remain discoverable.');

assertOwner(repoRoot, 'lamb.elasticity.elasticFromLame', ...
    'src/+lamb/+elasticity/elasticFromLame.m');
assertOwner(repoRoot, 'lamb.elasticity.elasticFromMuNu', ...
    'src/+lamb/+elasticity/elasticFromMuNu.m');

seedPath = fullfile(modelsRoot, '+mrlfe', '+tracking', 'mrlfeBuildSeed.m');
seedText = string(fileread(seedPath));
assert(contains(seedText, 'lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes'), ...
    'The intentional mRLFE -> Rayleigh-Lamb seed dependency must remain explicit.');

fprintf('Model structural symmetry contract passed.\n');
end

function assertOwner(repoRoot, functionName, relativePath)
expected = fullfile(repoRoot, strrep(relativePath, '/', filesep));
resolved = which(functionName);
assert(strcmp(resolved, expected), ...
    'Unexpected owner for %s. Expected %s, got %s.', functionName, expected, resolved);
end
