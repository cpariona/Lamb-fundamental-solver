clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

fprintf('\nRunning execution profile infrastructure tests...\n');
fprintf('-----------------------------------------------\n');

% Compatibility aggregate over canonical owners.
run_execution_profile_contract_tests;
run_gui_execution_profile_tests;

fprintf('\nExecution profile infrastructure tests passed.\n');
