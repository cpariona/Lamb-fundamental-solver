function test_public_test_wrapper_contract()
%TEST_PUBLIC_TEST_WRAPPER_CONTRACT Guard the small public wrapper surface.

repoRoot = testRepositoryRoot(mfilename('fullpath'));
expectedNames = [ ...
    "run_acoustoelastic_smoke_tests"
    "run_all_smoke_tests"
    "run_core_smoke_tests"
    "run_gui_smoke_tests"
    "run_mrlfe_smoke_tests"];
expectedPaths = "tests/" + expectedNames + ".m";

[status, output] = system(sprintf('git -C "%s" ls-files "tests/*.m"', repoRoot));
assert(status == 0, 'Could not enumerate root test wrappers.');
actualPaths = replace(splitlines(string(strtrim(output))), "\", "/");
actualPaths(actualPaths == "") = [];
actualPaths = actualPaths(count(actualPaths, "/") == 1);
assert(isequal(sort(actualPaths(:)), sort(expectedPaths(:))), ...
    'Root test wrappers differ from the explicit public set: %s', ...
    strjoin(setxor(actualPaths, expectedPaths), ', '));

for i = 1:numel(expectedNames)
    source = string(fileread(fullfile(repoRoot, expectedPaths(i))));
    executable = executableMatlabText(source);
    calls = regexp(executable, ...
        'runRepositoryTestRunner\s*\(\s*mfilename\(''fullpath''\)\s*,\s*''([A-Za-z]\w*)''\s*\)', ...
        'tokens');
    assert(isscalar(calls) && string(calls{1}{1}) == expectedNames(i), ...
        'Public wrapper must delegate once to its same-named canonical runner: %s', ...
        expectedPaths(i));
    assert(isfile(fullfile(repoRoot, 'tests', 'runners', expectedNames(i) + ".m")), ...
        'Public wrapper is missing its canonical runner: %s', expectedNames(i));
    assert(isempty(regexp(executable, '(?<![A-Za-z0-9_])test_[A-Za-z0-9_]*\s*[;(]', 'once')), ...
        'Public wrapper contains validation logic: %s', expectedPaths(i));
end

fprintf('Public test-wrapper contract passed.\n');
end

function text = executableMatlabText(text)
text = regexprep(text, '%\{[\s\S]*?%\}', ' ');
text = regexprep(text, '%[^\r\n]*', ' ');
end
