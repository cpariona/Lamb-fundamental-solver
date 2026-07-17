function test_repository_tracked_artifacts_contract()
%TEST_REPOSITORY_TRACKED_ARTIFACTS_CONTRACT Reject generated tracked outputs.

repoRoot = testRepositoryRoot(mfilename('fullpath'));
paths = gitTrackedPaths(repoRoot);

generatedExtensions = [".fig", ".png", ".jpg", ".jpeg", ".tif", ".tiff", ".gif", ".mat"];
for i = 1:numel(generatedExtensions)
    offenders = paths(endsWith(lower(paths), generatedExtensions(i)));
    assert(isempty(offenders), 'Tracked generated %s artifacts are forbidden: %s', ...
        generatedExtensions(i), strjoin(offenders, ', '));
end

pathParts = cellfun(@(p) split(string(p), "/"), cellstr(paths), 'UniformOutput', false);
generatedFolder = false(size(paths));
for i = 1:numel(paths)
    parts = pathParts{i};
    modelResultSource = startsWith(paths(i), "models/") && contains(paths(i), "/results/");
    generatedFolder(i) = any(parts == "Results") || any(parts == "figures") || ...
        (any(parts == "results") && ~modelResultSource);
end
assert(~any(generatedFolder), 'Tracked generated-output directory content is forbidden: %s', ...
    strjoin(paths(generatedFolder), ', '));

approvedCsv = [ ...
    "analysis/test_inventory/runner_edges.csv", ...
    "analysis/test_inventory/test_inventory.csv", ...
    "analysis/test_inventory/test_runner_ownership.csv", ...
    "analysis/test_inventory/test_runtime_measurements.csv"];
csvPaths = paths(endsWith(lower(paths), ".csv"));
unexpectedCsv = setdiff(csvPaths, approvedCsv);
assert(isempty(unexpectedCsv), 'CSV is not an approved inventory or fixture: %s', ...
    strjoin(unexpectedCsv, ', '));

fprintf('Repository tracked-artifact contract test passed.\n');
end

function paths = gitTrackedPaths(repoRoot)
[status, output] = system(sprintf('git -C "%s" ls-files', repoRoot));
assert(status == 0, 'Could not enumerate tracked repository files.');
paths = replace(splitlines(string(strtrim(output))), "\", "/");
paths(paths == "") = [];
end
