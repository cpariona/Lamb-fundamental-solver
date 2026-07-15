clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

%TEST_MRLFE_VISCOUS_DEFAULT_INTERNAL_TRACKING_GRID Contract test for viscous default tracking.
%
% For etaS > 0, the maintained mRLFE real-k path should use the AE-style
% internal tracking grid by default unless explicitly disabled.

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
options.mrlfeParams = defaultMRLFEParams();
options.mrlfeParams.etaS = 0.05;
options.mrlfeParams.etaL = 0;
options.mrlfeParams.useComplexLambda = false;
options.mrlfeParams.solveComplexK = false;

assert(~options.mrlfeUseInternalTrackingGrid, ...
    'Base mrlfeUseInternalTrackingGrid should remain false in defaults.');
assert(options.mrlfeUseInternalTrackingGridForViscousRealK, ...
    'Viscous real-k internal-grid policy should be enabled by default.');

results = rlComputeFundamentalLambModes(params, options);
assert(isfield(results.models, 'mRLFERealK'), 'etaS > 0 result must expose mRLFERealK.');
branch = results.models.mRLFERealK.branches.A0Like;

assert(numel(branch.frequency) == numel(requestedFrequency), ...
    'Viscous default branch must return requested frequency length.');
assert(max(abs(branch.frequency(:) - requestedFrequency(:))) < 1e-12, ...
    'Viscous default branch must return requested frequency values.');
assert(isfield(results.models.mRLFERealK, 'publicModelResults'), ...
    'Viscous default result must preserve public model results.');
assert(results.models.mRLFERealK.publicModelResults.A0Like.execution.internalEngine == "viscoelastic_adaptive", ...
    'Viscous default public result must use viscoelastic_adaptive engine.');

fprintf('test_mrlfe_viscous_default_internal_tracking_grid passed. etaS > 0 uses public viscoelastic engine.\n');
