function test_ae_study_layout_contract()
%TEST_AE_STUDY_LAYOUT_CONTRACT Guard the maintained AE study surface.

repoRoot = testRepositoryRoot(mfilename('fullpath'));
studyRoot = fullfile(repoRoot, 'studies');
expected = [ ...
    "sensitivity/acoustoelastic_iop_hgo/study_iop_A0Like.m"
    "sensitivity/acoustoelastic_iop_hgo/study_mu_iop_A0Like.m"
    "solver_diagnostics/acoustoelastic_iop_hgo/diagnose_atlas_truncation.m"
    "solver_diagnostics/acoustoelastic_iop_hgo/diagnose_branch_families.m"
    "solver_diagnostics/acoustoelastic_iop_hgo/diagnose_grid_start_sensitivity.m"
    "solver_diagnostics/acoustoelastic_iop_hgo/diagnose_modal_atlas.m"
    "solver_diagnostics/acoustoelastic_iop_hgo/diagnose_sweep_reliability.m"];

for i = 1:numel(expected)
    [~, name] = fileparts(expected(i));
    expectedPath = fullfile(studyRoot, expected(i));
    assert(isfile(expectedPath), 'Explicit AE study path is missing: %s.', name);
end

fprintf('AE study layout contract passed.\n');
end
