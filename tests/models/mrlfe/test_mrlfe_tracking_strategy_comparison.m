clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

%TEST_MRLFE_TRACKING_STRATEGY_COMPARISON Contract test for maintained comparison helper.
%
% The helper preserves its comparison-shaped output, but the maintained public
% production solver no longer exposes a separate internal-grid route.

params = rlDefaultParams();
params.fmin = 500;
params.fmax = 4000;
params.numFrequencyPoints = 10;
params.frequencySpacing = "linspace";
requestedFrequency = rlBuildFrequencyVector(params);
branchName = "A0Like";

options = rlDefaultOptions("Fast");
[summaryTable, comparison] = compareMRLFETrackingStrategies(params, options, ...
    'BranchName', branchName, ...
    'EtaS', 0.05, ...
    'Print', false);

assert(istable(summaryTable), 'Comparison helper must return a summary table.');
assert(height(summaryTable) == 2, 'Comparison helper must return exactly two strategy rows.');
assert(all(ismember(["direct", "internalGrid"], summaryTable.Strategy)), ...
    'Comparison helper must return direct and internalGrid strategies.');

rowDirect = find(summaryTable.Strategy == "direct", 1);
rowGrid = find(summaryTable.Strategy == "internalGrid", 1);
assert(~summaryTable.UsedInternalGrid(rowDirect), 'Direct strategy must not use internal grid.');
assert(~summaryTable.UsedInternalGrid(rowGrid), 'Public solver should not report legacy internal-grid metadata.');
assert(summaryTable.RequestedPoints(rowDirect) == numel(requestedFrequency), ...
    'Direct requested-point count must match requested frequency grid.');
assert(summaryTable.RequestedPoints(rowGrid) == numel(requestedFrequency), ...
    'Internal-grid requested-point count must match requested frequency grid.');
assert(summaryTable.TrackingPoints(rowGrid) == summaryTable.TrackingPoints(rowDirect), ...
    'Public solver should use the same tracking-point count for both comparison rows.');
assert(isfield(comparison, 'directRaw') && isfield(comparison, 'internalGridRaw'), ...
    'Comparison output must preserve raw results for both strategies.');
assert(isfield(comparison, 'summaryTable'), 'Comparison output must preserve summaryTable.');

directBranch = selectBranch(comparison.direct, branchName);
gridBranch = selectBranch(comparison.internalGrid, branchName);
assert(isequaln(directBranch.Cp(:), gridBranch.Cp(:)), ...
    'Public solver comparison rows must preserve identical phase velocity values.');
assert(isequal(getValidMask(directBranch), getValidMask(gridBranch)), ...
    'Public solver comparison rows must preserve identical valid masks.');

fprintf('test_mrlfe_tracking_strategy_comparison passed. Public comparison helper returns stable paired results.\n');

function branch = selectBranch(model, branchName)
switch string(branchName)
    case "A0Like"
        branch = selectFirstAvailable(model.branches, ["A0Like", "A0"]);
    case "S0Like"
        branch = selectFirstAvailable(model.branches, ["S0Like", "S0"]);
    otherwise
        error('test_mrlfe_tracking_strategy_comparison:UnsupportedBranch', ...
            'Unsupported branch "%s".', branchName);
end
end

function validMask = getValidMask(branch)
if isfield(branch, 'validMask')
    validMask = branch.validMask(:);
elseif isfield(branch, 'valid')
    validMask = branch.valid(:);
else
    error('test_mrlfe_tracking_strategy_comparison:MissingValidMask', ...
        'Branch does not expose validMask or valid.');
end
end

function branch = selectFirstAvailable(branches, names)
for i = 1:numel(names)
    fieldName = char(names(i));
    if isfield(branches, fieldName)
        branch = branches.(fieldName);
        return;
    end
end
error('test_mrlfe_tracking_strategy_comparison:MissingBranch', ...
    'None of the expected branch fields were present.');
end
