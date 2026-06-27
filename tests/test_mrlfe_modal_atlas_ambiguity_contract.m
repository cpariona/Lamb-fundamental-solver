function test_mrlfe_modal_atlas_ambiguity_contract()
%TEST_MRLFE_MODAL_ATLAS_AMBIGUITY_CONTRACT Contract test for experimental modal atlas metadata.

params = rlDefaultParams();
params.modelType = "ShearPoisson";
params.rho = 1070;
params.mu = 158e3;
params.nu = 0.4999;
params.thickness = 0.5e-3;
params.fmin = 10;
params.fmax = 2e3;
params.numFrequencyPoints = 24;
params.frequencySpacing = "linspace";

material = rlComputeMaterial(params);
params.E = material.E;
params.K = material.K;
params.CL = material.CL;
params.CT = material.CT;
params.lambda = material.lambda;
params.nu = material.nu;
geometry = rlComputeGeometry(params);

seedOptions = rlDefaultOptions("Fast");
seedOptions.computeA0 = true;
seedOptions.computeS0 = false;
seedOptions.computeMRLFE = false;
seedOptions.computeMRLFERealK = false;
seedOptions.computeMRLFEElasticRealK = false;
seedOptions.computeMRLFEViscoRealK = false;
seedOptions.computeMRLFEComplexK = false;
seedRaw = rlComputeFundamentalLambModes(params, seedOptions);
seedMode = seedRaw.modes.A0;

atlasOptions = rlDefaultOptions("Fast");
atlasOptions.mrlfeParams = defaultMRLFEParams();
atlasOptions.mrlfeParams.fluidDensity = 1000;
atlasOptions.mrlfeParams.fluidSoundSpeed = 1500;
atlasOptions.mrlfeParams.etaS = 0;
atlasOptions.mrlfeParams.etaL = 0;
atlasOptions.mrlfeParams.useComplexLambda = false;
atlasOptions.mrlfeModalAtlasCpScanPoints = 180;
atlasOptions.mrlfeModalAtlasTopNMinima = 8;
atlasOptions.mrlfeModalAtlasRefineMinima = false;
atlasOptions.mrlfeModalAtlasApplyAmbiguityCut = false;

continuous = solveMRLFEBranchModalAtlas("A0Like", seedMode, material, rmfield(geometry, 'halfThickness'), atlasOptions.mrlfeParams, atlasOptions);
assert(isfield(continuous, 'modalAmbiguityMask'));
assert(isfield(continuous, 'modalAmbiguityClusters'));
assert(isfield(continuous, 'modalAmbiguityTriggers'));
assert(isfield(continuous, 'modalAtlas'));
assert(isfield(continuous.modalAtlas, 'continuousCp'));
assert(isfield(continuous.modalAtlas, 'continuousResidual'));
assert(isfield(continuous.modalAtlas, 'continuousFamilyId'));
assert(isfield(continuous.modalAtlas, 'applyAmbiguityCut'));
assert(isequal(size(continuous.Cp(:)), size(continuous.modalAtlas.continuousCp(:))));
assert(~continuous.modalAtlas.applyAmbiguityCut);
assert(nnz(isfinite(continuous.Cp)) == nnz(isfinite(continuous.modalAtlas.continuousCp)));

cutOptions = atlasOptions;
cutOptions.mrlfeModalAtlasApplyAmbiguityCut = true;
cutOptions.mrlfeModalAtlasAmbiguityResidualRatio = 1e-12;
cutOptions.mrlfeModalAtlasAmbiguityMinCpSeparation = 0;
cutOptions.mrlfeModalAtlasAmbiguityMaxGapPoints = 1000;
cutOptions.mrlfeModalAtlasAmbiguityPaddingPoints = 0;
cutOptions.mrlfeModalAtlasAmbiguityMinClusterTriggers = 1;
cutOptions.mrlfeModalAtlasAmbiguityRequireHigherCpAlternative = false;
cutBranch = solveMRLFEBranchModalAtlas("A0Like", seedMode, material, rmfield(geometry, 'halfThickness'), cutOptions.mrlfeParams, cutOptions);
assert(cutBranch.modalAtlas.applyAmbiguityCut);
assert(isequal(size(cutBranch.Cp(:)), size(cutBranch.modalAtlas.continuousCp(:))));
assert(nnz(isfinite(cutBranch.Cp)) <= nnz(isfinite(cutBranch.modalAtlas.continuousCp)));

fprintf('test_mrlfe_modal_atlas_ambiguity_contract passed.\n');
end
