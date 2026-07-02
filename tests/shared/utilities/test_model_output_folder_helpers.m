testRoot = tempname(tempdir);
cleanup = onCleanup(@() removeTestRoot(testRoot));

genericOutput = resolveModelOutputFolder(testRoot, 'unit_model', 'case_a');
expectedGeneric = fullfile(testRoot, 'Results', 'unit_model', 'case_a');
assert(strcmp(genericOutput, expectedGeneric), ...
    'resolveModelOutputFolder returned an unexpected path.');
assert(isfolder(genericOutput), ...
    'resolveModelOutputFolder should create the requested output folder.');
assert(strcmp(resolveModelOutputFolder(testRoot, 'unit_model', 'case_a'), expectedGeneric), ...
    'resolveModelOutputFolder should be idempotent for an existing folder.');

assertModelOutputFolder(@aeOutputFolder, testRoot, 'ae_iop_hgo', 'ae_case');
assertModelOutputFolder(@mrlfeOutputFolder, testRoot, 'mrlfe', 'mrlfe_case');
assertModelOutputFolder(@rlOutputFolder, testRoot, 'rayleigh_lamb', 'rl_case');

fprintf('test_model_output_folder_helpers passed. Model output folder helpers preserve Results layout.\n');

function assertModelOutputFolder(helper, testRoot, modelFolderName, taskName)
actual = helper(testRoot, taskName);
expected = fullfile(testRoot, 'Results', modelFolderName, taskName);
assert(strcmp(actual, expected), ...
    'Model output helper returned an unexpected path.');
assert(isfolder(actual), ...
    'Model output helper should create its output folder.');
end

function removeTestRoot(testRoot)
if isfolder(testRoot)
    rmdir(testRoot, 's');
end
end
