function test_repository_root_utilities()
%TEST_REPOSITORY_ROOT_UTILITIES Validate repository-root resolution.

repoRoot = testRepositoryRoot(mfilename('fullpath'));

assert(isfile(fullfile(repoRoot, 'startup.m')), ...
    'testRepositoryRoot should resolve a folder containing startup.m.');
assert(isfolder(fullfile(repoRoot, 'tests', 'runners')), ...
    'testRepositoryRoot should resolve the repository root, not a tests subfolder.');
assert(strcmp(testRepositoryRoot(fullfile(repoRoot, 'tests', 'runners', 'run_extended_integration_tests.m')), repoRoot), ...
    'testRepositoryRoot should resolve canonical integration runners.');
assert(strcmp(testRepositoryRoot(fullfile(repoRoot, 'tests', 'runners', 'run_quick_smoke_tests.m')), repoRoot), ...
    'testRepositoryRoot should resolve runner implementations.');

fprintf('test_repository_root_utilities passed. Repository-root resolution is path independent.\n');
end
