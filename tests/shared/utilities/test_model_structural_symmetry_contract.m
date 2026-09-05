function test_model_structural_symmetry_contract()
%TEST_MODEL_STRUCTURAL_SYMMETRY_CONTRACT Guard common model-family ownership.

repoRoot = testRepositoryRoot();
modelsRoot = fullfile(repoRoot, 'models');
families = ["rayleigh_lamb", "mrlfe", "acoustoelastic_iop_hgo"];
commonFolders = ["api", "configuration", "core", "solvers", ...
    "tracking", "quality", "results"];

for family = families
    familyRoot = fullfile(modelsRoot, family);
    assert(isfolder(familyRoot), 'Missing model family: %s.', family);
    for folder = commonFolders
        folderPath = fullfile(familyRoot, folder);
        assert(isfolder(folderPath), ...
            'Model %s is missing common responsibility folder %s/.', family, folder);
        assert(~isempty(dir(fullfile(folderPath, '*.m'))), ...
            'Model %s has an empty common responsibility folder %s/.', family, folder);
    end
    assert(~isfolder(fullfile(familyRoot, 'options')), ...
        'Generic options/ ownership is forbidden for model %s; use configuration/.', family);
end

assertOwner(repoRoot, 'rlComputeFundamentalLambModes', ...
    'models/rayleigh_lamb/api/rlComputeFundamentalLambModes.m');
assertOwner(repoRoot, 'mrlfeSolve', ...
    'models/mrlfe/api/mrlfeSolve.m');
assertOwner(repoRoot, 'solveAcoustoelasticIOPHGOBranch', ...
    'models/acoustoelastic_iop_hgo/api/solveAcoustoelasticIOPHGOBranch.m');

assert(~isfile(fullfile(modelsRoot, 'rayleigh_lamb', 'core', ...
    'rlComputeFundamentalLambModes.m')), ...
    'RL public API must not be owned by core/.');
assert(~isfile(fullfile(modelsRoot, 'acoustoelastic_iop_hgo', 'solvers', ...
    'solveAcoustoelasticIOPHGOBranch.m')), ...
    'AE public API must not be owned by solvers/.');

frequencyOwner = fullfile(modelsRoot, 'shared', 'configuration', ...
    'buildFrequencyVector.m');
assert(isfile(frequencyOwner), ...
    'Generic frequency-grid construction must have neutral model ownership.');
rlFrequencyWrapper = fullfile(modelsRoot, 'rayleigh_lamb', 'configuration', ...
    'rlBuildFrequencyVector.m');
assert(isfile(rlFrequencyWrapper));
assert(contains(string(fileread(rlFrequencyWrapper)), 'buildFrequencyVector'), ...
    'RL frequency wrapper must delegate generic construction to the neutral owner.');

seedPath = fullfile(modelsRoot, 'mrlfe', 'tracking', 'mrlfeBuildSeed.m');
seedText = string(fileread(seedPath));
assert(contains(seedText, 'rlComputeFundamentalLambModes'), ...
    'The intentional mRLFE -> Rayleigh-Lamb seed dependency must remain explicit.');

fprintf('Model structural symmetry contract passed.\n');
end

function assertOwner(repoRoot, functionName, relativePath)
expected = fullfile(repoRoot, strrep(relativePath, '/', filesep));
resolved = which(functionName);
assert(strcmp(resolved, expected), ...
    'Unexpected owner for %s. Expected %s, got %s.', functionName, expected, resolved);
end
