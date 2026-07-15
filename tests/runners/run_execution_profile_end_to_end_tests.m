clear; clc;
startup

fprintf('\nRunning execution profile end-to-end tests...\n');
fprintf('-------------------------------------------\n');

% Compatibility aggregate over canonical contract and extended owners.
run_execution_profile_contract_tests;
run_gui_execution_profile_tests;
run_execution_profile_integration_tests;

fprintf('\nExecution profile end-to-end tests passed.\n');
