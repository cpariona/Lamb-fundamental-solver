function run_quick_smoke_tests()
% Explicit validation scope: restore the caller path on success or failure.
callerPath = path;
restorePath = onCleanup(@() path(callerPath)); %#ok<NASGU>
projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(projectRoot, 'tests', 'tooling'));
configureTestPath();
runTests();
end

function runTests()
fprintf('\nRunning quick smoke validation...\n');
fprintf('---------------------------------\n');

% Application surfaces.
test_gui_struct_helpers_contract;
test_fit_parameter_state_contract;
test_fit_parameter_execution_contract;
test_gui_normalized_adapters_smoke;
test_gui_acoustoelastic_iop_hgo_main_adapter_smoke;
test_ae_workflow_route_ownership;
test_gui_fit_model_configuration_contract;
test_fit_tool_model_configuration_contract;

% AE contracts and representative execution.
test_acoustoelastic_iop_hgo_branch_policy_validation;
test_ae_configuration_characterization;
test_ae_configuration_ownership;
test_ae_production_architecture_contract;
test_ae_result_ownership;
test_ae_analyze_truncation_recovery;
test_acoustoelastic_iop_hgo_branch_persistence_refinement;
test_acoustoelastic_iop_hgo_constitutive_identity;
test_ae_sensitivity_study_contract;
test_sensitivity_plot_renderer_contract;
test_acoustoelastic_iop_hgo_identityA0_diagnostic_policy;
test_ae_study_layout_contract;

% mRLFE contracts and representative execution.
test_mrlfe_smoke;
test_mrlfe_etaS_zero_limit;
test_mrlfe_residual_objective_contract;
test_mrlfe_tracking_quality_summary;
test_mrlfe_maintained_surface_contract;

fprintf('\nQuick smoke validation passed.\n');
end
