clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

%TEST_MRLFE_ETAS_ZERO_LIMIT Contract test for the unified mRLFE real-k model.
%
% etaS = 0 must be the elastic fluid-loaded limit of the same maintained
% mRLFERealK model, not a separate user-facing model branch.

params = rlDefaultParams();
params.fmin = 500;
params.fmax = 4000;
params.numFrequencyPoints = 14;
params.frequencySpacing = "linspace";

options = rlDefaultOptions("Fast");
options.computeA0 = true;
options.computeS0 = true;
options.computeMRLFE = false;
options.computeMRLFERealK = true;
options.computeMRLFEElasticRealK = false;
options.computeMRLFEViscoRealK = false;
options.computeMRLFEComplexK = false;
options.mrlfeComputeA0Like = true;
options.mrlfeComputeS0Like = true;
options.mrlfeParams = defaultMRLFEParams();
options.mrlfeParams.etaS = 0;
options.mrlfeParams.etaL = 0;
options.mrlfeParams.useComplexLambda = false;
options.mrlfeParams.solveComplexK = false;

results = rlComputeFundamentalLambModes(params, options);

assert(isfield(results, 'models'), 'mRLFE result must contain models.');
assert(isfield(results.models, 'mRLFERealK'), 'etaS = 0 must expose the unified mRLFERealK model.');
assert(isfield(results.models, 'mRLFE'), 'mRLFE compatibility alias must remain available.');
assert(isfield(results.models, 'mRLFEElasticRealK'), 'etaS = 0 reference result must remain available internally.');
assert(~isfield(results.models, 'mRLFEViscoRealK'), 'etaS = 0 must not create a separate viscous raw result.');

realK = results.models.mRLFERealK;
elastic = results.models.mRLFEElasticRealK;
assert(isfield(realK, 'branches'), 'mRLFERealK must contain branches.');
assert(isfield(realK.branches, 'A0Like'), 'mRLFERealK must contain A0Like.');
assert(isfield(realK.branches, 'S0Like'), 'mRLFERealK must contain S0Like.');

assertBranchSame(realK.branches.A0Like, elastic.branches.A0Like, 'A0Like');
assertBranchSame(realK.branches.S0Like, elastic.branches.S0Like, 'S0Like');

fprintf('test_mrlfe_etaS_zero_limit passed. etaS = 0 exposes unified mRLFERealK.\n');

function assertBranchSame(a, b, branchName)
assert(isequal(size(a.Cp), size(b.Cp)), '%s Cp size mismatch.', branchName);
assert(isequal(size(a.frequency), size(b.frequency)), '%s frequency size mismatch.', branchName);
assert(max(abs(a.frequency(:) - b.frequency(:))) < 1e-12, '%s frequency mismatch.', branchName);
assert(max(abs(a.Cp(:) - b.Cp(:)), [], 'omitnan') < 1e-12, '%s Cp mismatch.', branchName);
assert(isequal(a.valid(:), b.valid(:)), '%s valid mask mismatch.', branchName);
end
