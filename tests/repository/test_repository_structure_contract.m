function test_repository_structure_contract()
%TEST_REPOSITORY_STRUCTURE_CONTRACT Enforce the maintained repository layout.

repoRoot = testRepositoryRoot(mfilename('fullpath'));
paths = gitTrackedPaths(repoRoot);

allowedTopLevel = ["app", "docs", "examples", "src", "studies", "tests"];
requiredTopLevel = allowedTopLevel;
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
assertFittingOwnership(repoRoot, paths);
assertStudyOwnership(repoRoot, paths);
assertSweepOwnership(paths);
assertAppSurfaceOwnership(paths);
assertDocumentationOwnership(repoRoot, paths);
assertAeModelDiagnosticOwnership(paths);
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

legacyTestFiles = paths(startsWith(paths, "tests/") & endsWith(paths, ".m") & ...
    ~startsWith(paths, ["tests/app/", "tests/fitting/", "tests/models/", ...
        "tests/repository/", "tests/runners/", "tests/studies/", ...
        "tests/sweeps/", "tests/tooling/"]));
assert(isempty(legacyTestFiles), ...
    'Tests exist outside stable layout locations: %s', ...
    strjoin(legacyTestFiles, ', '));
for requiredRoot = ["tests/app/", "tests/fitting/", "tests/models/", ...
        "tests/repository/", "tests/runners/", "tests/tooling/"]
    owned = paths(startsWith(paths, requiredRoot) & endsWith(paths, ".m"));
    assert(~isempty(owned), 'Maintained test owner contains no MATLAB files: %s', requiredRoot);
end
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

for familyRoot = [ ...
        "studies/sensitivity/rayleigh_lamb/", ...
        "studies/sensitivity/mrlfe/", ...
        "studies/sensitivity/acoustoelastic_iop_hgo/", ...
        "studies/solver_diagnostics/mrlfe/", ...
        "studies/solver_diagnostics/acoustoelastic_iop_hgo/"]
    familyFiles = studyMatlab(startsWith(studyMatlab, familyRoot));
    assert(~isempty(familyFiles), 'Study family contains no MATLAB files: %s', familyRoot);
end

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

function assertSweepOwnership(paths)
sweepPaths = paths(startsWith(paths, "src/+lamb/+sweeps/") & endsWith(paths, ".m"));
expected = "src/+lamb/+sweeps/runParametricSweep.m";
assert(isequal(sweepPaths, expected), ...
    'lamb.sweeps must contain only the generic iteration engine.');
end

function assertFittingOwnership(repoRoot, paths)
fittingRoot = "src/+lamb/+fitting/";
expected = fittingRoot + [ ...
    "assessFitIdentifiability.m"
    "assessFitPhysicalQuality.m"
    "applyParameterOverrides.m"
    "buildParameterVector.m"
    "buildParameterBounds.m"
    "computeConstantSpeedBaseline.m"
    "computeDispersionFitMetrics.m"
    "computeDispersionFitResiduals.m"
    "estimateLocalSensitivity.m"
    "evaluateBoundedObjective.m"
    "getFitConfigValue.m"
    "normalizeExperimentalDispersionData.m"
    "solveDispersionFitProblem.m"
    "unpackParameterVector.m"
    "validateExperimentalDispersionData.m"
    "+rayleigh_lamb/rlBuildFitProblem.m"
    "+rayleigh_lamb/rlEvaluateFitModel.m"
    "+rayleigh_lamb/rlFitDispersionData.m"
    "+mrlfe/mrlfeBuildFitFrequencyGrid.m"
    "+mrlfe/mrlfeBuildFitProblem.m"
    "+mrlfe/mrlfeDefaultFitOptions.m"
    "+mrlfe/mrlfeDefaultFitParameters.m"
    "+mrlfe/mrlfeEvaluateFitModel.m"
    "+mrlfe/mrlfeFitDispersionData.m"
    "+acoustoelastic_iop_hgo/aeBuildFitProblem.m"
    "+acoustoelastic_iop_hgo/aeDefaultFitOptions.m"
    "+acoustoelastic_iop_hgo/aeDefaultFitParameters.m"
    "+acoustoelastic_iop_hgo/aeEvaluateFitModel.m"
    "+acoustoelastic_iop_hgo/aeFitDispersionData.m"];
