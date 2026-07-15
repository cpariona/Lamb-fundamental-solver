clear; clc;
startup

fprintf('\nRunning execution profile surface tests...\n');
fprintf('----------------------------------------\n');

% Compatibility aggregate over canonical owners.
run_execution_profile_contract_tests;
run_gui_execution_profile_tests;

fprintf('\nExecution profile surface tests passed.\n');
