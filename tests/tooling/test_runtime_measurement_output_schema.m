function test_runtime_measurement_output_schema()
%TEST_RUNTIME_MEASUREMENT_OUTPUT_SCHEMA Guard local runtime-evidence schema.

repoRoot = testRepositoryRoot(mfilename('fullpath'));
originalFolder = pwd;
originalPath = path;
cleanup = onCleanup(@() restoreSession(originalFolder, originalPath)); %#ok<NASGU>
% A disposable probe measures runtime without executing another maintained test.
probeFolder = tempname(fullfile(repoRoot, 'tests', 'tooling'));
mkdir(probeFolder);
probeCleanup = onCleanup(@() removeProbe(probeFolder)); %#ok<NASGU>
probeName = "run_runtime_schema_probe";
probeFile = fopen(fullfile(probeFolder, probeName + ".m"), 'w');
assert(probeFile >= 0, 'Could not create runtime schema probe.');
fprintf(probeFile, 'function run_runtime_schema_probe()\nend\n');
fclose(probeFile);
addpath(probeFolder);
cd(tempdir);

result = measureTestRuntime(probeName, ...
    'RepeatCount', 1, 'WriteCsv', false);
expectedColumns = { ...
    'Entrypoint', 'Path', 'EntryType', 'OwningArea', 'Category', ...
    'RepeatCountRequested', 'RepeatCountCompleted', 'Status', 'Passed', ...
    'ElapsedSecondsMedian', 'ElapsedSecondsMin', 'ElapsedSecondsMax', ...
    'ErrorIdentifier', 'ErrorMessage', 'HardTimeoutAvailable', ...
    'TimeoutSeconds', 'MeasuredAtCommit', 'MATLABRelease', 'Platform', 'Notes'};
assert(isequal(result.Properties.VariableNames, expectedColumns), ...
    'Runtime measurement table schema changed.');
assert(height(result) == 1 && result.Entrypoint == probeName, ...
    'Runtime schema fixture measured an unexpected entrypoint.');
assert(result.Passed && result.Status == "passed", ...
    'Runtime schema fixture must complete successfully.');

source = string(fileread(fullfile(repoRoot, 'tests', 'tooling', ...
    'measureTestRuntime.m')));
assert(contains(source, '"Results/test_runtime/test_runtime_measurements.csv"'), ...
    'Default runtime output must be repository-root-aware ignored evidence.');

fprintf('Runtime measurement output-schema contract passed.\n');
end

function restoreSession(originalFolder, originalPath)
cd(originalFolder);
path(originalPath);
end

function removeProbe(probeFolder)
delete(fullfile(probeFolder, 'run_runtime_schema_probe.m'));
rmdir(probeFolder);
end
