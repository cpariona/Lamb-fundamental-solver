function test_maintained_test_structure_contract()
%TEST_MAINTAINED_TEST_STRUCTURE_CONTRACT Enforce canonical direct-test structure.

repoRoot = testRepositoryRoot(mfilename('fullpath'));
runnerRoot = fullfile(repoRoot, 'tests', 'runners');
runnerNames = [ ...
    "run_repository_hygiene_tests"; ...
    "run_quick_contract_tests"; ...
    "run_quick_smoke_tests"; ...
    "run_numerical_regression_tests"; ...
    "run_extended_integration_tests"; ...
    "run_performance_and_benchmark_tests"];

testNames = strings(0, 1);
for i = 1:numel(runnerNames)
    runnerPath = fullfile(runnerRoot, runnerNames(i) + ".m");
    assert(isfile(runnerPath), 'Missing canonical runner: %s.', runnerNames(i));
    text = fileread(runnerPath);
    tokens = regexp(text, '(?m)^\s*(test_[A-Za-z]\w*)\s*;\s*(?:%.*)?$', 'tokens');
    for j = 1:numel(tokens)
        testNames(end + 1, 1) = string(tokens{j}{1}); %#ok<AGROW>
    end
end

testNames = unique(testNames, 'stable');
assert(~isempty(testNames), 'No maintained direct tests were discovered from canonical runners.');

violations = strings(0, 1);
for i = 1:numel(testNames)
    testName = testNames(i);
    testPath = string(which(testName));
    if strlength(testPath) == 0
        violations(end + 1, 1) = testName + ": does not resolve on the configured test path"; %#ok<AGROW>
        continue;
    end

    text = string(fileread(testPath));
    expectedHeader = "^\s*function\s+" + testName + "\s*\(\s*\)";
    if isempty(regexp(text, expectedHeader, 'once'))
        violations(end + 1, 1) = testName + ": must begin with function " + testName + "()"; %#ok<AGROW>
    end

    forbidden = [ ...
        struct('pattern', "(?m)^\s*clear(?:\s|;|$)", 'label', "clear"), ...
        struct('pattern', "(?m)^\s*clc(?:\s|;|$)", 'label', "clc"), ...
        struct('pattern', "(?m)^\s*configureTestPath\s*(?:\(|;|$)", 'label', "configureTestPath"), ...
        struct('pattern', "(?m)^\s*startup\s*(?:\(|;|$)", 'label', "startup"), ...
        struct('pattern', "(?i)assignin\s*\(\s*['\"]base['\"]", 'label', "assignin('base', ...)" )];
    for j = 1:numel(forbidden)
        if ~isempty(regexp(text, forbidden(j).pattern, 'once'))
            violations(end + 1, 1) = testName + ": contains forbidden " + forbidden(j).label; %#ok<AGROW>
        end
    end
end

assert(isempty(violations), 'Maintained test structure violations:\n%s', strjoin(violations, newline));

fprintf('Maintained test structure contract passed for %d direct tests.\n', numel(testNames));
end
