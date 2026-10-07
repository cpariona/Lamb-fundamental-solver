function test_repository_root_utilities()
%TEST_REPOSITORY_ROOT_UTILITIES Validate repository-root resolution.

repoRoot = testRepositoryRoot(mfilename('fullpath'));

assert(isfile(fullfile(repoRoot, 'startup.m')), ...
    'testRepositoryRoot should resolve a folder containing startup.m.');
assert(isfolder(fullfile(repoRoot, 'tests', 'runners')), ...
    'testRepositoryRoot should resolve the repository root, not a tests subfolder.');
assert(strcmp(testRepositoryRoot(fullfile(repoRoot, 'tests', 'runners', 'run_regression_tests.m')), repoRoot), ...
    'testRepositoryRoot should resolve the canonical regression gate.');
assert(strcmp(testRepositoryRoot(fullfile(repoRoot, 'tests', 'runners', 'private', 'repository_test_catalog.m')), repoRoot), ...
    'testRepositoryRoot should resolve the private catalog.');

fprintf('test_repository_root_utilities passed. Repository-root resolution is path independent.\n');
end
