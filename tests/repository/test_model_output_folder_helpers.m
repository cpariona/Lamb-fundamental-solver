function test_model_output_folder_helpers()
testRoot = tempname(tempdir);
cleanup = onCleanup(@() removeTestRoot(testRoot)); %#ok<NASGU>

genericOutput = resolveStudyOutputFolder(testRoot, 'unit_model', 'case_a');
expectedGeneric = fullfile(testRoot, 'Results', 'unit_model', 'case_a');
assert(strcmp(genericOutput, expectedGeneric), ...
    'resolveStudyOutputFolder returned an unexpected path.');
assert(isfolder(genericOutput), ...
    'resolveStudyOutputFolder should create the requested output folder.');
assert(strcmp(resolveStudyOutputFolder(testRoot, 'unit_model', 'case_a'), expectedGeneric), ...
    'resolveStudyOutputFolder should be idempotent for an existing folder.');

fprintf('test_model_output_folder_helpers passed. The shared owner preserves Results layout.\n');
end

function removeTestRoot(testRoot)
if isfolder(testRoot)
    rmdir(testRoot, 's');
end
end
