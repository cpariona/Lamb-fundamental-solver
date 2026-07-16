clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

% Fast repository, path, output-folder, and fitting-helper contracts.
fprintf('\nRunning core contract tests...\n');
fprintf('------------------------------\n');

run_repository_hygiene_tests;
test_model_output_folder_helpers;
test_fitting_helpers_smoke;

fprintf('\nCore contract tests passed.\n');
