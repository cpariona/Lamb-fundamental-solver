function test_mrlfe_modal_atlas_s0_contract()
%TEST_MRLFE_MODAL_ATLAS_S0_CONTRACT Contract test for experimental S0-like modal atlas.

params = rlDefaultParams();
params.modelType = "ShearPoisson";
params.rho = 1070;
params.mu = 158e3;
params.nu = 0.4999;
params.thickness = 0.5e-3;
params.fmin = 10;
params.fmax = 1.5e3;
params.numFrequencyPoints = 18;
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
seedOptions.computeA0 = false;
seedOptions.computeS0 = true;
seedOptions.computeMRLFE = false;
seedOptions.computeMRLFERealK = false;
seedOptions.computeMRLFEElasticRealK = false;
seedOptions.computeMRLFEViscoRealK = false;
seedOptions.computeMRLFEComplexK = false;
seedRaw = rlComputeFundamentalLambModes(params, seedOptions);
seedMode = seedRaw.modes.S0;

atlasOptions = rlDefaultOptions("Fast");
atlasOptions.mrlfeParams = defaultMRLFEParams();
atlasOptions.mrlfeParams.fluidDensity = 1000;
atlasOptions.mrlfeParams.fluidSoundSpeed = 1500;
atlasOptions.mrlfeParams.etaS = 0;
atlasOptions.mrlfeParams.etaL = 0;
atlasOptions.mrlfeParams.useComplexLambda = false;
atlasOptions.mrlfeModalAtlasCpScanPoints = 160;
atlasOptions.mrlfeModalAtlasTopNMinima = 8;
atlasOptions.mrlfeModalAtlasRefineMinima = false;
atlasOptions.mrlfeModalAtlasApplyAmbiguityCut = false;

branch = solveMRLFEBranchModalAtlas("S0Like", seedMode, material, rmfield(geometry, 'halfThickness'), atlasOptions.mrlfeParams, atlasOptions);

assert(isfield(branch, 'Cp'));
assert(isfield(branch, 'k'));
assert(isfield(branch, 'validCp'));
assert(isfield(branch, 'modalAtlas'));
assert(isfield(branch.modalAtlas, 'continuousCp'));
assert(isfield(branch.modalAtlas, 'selectedFamily'));
assert(isequal(size(branch.Cp(:)), size(seedMode.frequency(:))));
assert(isequal(size(branch.modalAtlas.continuousCp(:)), size(branch.Cp(:))));
assert(nnz(isfinite(branch.Cp(:)) & branch.Cp(:) > 0) > 0);

fprintf('test_mrlfe_modal_atlas_s0_contract passed.\n');
end
