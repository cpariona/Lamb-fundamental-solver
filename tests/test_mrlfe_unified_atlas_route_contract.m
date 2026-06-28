function test_mrlfe_unified_atlas_route_contract()
%TEST_MRLFE_UNIFIED_ATLAS_ROUTE_CONTRACT Unified atlas route uses fast seeds, not elastic mRLFE reference.

params = rlDefaultParams();
params.modelType = "ShearPoisson";
params.rho = 1070;
params.mu = 158e3;
params.nu = 0.4999;
params.thickness = 0.5e-3;
params.fmin = 10;
params.fmax = 900;
params.numFrequencyPoints = 10;
params.frequencySpacing = "linspace";

material = rlComputeMaterial(params);
geometryFull = rlComputeGeometry(params);
geometry = geometryFull;
if isfield(geometry, 'halfThickness')
    geometry = rmfield(geometry, 'halfThickness');
end
frequency = rlBuildFrequencyVector(params);

seedModes = struct();
seedModes.A0 = mrlfeMakePhysicalSeedMode("A0Like", frequency, material, geometry, struct());
seedModes.S0 = mrlfeMakePhysicalSeedMode("S0Like", frequency, material, geometry, struct());

mrlfeParams = defaultMRLFEParams();
mrlfeParams.fluidDensity = 1000;
mrlfeParams.fluidSoundSpeed = 1500;
mrlfeParams.etaS = 0.02;
mrlfeParams.etaL = 0;
mrlfeParams.useComplexLambda = false;
mrlfeParams.solveComplexK = false;

options = rlDefaultOptions("Fast");
options.mrlfeUseUnifiedAtlasRoute = true;
options.mrlfeComputeA0Like = true;
options.mrlfeComputeS0Like = true;
options.mrlfeViscoAtlasCpScanPoints = 120;
options.mrlfeA0DPCandidates = 6;
options.mrlfeA0DPRefineCandidates = false;
options.mrlfeDelayedCutMinValidRun = 2;

result = computeMRLFE(frequency, material, geometry, seedModes, mrlfeParams, options);

assert(result.variant == "real-k-atlas-unified");
assert(result.atlasUnified.usesElasticMRLFEReference == false);
assert(isfield(result.branches, 'A0Like'));
assert(isfield(result.branches, 'S0Like'));
assert(result.branches.A0Like.solverRoute == "atlasUnified");
assert(result.branches.S0Like.solverRoute == "atlasUnified");
assert(isfield(result.branches.A0Like, 'seedMode'));
assert(isfield(result.branches.S0Like, 'seedMode'));

fprintf('test_mrlfe_unified_atlas_route_contract passed.\n');
end
