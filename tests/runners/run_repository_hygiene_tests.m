clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

fprintf('\nRunning repository hygiene tests...\n');
fprintf('-----------------------------------\n');

test_repository_structure_contract;
test_repository_documentation_contract;
test_repository_naming_contract;
test_repository_tracked_artifacts_contract;
test_repository_dependency_boundaries_contract;
test_startup_path_policy;
test_repository_root_utilities;

buildTestOwnership('ValidateActual', true);

fprintf('\nRepository hygiene tests passed.\n');
