startup

repoRoot = testRepositoryRoot(mfilename('fullpath'));
pathEntries = strsplit(path, pathsep);

assertPathContains(pathEntries, fullfile(repoRoot, 'examples', 'mrlfe', 'diagnostics'), ...
    'Maintained mRLFE diagnostics folder should remain on the MATLAB path.');
assertPathContains(pathEntries, fullfile(repoRoot, 'examples', 'acoustoelastic_iop_hgo', 'diagnostics'), ...
    'Maintained AE diagnostics folder should remain on the MATLAB path.');
assertPathContains(pathEntries, fullfile(repoRoot, 'examples', 'rayleigh_lamb', 'sweeps'), ...
    'Maintained Rayleigh-Lamb sweeps folder should remain on the MATLAB path.');

assertPathExcludes(pathEntries, fullfile(repoRoot, 'examples', 'mrlfe', 'diagnostics', 'archive'), ...
    'Archived mRLFE diagnostics should not be added by startup.');
assertNoFolderNameOnPath(pathEntries, repoRoot, 'examples', 'figures', ...
    'Generated example figure folders should not be added by startup.');

fprintf('test_startup_path_policy passed. Archived diagnostics and generated figure folders are excluded from startup path.\n');

function assertPathContains(pathEntries, expectedFolder, message)
assert(any(strcmp(pathEntries, expectedFolder)), message);
end

function assertPathExcludes(pathEntries, excludedFolder, message)
assert(~any(strcmp(pathEntries, excludedFolder)), message);
end

function assertNoFolderNameOnPath(pathEntries, repoRoot, requiredAncestor, folderName, message)
for i = 1:numel(pathEntries)
    entry = pathEntries{i};
    if startsWith(entry, fullfile(repoRoot, requiredAncestor)) && hasFolderName(entry, folderName)
        error(message);
    end
end
end

function tf = hasFolderName(folder, folderName)
parts = regexp(folder, '[\\/]', 'split');
tf = any(strcmpi(parts, folderName));
end
