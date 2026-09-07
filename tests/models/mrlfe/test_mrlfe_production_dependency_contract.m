function test_mrlfe_production_dependency_contract()
%TEST_MRLFE_PRODUCTION_DEPENDENCY_CONTRACT Verify retired mRLFE owners are absent from production.

fprintf('\nRunning mRLFE production dependency contract...\n');
fprintf('---------------------------------------------\n');

root = testRepositoryRoot(mfilename('fullpath'));
modelRoot = fullfile(root, 'src', '+lamb', '+models', '+mrlfe');
assert(isfolder(modelRoot), 'Maintained mRLFE package root does not exist: %s', modelRoot);
files = dir(fullfile(modelRoot, '**', '*.m'));
assert(~isempty(files), 'Maintained mRLFE package scan must include MATLAB files.');

filePaths = strings(numel(files), 1);
for iFile = 1:numel(files)
    filePaths(iFile) = string(fullfile(files(iFile).folder, files(iFile).name));
end
normalizedRoot = replace(string(modelRoot), "\", "/") + "/";
relativePaths = erase(replace(filePaths, "\", "/"), normalizedRoot);
assert(any(~contains(relativePaths, "/")), ...
    'Maintained mRLFE scan must include public package-root functions.');
requiredPackages = [ ...
    "+configuration", "+core", "+solvers", "+tracking", ...
    "+policies", "+quality", "+results"];
for iPackage = 1:numel(requiredPackages)
    assert(any(startsWith(relativePaths, requiredPackages(iPackage) + "/")), ...
        'Maintained mRLFE scan missed package %s.', requiredPackages(iPackage));
end

retiredNames = [ ...
    "mrlfeMakePhysicalSeedMode", ...
    "solveMRLFEBranchAdaptiveAtlas", ...
    "mrlfeApplyPhysicalCorridorCut"];

for iFile = 1:numel(filePaths)
    text = string(fileread(filePaths(iFile)));
    for iName = 1:numel(retiredNames)
        assert(~contains(text, retiredNames(iName)), ...
            'Production file still references retired owner %s: %s', ...
            retiredNames(iName), filePaths(iFile));
    end
end

assert(isempty(which('mrlfeMakePhysicalSeedMode')), ...
    'Retired seed helper should not resolve on the MATLAB path.');
assert(isempty(which('solveMRLFEBranchAdaptiveAtlas')), ...
    'Retired adaptive tracker should not resolve on the MATLAB path.');
assert(isempty(which('mrlfeApplyPhysicalCorridorCut')), ...
    'Retired physical-tail helper should not resolve on the MATLAB path.');

fprintf('mRLFE production dependency contract passed.\n');
end
