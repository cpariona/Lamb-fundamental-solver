clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

% Focused deterministic numerical and fitting regressions (not quick smoke).
fprintf('\nRunning numerical regression validation...\n');
fprintf('------------------------------------------\n');

run_core_numerical_regression_tests;
test_rl_fit_evaluator_branch_consistency;
run_ae_extended_tests;
run_mrlfe_production_core_contract_tests;
run_mrlfe_public_result_contract_tests;

fprintf('\nNumerical regression validation passed.\n');
