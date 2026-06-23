clear; clc;
startup

%TEST_MRLFE_INTERNAL_TRACKING_GRID Contract test for optional mRLFE tracking grid.
%
% When enabled, the solver tracks on an internal grid but returns branches on
% the requested frequency grid. This mirrors the AE-style internal tracking
% policy without changing the external result shape.

params = rlDefaultParams();
params.fmin = 500;
params.fmax = 4000;
params.numFrequencyPoints = 10;
params.frequencySpacing = "linspace";
requestedFrequency = rlBuildFrequencyVector(params);

options = rlDefaultOptions("Fast");
options.computeA0 = true;
options.computeS0 = false;
options.computeMRLFE = false;
options.computeMRLFERealK = true;
options.computeMRLFEComplexK = false;
options.mrlfeComputeA0Like = true;
options.mrlfeComputeS0Like = false;
options.mrlfeUseInternalTrackingGrid = true;
options.mrlfeInternalTrackingPointFactor = 3;
options.mrlfeInternalTrackingMinPoints = 25;
options.mrlfeInternalTrackingMaxPoints = 80;
options.mrlfeParams = defaultMRLFEParams();
options.mrlfeParams.etaS = 0;
options.mrlfeParams.etaL = 0;
options.mrlfeParams.useComplexLambda = false;
options.mrlfeParams.solveComplexK = false;

results = rlComputeFundamentalLambModes(params, options);
assert(isfield(results.models, 'mRLFERealK'), 'mRLFERealK result is missing.');
branch = results.models.mRLFERealK.branches.A0Like;

assert(isequal(size(branch.frequency), size(requestedFrequency)), ...
    'mRLFE branch frequency shape must match the requested grid.');
assert(max(abs(branch.frequency(:) - requestedFrequency(:))) < 1e-12, ...
    'mRLFE branch output frequency must equal the requested grid.');
assert(numel(branch.Cp) == numel(requestedFrequency), ...
    'mRLFE branch Cp length must match the requested grid.');
assert(isfield(branch, 'internalTracking') && branch.internalTracking.used, ...
    'mRLFE branch must report that the internal tracking grid was used.');
assert(numel(branch.internalTracking.trackingFrequency) > numel(requestedFrequency), ...
    'Internal tracking grid must be denser than the requested grid in this test.');
assert(isfield(results.models.mRLFERealK, 'diagnostics'), ...
    'mRLFE result must include diagnostics.');
assert(results.models.mRLFERealK.diagnostics.usedInternalTrackingGrid, ...
    'mRLFE diagnostics must report internal tracking grid usage.');
assert(results.models.mRLFERealK.diagnostics.trackingPointCount > results.models.mRLFERealK.diagnostics.requestedPointCount, ...
    'mRLFE diagnostics must report a denser tracking grid.');

fprintf('test_mrlfe_internal_tracking_grid passed. Internal grid output returns to requested grid.\n');
