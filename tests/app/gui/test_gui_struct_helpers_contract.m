function test_gui_struct_helpers_contract()
%TEST_GUI_STRUCT_HELPERS_CONTRACT Contract tests for GUI struct helpers.

base = struct('a', 1, 'b', 2);
overlay = struct('b', 20, 'c', [], 'd', false, 'e', "");
merged = guiMergeStructs(base, overlay);

assert(isequal(fieldnames(merged), {'a'; 'b'; 'c'; 'd'; 'e'}), ...
    'guiMergeStructs should preserve existing field order and append new overlay fields.');
assert(merged.a == 1, 'guiMergeStructs should preserve fields absent from overlay.');
assert(merged.b == 20, 'guiMergeStructs should let overlay fields take precedence.');
assert(isfield(merged, 'c') && isempty(merged.c), ...
    'guiMergeStructs should preserve explicitly empty overlay fields.');
assert(merged.d == false, 'guiMergeStructs should preserve explicit false values.');
assert(merged.e == "", 'guiMergeStructs should preserve explicit empty string scalars.');
assert(isequal(guiMergeStructs(base, []), base), ...
    'guiMergeStructs should ignore non-struct overlays.');

source = struct('present', 42, 'emptyValue', [], 'falseValue', false, 'zeroValue', 0, 'emptyString', "");
assert(guiGetStructField(source, 'present', 7) == 42, ...
    'guiGetStructField should return present non-empty values.');
assert(guiGetStructField(source, 'emptyValue', 7) == 7, ...
    'guiGetStructField should treat [] as missing.');
assert(guiGetStructField(source, 'falseValue', true) == false, ...
    'guiGetStructField should preserve explicit false values.');
assert(guiGetStructField(source, 'zeroValue', 7) == 0, ...
    'guiGetStructField should preserve explicit numeric zero values.');
assert(guiGetStructField(source, 'emptyString', "fallback") == "", ...
    'guiGetStructField should preserve explicit empty string scalars.');
assert(guiGetStructField(source, 'missing', "fallback") == "fallback", ...
    'guiGetStructField should return defaults for missing fields.');
assert(guiGetStructField([], 'missing', "fallback") == "fallback", ...
    'guiGetStructField should return defaults for non-struct inputs.');

fprintf('test_gui_struct_helpers_contract passed. GUI struct helpers preserve adapter overlay semantics.\n');
end
