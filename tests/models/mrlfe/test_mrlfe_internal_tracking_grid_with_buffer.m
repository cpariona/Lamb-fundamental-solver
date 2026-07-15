clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

%TEST_MRLFE_INTERNAL_TRACKING_GRID_WITH_BUFFER Contract test for the optimized mRLFE path.
%
% The optional internal tracking grid must also work for etaS > 0 when the
% solver receives a compatible etaS = 0 reference buffer. This covers the path
% targeted by the AE-style optimization strategy.

params = rlDefaultParams();
params.fmin = 500;
params.fmax = 4000;
params.numFrequencyPoints = 10;
params.frequencySpacing = "linspace";
requestedFrequency = rlBuildFrequencyVector(params);

baseOptions = rlDefaultOptions("Fast");
baseOptions.computeA0 = true;
baseOptions.computeS0 = false;
baseOptions.computeMRLFE = false;
baseOptions.computeMRLFERealK = true;
baseOptions.computeMRLFEComplexK = false;
baseOptions.mrlfeComputeA0Like = true;
baseOptions.mrlfeComputeS0Like = false;
baseOptions.mrlfeParams = defaultMRLFEParams();
baseOptions.mrlfeParams.etaL = 0;
baseOptions.mrlfeParams.useComplexLambda = false;
baseOptions.mrlfeParams.solveComplexK = false;

elasticOptions = baseOptions;
elasticOptions.mrlfeParams.etaS = 0;
elasticReference = rlComputeFundamentalLambModes(params, elasticOptions);
assert(isfield(elasticReference.models, 'mRLFERealK'), 'etaS = 0 reference must expose mRLFERealK.');
assert(isfield(elasticReference.models.mRLFERealK.branches, 'A0Like'), 'etaS = 0 reference must include A0Like.');

viscousOptions = baseOptions;
viscousOptions.mrlfeParams.etaS = 0.05;
viscousOptions.mrlfeUseInternalTrackingGrid = true;
viscousOptions.mrlfeInternalTrackingPointFactor = 3;
viscousOptions.mrlfeInternalTrackingMinPoints = 25;
viscousOptions.mrlfeInternalTrackingMaxPoints = 80;
viscousOptions.mrlfeElasticReferenceResult = elasticReference.models.mRLFERealK;

viscousResults = rlComputeFundamentalLambModes(params, viscousOptions);
assert(isfield(viscousResults.models, 'mRLFERealK'), 'etaS > 0 result must expose unified mRLFERealK.');
assert(isfield(viscousResults.models, 'mRLFEElasticRealK'), 'etaS > 0 result must preserve the etaS = 0 reference internally.');
assert(isfield(viscousResults.models, 'mRLFEViscoRealK'), 'etaS > 0 result must preserve the raw viscous branch internally.');

branch = viscousResults.models.mRLFERealK.branches.A0Like;
assert(numel(branch.frequency) == numel(requestedFrequency), ...
    'Buffered viscous branch frequency length must match requested grid length.');
assert(max(abs(branch.frequency(:) - requestedFrequency(:))) < 1e-12, ...
    'Buffered viscous branch output frequency must equal requested grid values.');
assert(numel(branch.Cp) == numel(requestedFrequency), ...
    'Buffered viscous branch Cp length must match requested grid length.');
assert(any(branch.valid & isfinite(branch.Cp)), ...
    'Buffered viscous branch must contain at least one finite valid Cp point.');

referenceBranch = viscousResults.models.mRLFEElasticRealK.branches.A0Like;
providedBranch = elasticReference.models.mRLFERealK.branches.A0Like;
assert(max(abs(referenceBranch.frequency(:) - providedBranch.frequency(:))) < 1e-12, ...
    'Internal-grid viscous path must preserve the provided etaS = 0 reference frequency.');
assert(max(abs(referenceBranch.Cp(:) - providedBranch.Cp(:)), [], 'omitnan') < 1e-12, ...
    'Internal-grid viscous path must preserve the provided etaS = 0 reference Cp.');

assert(isfield(viscousResults.models.mRLFERealK, 'publicModelResults'), ...
    'Buffered viscous result must preserve public model results.');
assert(viscousResults.models.mRLFERealK.publicModelResults.A0Like.execution.internalEngine == "viscoelastic_adaptive", ...
    'Buffered viscous public result must use viscoelastic_adaptive engine.');

fprintf('test_mrlfe_internal_tracking_grid_with_buffer passed. Public etaS > 0 buffer path works.\n');
