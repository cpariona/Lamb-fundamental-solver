function runRepositoryTestRunner(anchorFile, runnerName)
%RUNREPOSITORYTESTRUNNER Run a maintained test runner implementation.

repoRoot = testRepositoryRoot(anchorFile);
runnerFile = fullfile(repoRoot, 'tests', 'runners', [char(string(runnerName)), '.m']);

assert(isfile(runnerFile), 'Missing test runner implementation: %s.', runnerFile);
run(runnerFile);
end
