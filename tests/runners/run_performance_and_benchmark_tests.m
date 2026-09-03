clear; clc;
if isempty(which('mrlfeSolve')), startup; end

fprintf('\nRunning performance and benchmark tests...\n');
fprintf('------------------------------------------\n');

test_runtime_measurement_output_schema;
test_execution_profile_diagnostics_format;
test_mrlfe_execution_profile_benchmark_contract;
test_mrlfe_fit_grid_policy_performance;
test_mrlfe_production_core_performance;

fprintf('\nPerformance and benchmark tests passed.\n');
