clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

% Canonical owner for structural execution-profile contracts.
fprintf('\nRunning execution-profile contract tests...\n');
fprintf('-------------------------------------------\n');

test_gui_execution_profile_normalization;
test_model_execution_profile_resolvers;
test_execution_profile_cleanup_contract;
test_execution_profile_surface_metadata;
test_execution_profile_state_transition_contract;

fprintf('\nExecution-profile contract tests passed.\n');
