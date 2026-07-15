clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

%TEST_MRLFE_INTERNAL_TRACKING_GRID Contract test for optional mRLFE tracking grid.
%
% When enabled, the solver tracks on an internal grid but returns branches on
% the requested frequency values. Vector orientation is not part of this
% contract because different maintained APIs may use row or column vectors.

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

assert(numel(branch.frequency) == numel(requestedFrequency), ...
    'mRLFE branch frequency length must match the requested grid length.');
assert(max(abs(branch.frequency(:) - requestedFrequency(:))) < 1e-12, ...
    'mRLFE branch output frequency must equal the requested grid values.');
assert(numel(branch.Cp) == numel(requestedFrequency), ...
    'mRLFE branch Cp length must match the requested grid.');
assert(isfield(results.models.mRLFERealK, 'diagnostics'), ...
    'mRLFE result must include diagnostics.');
assert(isfield(results.models.mRLFERealK, 'publicModelResults'), ...
    'mRLFE result must preserve public model results.');
assert(results.models.mRLFERealK.publicModelResults.A0Like.execution.effectivePreset == "fast", ...
    'mRLFE embedded public result must use fast preset.');

fprintf('test_mrlfe_internal_tracking_grid passed. Public output returns requested grid values.\n');
