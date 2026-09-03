clear; clc;
if isempty(which('mrlfeSolve')), startup; end

fprintf('\nRunning extended integration tests...\n');
fprintf('-------------------------------------\n');

% Execution profiles and fitted-curve integration.
test_execution_profile_current_contract;
test_execution_profile_surface_integration;
test_execution_profile_fit_curve_metadata;
test_execution_profile_validation_matrix;
test_fit_tool_requested_curve_models;
test_fit_display_curve_no_solver_contract;

% Shared and model-specific fitting validation.
test_fit_validation_rayleigh_lamb;
test_fit_validation_mrlfe;
test_fit_validation_mrlfe_hidden_params;
test_fit_validation_ae_iop_hgo;
test_fit_validation_ae_iop_hgo_hidden_params;
test_fit_physical_qc_flat_rl;
test_fit_physical_qc_synthetic_pass;
test_rl_fit_rejects_prediction_fallback;
test_mrlfe_etaS_fit_forward_cache;
test_mrlfe_fit_fast_options_quality;

% FitTool and Main GUI mRLFE routes.
test_gui_mrlfe_fixed_etaS_fit_contract;
test_gui_mrlfe_fit_route_policy_contract;
test_gui_mrlfe_fit_full_curve_fast_contract;
test_mrlfe_fit_frequency_grid_contract;
test_mrlfe_fit_uses_public_solver;
test_mrlfe_fit_public_solver_characterization;
test_mrlfe_fit_public_solver_parameter_regression;
test_mrlfe_main_gui_uses_public_solver;
test_mrlfe_main_gui_characterization;
test_mrlfe_main_gui_consumer_equivalence;
test_mrlfe_main_gui_result_contract;

% SweepTool and canonical mRLFE production routes.
test_mrlfe_sweep_uses_public_solver;
test_mrlfe_sweep_point_characterization;
test_mrlfe_sweep_metadata_and_mapping;
test_mrlfe_solve_request_builder;
test_mrlfe_public_contract_characterization;
test_mrlfe_canonical_route_contract;
test_mrlfe_configuration_ownership_contract;
test_mrlfe_maintained_route_characterization;
test_mrlfe_production_dependency_contract;
test_mrlfe_neutral_seed_contract;
test_mrlfe_neutral_tracker_termination_contract;
test_mrlfe_production_core_presets;
test_mrlfe_production_core_characterization;

fprintf('\nExtended integration tests passed.\n');
