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

fprintf('Model structural symmetry contract passed.\n');
end
