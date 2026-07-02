clear; clc;
startup

fprintf('\nRunning execution profile infrastructure tests...\n');
fprintf('-----------------------------------------------\n');

test_gui_execution_profile_normalization;
test_model_execution_profile_resolvers;
test_execution_profile_current_contract;
test_execution_profile_surface_metadata;

fprintf('\nExecution profile infrastructure tests passed.\n');
