function test_ae_result_file_compatibility()
%TEST_AE_RESULT_FILE_COMPATIBILITY Characterize canonical and legacy reads.

root = string(tempname);
cleanup = onCleanup(@()removeTemporaryRoot(root));
mkdir(root);

canonicalFolder = fullfile(root, 'Results', 'ae_iop_hgo', 'iop_sweep');
legacyFolder = fullfile(root, 'Results', 'sweep_iop');
mkdir(canonicalFolder);
mkdir(legacyFolder);
canonicalFile = fullfile(canonicalFolder, 'iop_sweep_workspace.mat');
legacyFile = fullfile(legacyFolder, 'sweep_iop_workspace.mat');

createEmptyFile(legacyFile);
resolved = aeResolveResultFile(root, 'iop_sweep', ...
    'iop_sweep_workspace.mat', 'sweep_iop', 'sweep_iop_workspace.mat');
assert(samePath(resolved, legacyFile), ...
    'The documented legacy result fallback changed.');

createEmptyFile(canonicalFile);
resolved = aeResolveResultFile(root, 'iop_sweep', ...
    'iop_sweep_workspace.mat', 'sweep_iop', 'sweep_iop_workspace.mat');
assert(samePath(resolved, canonicalFile), ...
    'The canonical AE result path must take precedence.');

delete(canonicalFile);
delete(legacyFile);
didReject = false;
try
    aeResolveResultFile(root, 'iop_sweep', ...
        'iop_sweep_workspace.mat', 'sweep_iop', 'sweep_iop_workspace.mat');
catch ME
    didReject = contains(ME.message, canonicalFile) && ...
        contains(ME.message, legacyFile);
end
assert(didReject, 'Missing-result error must identify both checked locations.');

fprintf('AE result-file compatibility contract passed.\n');
end

function createEmptyFile(path)
fileId = fopen(path, 'w');
assert(fileId >= 0, 'Unable to create compatibility fixture: %s', path);
fclose(fileId);
end

function tf = samePath(actual, expected)
tf = strcmpi(strrep(string(actual), '/', '\'), strrep(string(expected), '/', '\'));
end

function removeTemporaryRoot(root)
if isfolder(root)
    rmdir(root, 's');
end
end
