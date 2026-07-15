clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

% Routine structural contracts. No characterization, benchmarks, or matrices.
fprintf('\nRunning quick contract validation...\n');
fprintf('------------------------------------\n');

run_core_contract_tests;
run_execution_profile_contract_tests;
run_fit_data_import_tests;
run_fit_tool_interaction_contract_tests;
run_mrlfe_public_api_contract_tests;

fprintf('\nQuick contract validation passed.\n');
