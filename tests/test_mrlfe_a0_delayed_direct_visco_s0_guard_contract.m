function test_mrlfe_a0_delayed_direct_visco_s0_guard_contract()
%TEST_MRLFE_A0_DELAYED_DIRECT_VISCO_S0_GUARD_CONTRACT S0 request must not use A0DelayedCut route.

params = rlDefaultParams();
params.modelType = "ShearPoisson";
params.rho = 1070;
params.mu = 158e3;
params.nu = 0.4999;
params.thickness = 0.5e-3;
params.fmin = 10;
params.fmax = 600;
params.numFrequencyPoints = 8;
params.frequencySpacing = "linspace";

options = rlDefaultOptions("Fast");
options.computeA0 = true;
options.computeS0 = true;
options.computeMRLFERealK = true;
options.computeMRLFEElasticRealK = false;
options.computeMRLFEViscoRealK = true;
options.computeMRLFEComplexK = false;
options.mrlfeComputeA0Like = true;
options.mrlfeComputeS0Like = true;
options.mrlfeDirectViscoAtlasPolicy = "A0DelayedCut";
options.mrlfeParams = defaultMRLFEParams();
options.mrlfeParams.fluidDensity = 1000;
options.mrlfeParams.fluidSoundSpeed = 1500;
options.mrlfeParams.etaS = 0.02;
options.mrlfeParams.etaL = 0;
options.mrlfeParams.useComplexLambda = false;

result = rlComputeFundamentalLambModes(params, options);

assert(isfield(result.models.mRLFERealK.branches, 'A0Like'));
assert(isfield(result.models.mRLFERealK.branches, 'S0Like'));
assert(~isfield(result.models.mRLFERealK, 'experimental'));
assert(result.models.mRLFEElasticRealK.variant == "real-k");

fprintf('test_mrlfe_a0_delayed_direct_visco_s0_guard_contract passed.\n');
end
