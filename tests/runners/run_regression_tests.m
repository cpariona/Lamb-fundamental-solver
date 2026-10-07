function summary = run_regression_tests(varargin)
%RUN_REGRESSION_TESTS Run maintained tests once in catalog order.
%   SUMMARY = RUN_REGRESSION_TESTS runs every group, including performance.
%   SUMMARY = RUN_REGRESSION_TESTS("Groups", GROUPS) selects catalog groups.
%   Failed or incomplete tests fail the gate. No baseline-update mode exists.

callerPath = path;
restorePath = onCleanup(@() path(callerPath)); %#ok<NASGU>
projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
catalog = repository_test_catalog(projectRoot);
groups = unique(catalog.Group, 'stable');
parser = inputParser;
parser.addParameter('Groups', groups, ...
    @(x) ischar(x) || isstring(x) || iscellstr(x));
parser.parse(varargin{:});
selected = string(parser.Results.Groups);
assert(~isempty(selected) && all(ismember(selected, groups)), ...
    'lamb:tests:UnknownGroup', 'Groups must be drawn from: %s', strjoin(groups, ', '));
catalog = catalog(ismember(catalog.Group, selected), :);
summary = catalog(:, {'Group', 'Path'});
summary.Passed = false(height(catalog), 1);
summary.CaseCount = zeros(height(catalog), 1);
summary.ElapsedSeconds = zeros(height(catalog), 1);
summary.ErrorIdentifier = strings(height(catalog), 1);
summary.ErrorMessage = strings(height(catalog), 1);
for i = 1:height(catalog)
    if i == 1 || catalog.Group(i) ~= catalog.Group(i-1)
        path(callerPath);
        addpath(projectRoot, fullfile(projectRoot, 'tests', 'tooling'));
        configureTestPath();
    end
    fprintf('\n[%s] %s\n', catalog.Group(i), catalog.Path(i));
    started = tic;
    try
        absolutePath = fullfile(projectRoot, catalog.Path(i));
        [~, name] = fileparts(absolutePath);
        assert(strcmp(which(char(name)), char(absolutePath)), ...
            'lamb:tests:ShadowedTest', 'Test resolves outside its catalog owner: %s', name);
        isNativeSuite = ~isempty(regexp(fileread(absolutePath), ...
            '^\s*function\s+tests\s*=', 'once'));
        if isNativeSuite
            results = runtests(char(absolutePath));
            summary.CaseCount(i) = numel(results);
            assertSuccess(results);
        else
            summary.CaseCount(i) = 1;
            feval(char(name));
        end
        summary.Passed(i) = true;
    catch exception
        summary.ErrorIdentifier(i) = string(exception.identifier);
        summary.ErrorMessage(i) = string(exception.message);
        fprintf(2, '%s\n', getReport(exception, 'extended', 'hyperlinks', 'off'));
    end
    summary.ElapsedSeconds(i) = toc(started);
end
fprintf('\nRegression gate: %d/%d files passed; %d cases executed.\n', ...
    nnz(summary.Passed), height(summary), sum(summary.CaseCount));
assert(all(summary.Passed), 'lamb:tests:RegressionFailure', ...
    'Failed test files: %s', strjoin(summary.Path(~summary.Passed), ', '));
end
