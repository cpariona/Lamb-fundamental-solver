function test_mrlfe_a0_delayed_direct_visco_opt_in_contract()
%TEST_MRLFE_A0_DELAYED_DIRECT_VISCO_OPT_IN_CONTRACT A0DelayedCut opt-in route contract.

params = rlDefaultParams();
params.modelType = "ShearPoisson";
params.rho = 1070;
params.mu = 158e3;
params.nu = 0.4999;
params.thickness = 0.5e-3;
params.fmin = 10;
params.fmax = 800;
params.numFrequencyPoints = 10;
params.frequencySpacing = "linspace";

options = rlDefaultOptions("Fast");
options.computeA0 = true;
options.computeS0 = false;
options.computeMRLFERealK = true;
options.computeMRLFEElasticRealK = false;
options.computeMRLFEViscoRealK = true;
options.computeMRLFEComplexK = false;
options.mrlfeComputeA0Like = true;
options.mrlfeComputeS0Like = false;
options.mrlfeDirectViscoAtlasPolicy = "A0DelayedCut";
options.mrlfeViscoAtlasCpScanPoints = 120;
options.mrlfeA0DPCandidates = 6;
options.mrlfeA0DPRefineCandidates = false;
options.mrlfeDelayedCutMinValidRun = 2;
options.mrlfeParams = defaultMRLFEParams();
options.mrlfeParams.fluidDensity = 1000;
options.mrlfeParams.fluidSoundSpeed = 1500;
options.mrlfeParams.etaS = 0.02;
options.mrlfeParams.etaL = 0;
options.mrlfeParams.useComplexLambda = false;

result = rlComputeFundamentalLambModes(params, options);

assert(isfield(result.models, 'mRLFERealK'));
assert(isfield(result.models.mRLFERealK.branches, 'A0Like'));
assert(~isfield(result.models.mRLFERealK.branches, 'S0Like'));
assert(isfield(result.models.mRLFERealK, 'experimental'));
assert(result.models.mRLFERealK.experimental.directViscoAtlasPolicy == "A0DelayedCut");
assert(result.models.mRLFERealK.experimental.S0LikeExcluded == true);
assert(result.models.mRLFEElasticRealK.variant == "real-k-elastic-reference-skipped");
assert(isfield(result.models.mRLFERealK.branches.A0Like, 'delayedViscoModalCut'));

fprintf('test_mrlfe_a0_delayed_direct_visco_opt_in_contract passed.\n');
end
