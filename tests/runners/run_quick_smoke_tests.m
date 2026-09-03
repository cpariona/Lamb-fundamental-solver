clear; clc;
if isempty(which('mrlfeSolve')), startup; end

fprintf('\nRunning quick smoke validation...\n');
fprintf('---------------------------------\n');

% Application surfaces.
test_gui_struct_helpers_contract;
test_fit_parameter_state_contract;
test_fit_parameter_execution_contract;
test_gui_normalized_adapters_smoke;
test_gui_sweep_adapters_smoke;
test_gui_sweep_model_configuration_smoke;
test_gui_acoustoelastic_iop_hgo_sweep_adapter_smoke;
test_gui_acoustoelastic_iop_hgo_main_adapter_smoke;
test_ae_workflow_route_ownership;
test_gui_fit_model_configuration_contract;
test_fit_tool_model_configuration_contract;

% AE contracts and representative execution.
test_acoustoelastic_iop_hgo_branch_policy_validation;
test_ae_configuration_characterization;
test_ae_configuration_ownership;
test_ae_production_architecture_contract;
test_ae_result_file_compatibility;
test_ae_result_ownership;
test_ae_analyze_truncation_recovery;
test_acoustoelastic_iop_hgo_branch_persistence_refinement;
test_acoustoelastic_iop_hgo_constitutive_identity;
test_ae_physical_sweep_examples_contract;
test_sweep_plot_renderer_contract;
test_acoustoelastic_iop_hgo_identityA0_diagnostic_policy;
test_ae_maintained_examples_and_diagnostics;

% mRLFE contracts and representative execution.
test_mrlfe_smoke;
test_mrlfe_etaS_zero_limit;
test_mrlfe_residual_objective_contract;
test_mrlfe_tracking_quality_summary;
test_mrlfe_maintained_surface_contract;

fprintf('\nQuick smoke validation passed.\n');
