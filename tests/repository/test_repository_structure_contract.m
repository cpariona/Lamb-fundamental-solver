function test_repository_structure_contract()
%TEST_REPOSITORY_STRUCTURE_CONTRACT Enforce the maintained repository layout.

repoRoot = testRepositoryRoot(mfilename('fullpath'));
paths = gitTrackedPaths(repoRoot);

allowedTopLevel = ["app", "docs", "examples", "src", "studies", "tests"];
requiredTopLevel = ["app", "examples", "src", "studies", "tests"];
for i = 1:numel(requiredTopLevel)
    assert(isfolder(fullfile(repoRoot, requiredTopLevel(i))), ...
        'Required repository directory is missing: %s', requiredTopLevel(i));
end
assert(~isfolder(fullfile(repoRoot, 'shared')), ...
    'A root-level shared/ source directory is forbidden.');
assert(~isfolder(fullfile(repoRoot, 'analysis')), ...
    'The retired analysis/ tree must remain absent.');

for i = 1:numel(paths)
    path = paths(i);
    parts = split(path, "/");
    if numel(parts) > 1
        assert(any(parts(1) == allowedTopLevel), ...
            'Tracked content uses an unsupported top-level directory: %s', path);
    end
end

sourcePaths = paths(startsWith(paths, ["app/", "examples/", "src/", "studies/", "tests/"]));
assert(~any(contains(lower(sourcePaths), "/archive/")), ...
    'Archive directories are forbidden under maintained source, example, and test trees.');
assert(~any(startsWith(paths, "docs/") & endsWith(paths, ".m")), ...
    'Production MATLAB files are forbidden under docs/.');

assertTestLocations(paths);
assertTestOwnership(repoRoot, paths);
assertModelTestsDoNotDependOnFitting(repoRoot, paths);
assertRetiredUnqualifiedFittingNames();
assertStudyOwnership(repoRoot, paths);
assertAppSurfaceOwnership(paths);
assertNoModelCampaigns(paths);
assertNoModelUiCode(repoRoot, paths);

fprintf('Repository structure contract test passed.\n');
end

function assertTestLocations(paths)
rootTestFiles = paths(startsWith(paths, "tests/") & count(paths, "/") == 1 & endsWith(paths, ".m"));
assert(isempty(rootTestFiles), ...
    'Root test wrappers are forbidden; commands must resolve to tests/runners/.');

runnerFiles = paths(startsWith(paths, "tests/runners/") & endsWith(paths, ".m"));
expectedRunners = "tests/runners/" + [ ...
    "run_repository_hygiene_tests.m"
    "run_quick_contract_tests.m"
    "run_quick_smoke_tests.m"
    "run_numerical_regression_tests.m"
    "run_extended_integration_tests.m"
    "run_performance_and_benchmark_tests.m"];
assert(isequal(sort(runnerFiles(:)), sort(expectedRunners(:))), ...
    'The maintained runner surface must contain exactly six tiers: %s', ...
    strjoin(setxor(runnerFiles, expectedRunners), ', '));

end

function assertModelTestsDoNotDependOnFitting(repoRoot, paths)
modelTests = paths(startsWith(paths, "tests/models/") & endsWith(paths, ".m"));
assert(~isempty(modelTests), 'Forward-model test dependency scan must not be empty.');
for path = modelTests(:).'
    source = executableMatlabText(fileread(fullfile(repoRoot, path)));
    assert(~contains(source, "lamb.fitting."), ...
        'Forward-model test depends on fitting setup: %s', path);
end
end

function assertTestOwnership(repoRoot, paths)
testPaths = paths(startsWith(paths, "tests/") & endsWith(paths, ".m"));
testNames = strings(0,1);
for p = testPaths(:).'
    [~,name] = fileparts(p);
    if startsWith(name,"test_"), testNames(end+1,1) = name; end %#ok<AGROW>
end
mentions = strings(0,1);
runnerPaths = paths(startsWith(paths,"tests/runners/") & endsWith(paths,".m"));
for p = runnerPaths(:).'
    source = regexprep(fileread(fullfile(repoRoot,p)), '%[^\r\n]*', '');
    found = string(regexp(source, '\<test_[A-Za-z0-9_]+\>', 'match'));
    mentions = [mentions; found(:)]; %#ok<AGROW>
end
assert(numel(mentions) == numel(unique(mentions)), 'A test has multiple runner owners.');
assert(isequal(sort(testNames),sort(mentions)), 'Every maintained test needs exactly one runner owner.');
end

