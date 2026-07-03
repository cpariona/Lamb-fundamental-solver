clear; clc;
startup

fprintf('\nRunning execution profile cleanup tests...\n');
fprintf('---------------------------------------\n');

test_gui_execution_profile_normalization;
test_execution_profile_cleanup_contract;
test_model_execution_profile_resolvers;
test_execution_profile_surface_integration;

fprintf('\nExecution profile cleanup tests passed.\n');
