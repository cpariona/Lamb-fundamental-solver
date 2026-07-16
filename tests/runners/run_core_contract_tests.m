clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

% Fast repository, path, output-folder, and fitting-helper contracts.
fprintf('\nRunning core contract tests...\n');
fprintf('------------------------------\n');

test_startup_path_policy;
test_repository_root_utilities;
test_repository_naming_contract;
test_model_output_folder_helpers;
test_fitting_helpers_smoke;

fprintf('\nCore contract tests passed.\n');
