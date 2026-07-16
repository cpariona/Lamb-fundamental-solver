function test_repository_structure_contract()
%TEST_REPOSITORY_STRUCTURE_CONTRACT Enforce the maintained repository layout.

repoRoot = testRepositoryRoot(mfilename('fullpath'));
paths = gitTrackedPaths(repoRoot);

allowedTopLevel = ["analysis", "app", "docs", "examples", "models", "tests"];
requiredTopLevel = allowedTopLevel;
for i = 1:numel(requiredTopLevel)
    assert(isfolder(fullfile(repoRoot, requiredTopLevel(i))), ...
        'Required repository directory is missing: %s', requiredTopLevel(i));
end
assert(~isfolder(fullfile(repoRoot, 'shared')), ...
    'A root-level shared/ source directory is forbidden.');

for i = 1:numel(paths)
    path = paths(i);
    parts = split(path, "/");
    if numel(parts) > 1
        assert(any(parts(1) == allowedTopLevel), ...
            'Tracked content uses an unsupported top-level directory: %s', path);
    end
end

sourcePaths = paths(startsWith(paths, ["analysis/", "app/", "examples/", "models/", "tests/"]));
assert(~any(contains(lower(sourcePaths), "/archive/")), ...
    'Archive directories are forbidden under maintained source, example, and test trees.');
assert(~any(startsWith(paths, "docs/") & endsWith(paths, ".m")), ...
    'Production MATLAB files are forbidden under docs/.');

assertTestLocations(paths);
assertNoModelCampaigns(paths);
assertNoModelUiCode(repoRoot, paths);

fprintf('Repository structure contract test passed.\n');
end

function assertTestLocations(paths)
rootTestFiles = paths(startsWith(paths, "tests/") & count(paths, "/") == 1 & endsWith(paths, ".m"));
allowedRootFiles = [ ...
    "tests/run_acoustoelastic_smoke_tests.m", ...
    "tests/run_all_smoke_tests.m", ...
    "tests/run_core_smoke_tests.m", ...
    "tests/run_gui_smoke_tests.m", ...
    "tests/run_main_gui_export_tests.m", ...
    "tests/run_mrlfe_production_core_tests.m", ...
    "tests/run_mrlfe_public_contract_tests.m", ...
    "tests/run_mrlfe_route_integrity_tests.m", ...
    "tests/run_mrlfe_smoke_tests.m"];
unexpected = setdiff(rootTestFiles, allowedRootFiles);
assert(isempty(unexpected), 'Unexpected root-level MATLAB test file: %s', strjoin(unexpected, ', '));

legacyTestFiles = paths(startsWith(paths, "tests/") & endsWith(paths, ".m") & ...
    ~startsWith(paths, ["tests/app/", "tests/models/", "tests/runners/", "tests/shared/"]) & ...
    ~ismember(paths, allowedRootFiles));
assert(isequal(legacyTestFiles, "tests/fitting/run_fit_validation_tests.m") || isempty(legacyTestFiles), ...
    'Tests exist outside stable layout locations or documented public wrappers: %s', ...
    strjoin(legacyTestFiles, ', '));
end

function assertNoModelCampaigns(paths)
modelFiles = paths(startsWith(paths, "models/") & endsWith(paths, ".m"));
[~, names] = cellfun(@fileparts, cellstr(modelFiles), 'UniformOutput', false);
names = string(names);
campaignNames = modelFiles(~cellfun(@isempty, regexp(cellstr(names), '(?i)(sweep|campaign)', 'once')));
assert(isempty(campaignNames), ...
    'Campaign or sweep orchestration is forbidden under models/: %s', strjoin(campaignNames, ', '));
end

function assertNoModelUiCode(repoRoot, paths)
modelFiles = paths(startsWith(paths, "models/") & endsWith(paths, ".m"));
uiCalls = ["uifigure", "uicontrol", "uilabel", "uibutton", "uitable", ...
    "uiaxes", "FitTool_GUI", "SweepTool_GUI", "LambFundamental_GUI"];
for i = 1:numel(modelFiles)
    executable = executableMatlabText(fileread(fullfile(repoRoot, modelFiles(i))));
    for j = 1:numel(uiCalls)
        assert(isempty(regexp(executable, ['(?<![A-Za-z0-9_])' char(uiCalls(j)) '\s*\('], 'once')), ...
            'Model code contains a forbidden GUI/UI call to %s: %s', uiCalls(j), modelFiles(i));
    end
end
end

function paths = gitTrackedPaths(repoRoot)
[status, output] = system(sprintf('git -C "%s" ls-files', repoRoot));
assert(status == 0, 'Could not enumerate tracked repository files.');
paths = replace(splitlines(string(strtrim(output))), "\", "/");
paths(paths == "") = [];
end

function text = executableMatlabText(text)
text = regexprep(text, '%\{[\s\S]*?%\}', ' ');
text = regexprep(text, '''(?:[^'']|'''')*''', '''''');
text = regexprep(text, '"(?:[^"]|"")*"', '""');
text = regexprep(text, '%[^\r\n]*', ' ');
end
