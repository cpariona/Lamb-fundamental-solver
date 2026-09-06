function test_repository_structure_contract()
%TEST_REPOSITORY_STRUCTURE_CONTRACT Enforce the maintained repository layout.

repoRoot = testRepositoryRoot(mfilename('fullpath'));
paths = gitTrackedPaths(repoRoot);

allowedTopLevel = ["analysis", "app", "docs", "examples", "src", "tests"];
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

sourcePaths = paths(startsWith(paths, ["analysis/", "app/", "examples/", "src/", "tests/"]));
assert(~any(contains(lower(sourcePaths), "/archive/")), ...
    'Archive directories are forbidden under maintained source, example, and test trees.');
assert(~any(startsWith(paths, "docs/") & endsWith(paths, ".m")), ...
    'Production MATLAB files are forbidden under docs/.');

assertTestLocations(paths);
assertTestOwnership(repoRoot, paths);
assertFittingOwnership(repoRoot, paths);
assertAeAnalysisOwnership(paths);
assertAppSurfaceOwnership(paths);
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
    ~startsWith(paths, ["tests/app/", "tests/models/", "tests/runners/", ...
        "tests/shared/", "tests/tooling/"]));
assert(isempty(legacyTestFiles), ...
    'Tests exist outside stable layout locations: %s', ...
    strjoin(legacyTestFiles, ', '));
repoRoot = testRepositoryRoot(mfilename('fullpath'));
assert(~isfolder(fullfile(repoRoot, 'tests', 'fitting')), ...
    'The removed tests/fitting structural exception must not exist.');
assert(~any(startsWith(paths, "analysis/test_inventory/")), ...
    'Generated test-inventory infrastructure must not be tracked under analysis/.');
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

function assertAeAnalysisOwnership(paths)
sweepRoot = "analysis/sweeps/acoustoelastic_iop_hgo/";
plotRoot = "analysis/plotting/sweeps/acoustoelastic_iop_hgo/";
diagnosticRoot = "analysis/diagnostics/acoustoelastic_iop_hgo/";
ioRoot = "analysis/io/acoustoelastic_iop_hgo/";
aePaths = paths(contains(paths, "/acoustoelastic_iop_hgo/") & ...
    startsWith(paths, "analysis/") & endsWith(paths, ".m"));

expected = [ ...
    sweepRoot + [ ...
        "aeDefaultSweepOptions.m"; "aeDefaultSweepParams.m"; ...
        "aeRunSweep.m"; "aeRunGridSweep.m"; ...
        "aeSummarizeSweep.m"; "aeSummarizeGridSweep.m"]
    plotRoot + [ ...
        "aeBuildGridSweepCpCube.m"; "aeBuildSweepPlotData.m"; ...
        "aePlotSweepCp.m"; "aePlotGridSweepCp.m"; ...
        "aePlotGridSweepCpByAxis.m"]
    diagnosticRoot + [ ...
        "aeAnalyzeBranchPersistenceCandidates.m"; ...
        "aeAnalyzeSweepReliability.m"; ...
        "aeAnalyzeTruncationRecovery.m"; "aeComputeModalAtlasForCase.m"; ...
        "aeDiagnoseAtlasA0TruncationCause.m"; ...
        "aeFindTopModalAtlasLocalMinima.m"; ...
        "aeLinkModalAtlasMinimaIntoBranches.m"; ...
        "aeRefineAtlasA0BranchPersistence.m"]
    ioRoot + [ ...
        "aeDeleteExampleFigure.m"; ...
        "aeResolveResultFile.m"; "aeSaveExampleFigure.m"; ...
        "aeWriteSweepOutputs.m"]];
assert(isequal(sort(aePaths), sort(expected)), ...
    'AE analysis responsibility placement changed: %s', ...
    strjoin(setxor(aePaths, expected), ', '));
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
    'analysis/fitting must be retired after canonical fitting migration.');

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
rootMatlab = paths(startsWith(paths, "app/") & count(paths, "/") == 1 & ...
    endsWith(paths, ".m"));
expectedRoot = ["app/FitTool_GUI.m"; "app/LambFundamental_GUI.m"; "app/SweepTool_GUI.m"];
assert(isequal(sort(rootMatlab), sort(expectedRoot)), ...
    'Only the three public GUI entrypoints may remain at app root.');
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
