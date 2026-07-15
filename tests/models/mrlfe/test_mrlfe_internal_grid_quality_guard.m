clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

%TEST_MRLFE_INTERNAL_GRID_QUALITY_GUARD Quality guard for the viscous internal-grid policy.
%
% This is not a proof that the internal grid is always better. It is a
% regression guard that prevents the default etaS > 0 policy from becoming
% severely worse than direct tracking in a representative mRLFE A0-like case.

params = rlDefaultParams();
params.fmin = 500;
params.fmax = 4000;
params.numFrequencyPoints = 12;
params.frequencySpacing = "linspace";

options = rlDefaultOptions("Fast");
options.mrlfeInternalTrackingPointFactor = 3;
options.mrlfeInternalTrackingMinPoints = 30;
options.mrlfeInternalTrackingMaxPoints = 90;

summaryTable = compareMRLFETrackingStrategies(params, options, ...
    'BranchName', "A0Like", ...
    'EtaS', 0.05, ...
    'Print', false);

rowDirect = find(summaryTable.Strategy == "direct", 1);
rowGrid = find(summaryTable.Strategy == "internalGrid", 1);
assert(~isempty(rowDirect) && ~isempty(rowGrid), ...
    'Quality guard requires direct and internalGrid rows.');

directValid = summaryTable.ValidFraction(rowDirect);
gridValid = summaryTable.ValidFraction(rowGrid);
directJump = summaryTable.MaxRelJump(rowDirect);
gridJump = summaryTable.MaxRelJump(rowGrid);
directQuality = summaryTable.QualityScore(rowDirect);
gridQuality = summaryTable.QualityScore(rowGrid);

assert(isfinite(directValid) && isfinite(gridValid), ...
    'Valid fractions must be finite.');
assert(gridValid >= max(0, directValid - 0.25), ...
    'Internal-grid valid fraction degraded too much relative to direct tracking.');

if isfinite(directJump) && isfinite(gridJump)
    assert(gridJump <= max(1.0, 4.0 * max(directJump, eps)), ...
        'Internal-grid relative jump became excessively larger than direct tracking.');
end

assert(isfinite(directQuality) && isfinite(gridQuality), ...
    'Quality scores must be finite.');
assert(gridQuality <= max(10.0, 8.0 * max(directQuality, eps)), ...
    'Internal-grid quality score degraded too much relative to direct tracking.');

fprintf('test_mrlfe_internal_grid_quality_guard passed. Internal-grid policy is within quality guard limits.\n');
