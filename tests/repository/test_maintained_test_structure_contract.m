function test_maintained_test_structure_contract()
%TEST_MAINTAINED_TEST_STRUCTURE_CONTRACT Enforce canonical maintained-test structure.

repoRoot = testRepositoryRoot(mfilename('fullpath'));
testPaths = trackedTestFiles(repoRoot);
assert(~isempty(testPaths), 'No maintained test_*.m files were discovered.');

violations = strings(0, 1);
for i = 1:numel(testPaths)
    relativePath = testPaths(i);
    absolutePath = fullfile(repoRoot, strrep(relativePath, '/', filesep));
    [~, testName] = fileparts(relativePath);
    testName = string(testName);
    text = string(fileread(absolutePath));

    directHeader = "^\s*function\s+" + testName + "\s*\(\s*\)";
    suiteHeader = "^\s*function\s+tests\s*=\s*" + testName + "(?:\s*\(\s*\))?";
    isDirect = ~isempty(regexp(text, directHeader, 'once'));
    isFunctionTestSuite = ~isempty(regexp(text, suiteHeader, 'once')) && ...
        contains(text, 'functiontests(localfunctions)');

    if ~(isDirect || isFunctionTestSuite)
        violations(end + 1, 1) = relativePath + ...
            ": must begin with function " + testName + "() or a native functiontests suite"; %#ok<AGROW>
    end

    forbidden = [ ...
        struct('pattern', "(?m)^\s*clear(?:\s|;|$)", 'label', "clear"), ...
        struct('pattern', "(?m)^\s*clc(?:\s|;|$)", 'label', "clc"), ...
        struct('pattern', "(?m)^\s*configureTestPath\s*(?:\(|;|$)", 'label', "configureTestPath"), ...
        struct('pattern', "(?m)^\s*assignin\s*\(\s*'base'", 'label', "assignin('base', ...)" )];
    for j = 1:numel(forbidden)
        if ~isempty(regexp(text, forbidden(j).pattern, 'once'))
            violations(end + 1, 1) = relativePath + ": contains forbidden " + forbidden(j).label; %#ok<AGROW>
        end
    end

    % This test intentionally exercises startup itself and restores caller path.
    if testName ~= "test_startup_path_policy" && ...
            ~isempty(regexp(text, "(?m)^\s*startup\s*(?:\(|;|$)", 'once'))
        violations(end + 1, 1) = relativePath + ": contains forbidden startup"; %#ok<AGROW>
    end
end

assert(isempty(violations), 'Maintained test structure violations:\n%s', strjoin(violations, newline));

fprintf('Maintained test structure contract passed for %d tracked tests.\n', numel(testPaths));
end

function paths = trackedTestFiles(repoRoot)
[status, output] = system(sprintf('git -C "%s" ls-files "tests/**/*.m"', repoRoot));
assert(status == 0, 'Could not enumerate tracked MATLAB tests.');
paths = replace(splitlines(string(strtrim(output))), "\", "/");
paths(paths == "") = [];
names = strings(size(paths));
for i = 1:numel(paths)
    [~, name] = fileparts(paths(i));
    names(i) = string(name);
end
paths = paths(startsWith(names, "test_"));
end
