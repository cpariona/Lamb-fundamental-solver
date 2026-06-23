clear; clc;
startup

%TEST_MRLFE_TRACKING_STRATEGY_COMPARISON Contract test for maintained comparison helper.
%
% The helper compares direct and internal-grid mRLFE tracking without creating
% temporary diagnostic scripts or output files.

params = rlDefaultParams();
params.fmin = 500;
params.fmax = 4000;
params.numFrequencyPoints = 10;
params.frequencySpacing = "linspace";
requestedFrequency = rlBuildFrequencyVector(params);

options = rlDefaultOptions("Fast");
[summaryTable, comparison] = compareMRLFETrackingStrategies(params, options, ...
    'BranchName', "A0Like", ...
    'EtaS', 0.05, ...
    'Print', false);

assert(istable(summaryTable), 'Comparison helper must return a summary table.');
assert(height(summaryTable) == 2, 'Comparison helper must return exactly two strategy rows.');
assert(all(ismember(["direct", "internalGrid"], summaryTable.Strategy)), ...
    'Comparison helper must return direct and internalGrid strategies.');

rowDirect = find(summaryTable.Strategy == "direct", 1);
rowGrid = find(summaryTable.Strategy == "internalGrid", 1);
assert(~summaryTable.UsedInternalGrid(rowDirect), 'Direct strategy must not use internal grid.');
assert(summaryTable.UsedInternalGrid(rowGrid), 'Internal-grid strategy must use internal grid.');
assert(summaryTable.RequestedPoints(rowDirect) == numel(requestedFrequency), ...
    'Direct requested-point count must match requested frequency grid.');
assert(summaryTable.RequestedPoints(rowGrid) == numel(requestedFrequency), ...
    'Internal-grid requested-point count must match requested frequency grid.');
assert(summaryTable.TrackingPoints(rowGrid) > summaryTable.TrackingPoints(rowDirect), ...
    'Internal-grid tracking-point count must exceed direct tracking-point count.');
assert(isfield(comparison, 'directRaw') && isfield(comparison, 'internalGridRaw'), ...
    'Comparison output must preserve raw results for both strategies.');
assert(isfield(comparison, 'summaryTable'), 'Comparison output must preserve summaryTable.');

fprintf('test_mrlfe_tracking_strategy_comparison passed. Direct/internal-grid comparison helper works.\n');
