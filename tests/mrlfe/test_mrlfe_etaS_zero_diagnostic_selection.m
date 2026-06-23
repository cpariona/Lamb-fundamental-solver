clear; clc;
startup

%TEST_MRLFE_ETAS_ZERO_DIAGNOSTIC_SELECTION
% Protect the diagnostic selection rule: etaS = 0 is the elastic real-k limit
% and must not require the viscoelastic raw model field.

params = rlDefaultParams();
params.fmin = 500;
params.fmax = 1200;
params.numFrequencyPoints = 8;
params.frequencySpacing = "linspace";
params.E = 100e3;
params.mu = params.E / (2 * (1 + params.nu));

options = rlDefaultOptions("Fast");
options.computeA0 = true;
options.computeS0 = false;
options.computeMRLFERealK = true;
options.computeMRLFEViscoRealK = false;
options.mrlfeComputeA0Like = true;
options.mrlfeComputeS0Like = false;
options.mrlfeParams = defaultMRLFEParams();
options.mrlfeParams.etaS = 0;
options.mrlfeParams.etaL = 0;
options.mrlfeParams.useComplexLambda = false;

results = rlComputeFundamentalLambModes(params, options);
assert(isfield(results.models, 'mRLFERealK'), ...
    'etaS = 0 diagnostic selection must expose mRLFERealK.');
assert(isfield(results.models, 'mRLFEElasticRealK'), ...
    'etaS = 0 diagnostic selection must expose mRLFEElasticRealK.');
assert(~isfield(results.models, 'mRLFEViscoRealK'), ...
    'etaS = 0 diagnostic selection should not require mRLFEViscoRealK.');

branches = selectRealKBranchesForDiagnostic(results, 0);
assert(isfield(branches, 'A0Like'), ...
    'etaS = 0 diagnostic selection must return A0Like branches from real-k results.');

options.mrlfeParams.etaS = 0.05;
options.computeMRLFEViscoRealK = true;
resultsVisco = rlComputeFundamentalLambModes(params, options);
assert(isfield(resultsVisco.models, 'mRLFEViscoRealK'), ...
    'etaS > 0 diagnostic selection must expose mRLFEViscoRealK.');
branchesVisco = selectRealKBranchesForDiagnostic(resultsVisco, options.mrlfeParams.etaS);
assert(isfield(branchesVisco, 'A0Like'), ...
    'etaS > 0 diagnostic selection must return A0Like branches from visco real-k results.');

fprintf('test_mrlfe_etaS_zero_diagnostic_selection passed. etaS = 0 diagnostics use elastic/unified real-k results.\n');

function branches = selectRealKBranchesForDiagnostic(results, etaS)
if etaS > 0 && isfield(results.models, 'mRLFEViscoRealK')
    branches = results.models.mRLFEViscoRealK.branches;
elseif isfield(results.models, 'mRLFERealK')
    branches = results.models.mRLFERealK.branches;
elseif isfield(results.models, 'mRLFEElasticRealK')
    branches = results.models.mRLFEElasticRealK.branches;
else
    error('No mRLFE real-k branches were found in results.models.');
end
end
