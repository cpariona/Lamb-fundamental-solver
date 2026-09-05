function test_model_output_folder_helpers()
testRoot = tempname(tempdir);
cleanup = onCleanup(@() removeTestRoot(testRoot)); %#ok<NASGU>

genericOutput = resolveModelOutputFolder(testRoot, 'unit_model', 'case_a');
expectedGeneric = fullfile(testRoot, 'Results', 'unit_model', 'case_a');
assert(strcmp(genericOutput, expectedGeneric), ...
    'resolveModelOutputFolder returned an unexpected path.');
assert(isfolder(genericOutput), ...
    'resolveModelOutputFolder should create the requested output folder.');
assert(strcmp(resolveModelOutputFolder(testRoot, 'unit_model', 'case_a'), expectedGeneric), ...
    'resolveModelOutputFolder should be idempotent for an existing folder.');

fprintf('test_model_output_folder_helpers passed. The shared owner preserves Results layout.\n');
end

function removeTestRoot(testRoot)
if isfolder(testRoot)
    rmdir(testRoot, 's');
end
end
