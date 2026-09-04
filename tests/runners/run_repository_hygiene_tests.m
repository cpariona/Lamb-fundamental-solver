function run_repository_hygiene_tests()
% Explicit validation scope: restore the caller path on success or failure.
callerPath = path;
restorePath = onCleanup(@() path(callerPath)); %#ok<NASGU>
projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(projectRoot, 'tests', 'tooling'));
configureTestPath();
runTests();
end

function runTests()
fprintf('\nRunning repository hygiene tests...\n');
fprintf('-----------------------------------\n');

test_repository_structure_contract;
test_repository_documentation_contract;
test_repository_naming_contract;
test_repository_tracked_artifacts_contract;
test_repository_dependency_boundaries_contract;
test_startup_path_policy;
test_repository_root_utilities;

fprintf('\nRepository hygiene tests passed.\n');
end
