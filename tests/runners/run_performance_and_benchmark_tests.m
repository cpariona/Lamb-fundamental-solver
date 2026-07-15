clear; clc;
startup

% Maintained descriptive timing evidence. The obsolete execution-profile
% benchmark is deliberately excluded pending redesign.
fprintf('\nRunning performance and benchmark evidence...\n');
fprintf('---------------------------------------------\n');

test_mrlfe_fit_grid_policy_performance;
run_mrlfe_production_core_performance_tests;

fprintf('\nPerformance and benchmark evidence passed.\n');
