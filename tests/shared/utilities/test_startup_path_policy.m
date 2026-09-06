function test_startup_path_policy()
%TEST_STARTUP_PATH_POLICY Production isolation and unique public resolution.
callerPath = path;
restorePath = onCleanup(@() path(callerPath)); %#ok<NASGU>
repoRoot = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
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
    parts = split(replace(entry, "\", "/"), "/");
    assert(~any(ismember(lower(parts), ["archive","figures","outputs","generated"])), ...
        'Generated or archived directories must not enter the path.');
end
publicNames = ["runApp","LambFundamental_GUI","FitTool_GUI", ...
    "lamb.models.rayleigh_lamb.rlDefaultParams","lamb.models.rayleigh_lamb.rlDefaultOptions","lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes", ...
    "lamb.models.rayleigh_lamb.approximations.rlComputeAnalyticalApproximations","lamb.models.mrlfe.mrlfeDefaultParameters", ...
    "lamb.models.mrlfe.mrlfeDefaultOptions","lamb.models.mrlfe.mrlfeSolve","lamb.models.acoustoelastic_iop_hgo.defaultAcoustoelasticIOPHGOOptions", ...
    "lamb.models.acoustoelastic_iop_hgo.solveAcoustoelasticIOPHGOBranch", ...
    "lamb.sweeps.runParametricSweep"];
for name = publicNames
    locations = which(char(name), '-all');
    assert(numel(locations) == 1, 'Public API shadowing: %s', name);
end
assert(isempty(which('test_rl_fit_synthetic_A0')), 'Test bodies leaked into startup.');
assert(isempty(which('benchmarkMRLFEExecutionProfiles')), 'Benchmark leaked into startup.');
assert(isempty(which('SweepTool_GUI')), 'Retired SweepTool GUI leaked into startup.');
assert(isempty(which('runAcoustoelasticSensitivity')), 'Studies leaked into startup.');
fprintf('Startup path isolation and public API resolution passed.\n');
end