function assertStudyOwnership(repoRoot, paths)
studyMatlab = paths(startsWith(paths, "studies/") & endsWith(paths, ".m"));
assert(~isempty(studyMatlab), 'The studies ownership scan must not be empty.');
assert(~any(contains(studyMatlab, "/shared/")), ...
    'Generic shared/ ownership is forbidden under studies/.');
assert(~any(contains(lower(studyMatlab), "example")), ...
    'Study function names must not retain Example chronology.');

retiredDiagnostics = ["aeFindTopModalAtlasLocalMinima.m", ...
    "aeLinkModalAtlasMinimaIntoBranches.m", "aeResolveResultFile.m"];
for name = retiredDiagnostics
    assert(~any(endsWith(paths, "/" + name)), ...
        'Retired duplicated/compatibility diagnostic returned: %s', name);
end

retiredCalls = ["rlRunSweep", "mrlfeRunSweep", "aeRunSweep", ...
    "aeRunGridSweep", "aePlotGridSweepFrequencySurfaceInteractive"];
for path = studyMatlab(:).'
    executable = executableMatlabText(fileread(fullfile(repoRoot, path)));
    for name = retiredCalls
        expression = ['(?<![A-Za-z0-9_])' char(name) '\s*\('];
        assert(isempty(regexp(executable, expression, 'once')), ...
            'Study calls retired sweep API %s: %s', name, path);
    end
end
end

function assertRetiredUnqualifiedFittingNames()
oldNames = [ ...
    "rlBuildFitProblem", "rlEvaluateFitModel", "rlFitDispersionData", ...
    "mrlfeBuildFitFrequencyGrid", "mrlfeBuildFitProblem", ...
    "mrlfeEvaluateFitModel", "mrlfeFitDispersionData", ...
    "aeBuildFitProblem", "aeEvaluateFitModel", "aeFitDispersionData", ...
    "assessFitIdentifiability", "assessFitPhysicalQuality", ...
    "applyParameterOverrides", "buildParameterBounds", "buildParameterVector", ...
    "computeConstantSpeedBaseline", "computeDispersionFitMetrics", ...
    "computeDispersionFitResiduals", "estimateLocalSensitivity", ...
    "evaluateBoundedObjective", "getFitConfigValue", ...
    "normalizeExperimentalDispersionData", "solveDispersionFitProblem", ...
    "unpackParameterVector", "validateDispersionFitCoverage", ...
    "validateExperimentalDispersionData"];
for i = 1:numel(oldNames)
    assert(isempty(which(oldNames(i))), ...
        'Retired unqualified fitting name must not resolve: %s', oldNames(i));
end
end

function assertAppSurfaceOwnership(paths)
assert(~any(startsWith(paths, "app/adapters/")), ...
    'app/adapters must be absent after surface-first organization.');
assert(~any(startsWith(paths, ["app/main/", "app/shared/"])), ...
    'Retired generic app/main and app/shared owners must remain absent.');
rootMatlab = paths(startsWith(paths, "app/") & count(paths, "/") == 1 & ...
    endsWith(paths, ".m"));
expectedRoot = ["app/FitTool_GUI.m"; "app/LambFundamental_GUI.m"];
assert(isequal(sort(rootMatlab), sort(expectedRoot)), ...
    'Only the solver and fitting GUI entrypoints may remain at app root.');
assert(~any(startsWith(paths, "app/sweep/")), ...
    'The retired app/sweep adapter tree must remain absent.');
assert(~any(endsWith(paths, "/SweepTool_GUI.m")), ...
    'The retired SweepTool GUI must remain absent.');
end

function assertNoModelCampaigns(paths)
modelFiles = paths(startsWith(paths, "src/+lamb/+models/") & endsWith(paths, ".m"));
[~, names] = cellfun(@fileparts, cellstr(modelFiles), 'UniformOutput', false);
names = string(names);
campaignNames = modelFiles(~cellfun(@isempty, regexp(cellstr(names), '(?i)(sweep|campaign)', 'once')));
assert(isempty(campaignNames), ...
    'Campaign or sweep orchestration is forbidden under models/: %s', strjoin(campaignNames, ', '));
end

function assertNoModelUiCode(repoRoot, paths)
modelFiles = paths(startsWith(paths, "src/+lamb/+models/") & endsWith(paths, ".m"));
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
