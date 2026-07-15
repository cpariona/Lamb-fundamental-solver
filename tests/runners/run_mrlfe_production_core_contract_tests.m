clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

% Deterministic production-core contracts without characterization or timing.
fprintf('\nRunning mRLFE production-core contract tests...\n');
fprintf('-----------------------------------------------\n');

test_mrlfe_production_core_contract;
test_mrlfe_numerical_preset_grids;
test_mrlfe_solve_frequency_override;
test_mrlfe_robust_start_contract;
test_mrlfe_termination_policy;

fprintf('\nmRLFE production-core contract tests passed.\n');
