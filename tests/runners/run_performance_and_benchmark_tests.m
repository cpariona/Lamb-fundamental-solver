function run_performance_and_benchmark_tests()
% Explicit validation scope: restore the caller path on success or failure.
callerPath = path;
restorePath = onCleanup(@() path(callerPath)); %#ok<NASGU>
projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(projectRoot, 'tests', 'tooling'));
configureTestPath();
runTests();
end

function runTests()
fprintf('\nRunning performance tests...\n');
fprintf('----------------------------\n');

test_runtime_measurement_output_schema;
test_execution_profile_diagnostics_format;
test_mrlfe_fit_grid_policy_performance;
test_mrlfe_production_core_performance;

fprintf('\nPerformance tests passed.\n');
end
