clear; clc;
startup

% Explicitly extended aggregate. Includes matrices and multi-minute
% characterization; do not use for routine local validation.
fprintf('\nRunning extended integration validation...\n');
fprintf('------------------------------------------\n');

run_execution_profile_integration_tests;
run_gui_execution_profile_tests;
run_gui_extended_tests;
run_fit_tool_requested_curve_tests;
run_fit_validation_tests;
run_ae_extended_tests;
run_mrlfe_fit_public_solver_tests;
run_mrlfe_main_gui_public_solver_tests;
run_mrlfe_sweeptool_public_solver_tests;
run_mrlfe_neutral_production_helper_tests;
run_mrlfe_public_contract_tests;

fprintf('\nExtended integration validation passed.\n');
