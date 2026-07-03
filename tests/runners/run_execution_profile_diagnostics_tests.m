clear; clc;
startup

fprintf('\nRunning execution profile diagnostics tests...\n');
fprintf('---------------------------------------------\n');

test_execution_profile_diagnostics_format;
test_mrlfe_execution_profile_benchmark_contract;

fprintf('\nExecution profile diagnostics tests passed.\n');
