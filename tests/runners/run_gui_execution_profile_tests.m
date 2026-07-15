clear; clc;
startup

% GUI-owned execution-profile behavior and cross-surface integration.
fprintf('\nRunning GUI execution-profile tests...\n');
fprintf('--------------------------------------\n');

test_execution_profile_current_contract;
test_execution_profile_surface_integration;

fprintf('\nGUI execution-profile tests passed.\n');
