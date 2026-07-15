clear; clc;
startup

% Extended fitted-curve metadata and the 36-case validation matrix.
fprintf('\nRunning execution-profile integration tests...\n');
fprintf('----------------------------------------------\n');

test_execution_profile_fit_curve_metadata;
test_execution_profile_validation_matrix;

fprintf('\nExecution-profile integration tests passed.\n');
