clear; clc;
startup

fprintf('\nRunning execution profile end-to-end tests...\n');
fprintf('-------------------------------------------\n');

test_gui_execution_profile_normalization;
test_execution_profile_state_transition_contract;
test_execution_profile_fit_curve_metadata;
test_execution_profile_validation_matrix;

fprintf('\nExecution profile end-to-end tests passed.\n');
