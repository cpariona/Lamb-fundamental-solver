clear; clc;
startup

% Canonical AE contracts and representative small solver executions.
fprintf('\nRunning quick acoustoelastic IOP/HGO tests...\n');
fprintf('---------------------------------------------\n');

test_acoustoelastic_iop_hgo_branch_policy_validation;
test_ae_analyze_truncation_recovery;
test_acoustoelastic_iop_hgo_branch_persistence_refinement;
test_acoustoelastic_iop_hgo_constitutive_identity;
test_ae_physical_sweep_examples_contract;
test_sweep_plot_renderer_contract;
test_acoustoelastic_iop_hgo_identityA0_diagnostic_policy;
test_acoustoelastic_iop_hgo_short_entrypoints;

fprintf('\nQuick acoustoelastic IOP/HGO tests passed.\n');