actual = paths(startsWith(paths, fittingRoot) & endsWith(paths, ".m"));
assert(isequal(sort(actual), sort(expected)), ...
    'Canonical fitting ownership changed: %s', strjoin(setxor(actual, expected), ', '));
assert(~isfolder(fullfile(repoRoot, 'analysis', 'fitting')), ...
    'analysis/fitting must remain absent under canonical fitting ownership.');

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
    "unpackParameterVector", "validateExperimentalDispersionData"];
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
for owner = ["app/solver/", "app/fitting/", "app/execution_profiles/", "app/utilities/"]
    owned = paths(startsWith(paths, owner) & endsWith(paths, ".m"));
    assert(~isempty(owned), 'Maintained app owner contains no MATLAB files: %s', owner);
end
executionProfileFiles = paths(startsWith(paths, "app/execution_profiles/") & endsWith(paths, ".m"));
expectedProfiles = "app/execution_profiles/" + [ ...
    "aeResolveExecutionProfile.m"; "guiExecutionProfileValues.m"; ...
    "guiFormatExecutionProfileDiagnostics.m"; "guiNormalizeControlExecutionProfile.m"; ...
    "guiNormalizeExecutionProfile.m"; "mrlfeBuildSurfaceExecutionMetadata.m"; ...
    "mrlfeResolveExecutionProfile.m"; "rlResolveExecutionProfile.m"];
assert(isequal(sort(executionProfileFiles), sort(expectedProfiles)), ...
    'Execution-profile ownership changed: %s', ...
    strjoin(setxor(executionProfileFiles, expectedProfiles), ', '));
utilityFiles = paths(startsWith(paths, "app/utilities/") & endsWith(paths, ".m"));
expectedUtilities = "app/utilities/" + ["guiGetStructField.m"; "guiMergeStructs.m"];
assert(isequal(sort(utilityFiles), sort(expectedUtilities)), ...
    'App utilities must remain a narrow cross-GUI owner: %s', ...
    strjoin(setxor(utilityFiles, expectedUtilities), ', '));
end

function assertDocumentationOwnership(repoRoot, paths)
canonical = ["docs/architecture.md"; "docs/conventions.md"; ...
    "docs/fitting.md"; "docs/validation.md"];
for path = canonical(:).'
    assert(any(paths == path) && isfile(fullfile(repoRoot, path)), ...
        'Missing canonical documentation: %s', path);
end
retiredRoots = ["docs/architecture/", "docs/project/", "docs/repository/", ...
    "docs/validation/", "docs/workflows/"];
assert(~any(startsWith(paths, retiredRoots)), ...
    'Campaign or superseded documentation owner returned.');
assert(~any(contains(paths(startsWith(paths, "docs/")), "/active/")), ...
    'Transition-era active/ documentation must remain absent.');
for family = ["rayleigh_lamb", "mrlfe", "acoustoelastic_iop_hgo"]
    familyDocs = paths(startsWith(paths, "docs/models/" + family + "/") & ...
        endsWith(paths, ".md"));
    assert(~isempty(familyDocs), 'Model documentation scan is empty: %s', family);
end
end

function assertAeModelDiagnosticOwnership(paths)
diagnosticPaths = paths(startsWith(paths, ...
    "src/+lamb/+models/+acoustoelastic_iop_hgo/+diagnostics/") & endsWith(paths, ".m"));
expected = [ ...
    "src/+lamb/+models/+acoustoelastic_iop_hgo/+diagnostics/aeBuildIdentityA0DiagnosticBranch.m"
    "src/+lamb/+models/+acoustoelastic_iop_hgo/+diagnostics/aeScoreBranchIdentityCandidates.m"];
assert(isequal(sort(diagnosticPaths), sort(expected)), ...
    'AE model diagnostic ownership changed: %s', ...
    strjoin(setxor(diagnosticPaths, expected), ', '));
resultPaths = paths(startsWith(paths, ...
    "src/+lamb/+models/+acoustoelastic_iop_hgo/+results/") & endsWith(paths, ".m"));
assert(isequal(resultPaths, ...
    "src/+lamb/+models/+acoustoelastic_iop_hgo/+results/aeBuildResult.m"), ...
    'AE results/ must contain result construction only.');
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
