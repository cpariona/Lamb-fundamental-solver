clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

% Historical core numerical coverage, separated from structural contracts.
fprintf('\nRunning core numerical regression tests...\n');
fprintf('------------------------------------------\n');

test_lightweight_numerical_regression;
test_rl_fit_synthetic_A0;
test_mrlfe_fit_synthetic_A0Like;

fprintf('\nCore numerical regression tests passed.\n');
