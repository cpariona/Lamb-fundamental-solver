function test_ae_maintained_examples_and_diagnostics()
%TEST_AE_MAINTAINED_EXAMPLES_AND_DIAGNOSTICS Guard the compact AE teaching surface.

repoRoot = testRepositoryRoot(mfilename('fullpath'));
exampleRoot = fullfile(repoRoot, 'examples', 'acoustoelastic_iop_hgo');
expected = [ ...
    "basic/run_atlas_branch.m"
    "fitting/fit_ae_atlasA0.m"
    "sweeps/ae_sweep_iop_A0Like.m"
    "sweeps/ae_sweep_mu_iop_A0Like.m"
    "diagnostics/diagnose_atlas_truncation.m"
    "diagnostics/diagnose_branch_families.m"
    "diagnostics/diagnose_grid_start_sensitivity.m"
    "diagnostics/diagnose_modal_atlas.m"
    "diagnostics/diagnose_sweep_reliability.m"];

files = dir(fullfile(exampleRoot, '**', '*.m'));
actual = strings(numel(files), 1);
for i = 1:numel(files)
    fullPath = replace(string(fullfile(files(i).folder, files(i).name)), "\", "/");
    rootPrefix = replace(string(exampleRoot), "\", "/") + "/";
    actual(i) = erase(fullPath, rootPrefix);
end
assert(isequal(sort(actual), sort(expected)), ...
    'Maintained AE examples/diagnostics changed: %s', ...
    strjoin(setxor(actual, expected), ', '));

for i = 1:numel(expected)
    [~, name] = fileparts(expected(i));
    expectedPath = fullfile(exampleRoot, expected(i));
    assert(isfile(expectedPath), 'Explicit example path is missing: %s.', name);
    assert(isempty(which(name)), 'Examples must not be globally on the path: %s.', name);
end

fprintf('AE maintained examples and diagnostics contract passed.\n');
end
