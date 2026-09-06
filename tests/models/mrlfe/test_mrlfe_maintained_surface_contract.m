function test_mrlfe_maintained_surface_contract()
%TEST_MRLFE_MAINTAINED_SURFACE_CONTRACT Guard the maintained mRLFE surface.

repoRoot = testRepositoryRoot(mfilename('fullpath'));
entrypointsText = string(fileread(fullfile(repoRoot, 'docs', 'repository', ...
    'maintained_entrypoints.md')));
for name = ["lamb.models.mrlfe.mrlfeSolve", "lamb.models.mrlfe.mrlfeDefaultParameters", "lamb.models.mrlfe.mrlfeDefaultOptions"]
    assert(contains(entrypointsText, name), ...
        'Maintained entrypoint documentation is missing %s.', name);
end

exampleRoot = fullfile(repoRoot, 'examples', 'mrlfe');
expected = [ ...
    "basic/run_default_mrlfe.m"
    "fitting/fit_mrlfe_A0Like.m"
    "sweeps/mrlfe_sweep_etaS_A0Like.m"
    "diagnostics/validate_grid_presets.m"];
files = dir(fullfile(exampleRoot, '**', '*.m'));
actual = strings(numel(files), 1);
for i = 1:numel(files)
    fullPath = replace(string(fullfile(files(i).folder, files(i).name)), "\", "/");
    rootPrefix = replace(string(exampleRoot), "\", "/") + "/";
    actual(i) = erase(fullPath, rootPrefix);
end
assert(isequal(sort(actual), sort(expected)), ...
    'Maintained mRLFE examples/diagnostics changed: %s', ...
    strjoin(setxor(actual, expected), ', '));

for i = 1:numel(expected)
    [~, name] = fileparts(expected(i));
    expectedPath = fullfile(exampleRoot, expected(i));
    assert(isfile(expectedPath), 'Explicit example path is missing: %s.', name);
    assert(isempty(which(name)), 'Examples must not be globally on the path: %s.', name);
end

modelFiles = dir(fullfile(repoRoot, 'src', '+lamb', '+models', '+mrlfe', '**', '*.m'));
assert(~isempty(modelFiles), ...
    'Maintained mRLFE ownership-prefix scan must include MATLAB files.');
for i = 1:numel(modelFiles)
    assert(startsWith(string(erase(modelFiles(i).name, '.m')), "mrlfe"), ...
        'mRLFE model function lacks its ownership prefix: %s.', modelFiles(i).name);
end

fprintf('mRLFE maintained surface contract passed.\n');
end
