function test_startup_path_policy()
%TEST_STARTUP_PATH_POLICY Production isolation and unique public resolution.
callerPath = path;
restorePath = onCleanup(@() path(callerPath)); %#ok<NASGU>
repoRoot = testRepositoryRoot(mfilename('fullpath'));
startup;
entries = string(strsplit(path, pathsep));
testRoot = string(fullfile(repoRoot, 'tests'));
exampleRoot = string(fullfile(repoRoot, 'examples'));
studyRoot = string(fullfile(repoRoot, 'studies'));
assert(~any(startsWith(entries, exampleRoot)), 'Examples must be opt-in.');
assert(~any(startsWith(entries, studyRoot)), 'Studies must be opt-in.');
testEntries = entries(startsWith(entries, testRoot));
assert(isequal(testEntries, string(fullfile(repoRoot, 'tests', 'runners'))), ...
    'Only the six runner launchers may be on the production path.');
for entry = entries(startsWith(entries, string(repoRoot)))
    parts = split(replace(entry, "\\", "/"), "/");
    assert(~any(ismember(lower(parts), ["archive","figures","outputs","generated"])), ...
        'Generated or archived directories must not enter the path.');
end
publicOwners = [ ...
    "runApp", "runApp.m"
    "LambFundamental_GUI", "app/LambFundamental_GUI.m"
    "FitTool_GUI", "app/FitTool_GUI.m"
    "lamb.models.rayleigh_lamb.rlDefaultParams", "src/+lamb/+models/+rayleigh_lamb/rlDefaultParams.m"
    "lamb.models.rayleigh_lamb.rlDefaultOptions", "src/+lamb/+models/+rayleigh_lamb/rlDefaultOptions.m"
    "lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes", "src/+lamb/+models/+rayleigh_lamb/rlComputeFundamentalLambModes.m"
    "lamb.models.rayleigh_lamb.approximations.rlComputeAnalyticalApproximations", "src/+lamb/+models/+rayleigh_lamb/+approximations/rlComputeAnalyticalApproximations.m"
    "lamb.models.mrlfe.mrlfeDefaultParameters", "src/+lamb/+models/+mrlfe/mrlfeDefaultParameters.m"
    "lamb.models.mrlfe.mrlfeDefaultOptions", "src/+lamb/+models/+mrlfe/mrlfeDefaultOptions.m"
    "lamb.models.mrlfe.mrlfeSolve", "src/+lamb/+models/+mrlfe/mrlfeSolve.m"
    "lamb.models.acoustoelastic_iop_hgo.aeDefaultOptions", "src/+lamb/+models/+acoustoelastic_iop_hgo/aeDefaultOptions.m"
    "lamb.models.acoustoelastic_iop_hgo.aeSolveBranch", "src/+lamb/+models/+acoustoelastic_iop_hgo/aeSolveBranch.m"
    "lamb.fitting.rayleigh_lamb.rlFitDispersionData", "src/+lamb/+fitting/+rayleigh_lamb/rlFitDispersionData.m"
    "lamb.fitting.rayleigh_lamb.rlEvaluateFitModel", "src/+lamb/+fitting/+rayleigh_lamb/rlEvaluateFitModel.m"
    "lamb.fitting.mrlfe.mrlfeFitDispersionData", "src/+lamb/+fitting/+mrlfe/mrlfeFitDispersionData.m"
    "lamb.fitting.mrlfe.mrlfeEvaluateFitModel", "src/+lamb/+fitting/+mrlfe/mrlfeEvaluateFitModel.m"
    "lamb.fitting.mrlfe.mrlfeDefaultFitParameters", "src/+lamb/+fitting/+mrlfe/mrlfeDefaultFitParameters.m"
    "lamb.fitting.mrlfe.mrlfeDefaultFitOptions", "src/+lamb/+fitting/+mrlfe/mrlfeDefaultFitOptions.m"
    "lamb.fitting.acoustoelastic_iop_hgo.aeFitDispersionData", "src/+lamb/+fitting/+acoustoelastic_iop_hgo/aeFitDispersionData.m"
    "lamb.fitting.acoustoelastic_iop_hgo.aeEvaluateFitModel", "src/+lamb/+fitting/+acoustoelastic_iop_hgo/aeEvaluateFitModel.m"
    "lamb.fitting.acoustoelastic_iop_hgo.aeDefaultFitParameters", "src/+lamb/+fitting/+acoustoelastic_iop_hgo/aeDefaultFitParameters.m"
    "lamb.fitting.acoustoelastic_iop_hgo.aeDefaultFitOptions", "src/+lamb/+fitting/+acoustoelastic_iop_hgo/aeDefaultFitOptions.m"
    "lamb.sweeps.runParametricSweep", "src/+lamb/+sweeps/runParametricSweep.m"];
for i = 1:size(publicOwners, 1)
    name = publicOwners(i, 1);
    expected = string(fullfile(repoRoot, replace(publicOwners(i, 2), "/", filesep)));
    locations = string(which(char(name), '-all'));
    assert(isscalar(locations), 'Public API must resolve exactly once: %s', name);
    assert(locations == expected, ...
        'Public API %s resolves outside production. Expected %s, got %s.', ...
        name, expected, locations);
end
assert(isempty(which('test_rl_fit_synthetic_A0')), 'Test bodies leaked into startup.');
assert(isempty(which('mrlfeBenchmarkExecutionProfiles')), 'Benchmark leaked into startup.');
assert(isempty(which('SweepTool_GUI')), 'Retired SweepTool GUI leaked into startup.');
assert(isempty(which('aeRunSensitivity')), 'Studies leaked into startup.');
assert(isempty(which('aeDiagnoseModalAtlas')), 'Solver diagnostics leaked into startup.');
fprintf('Startup path isolation and public API resolution passed.\n');
end
