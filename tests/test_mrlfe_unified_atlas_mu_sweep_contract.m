function test_mrlfe_unified_atlas_mu_sweep_contract()
%TEST_MRLFE_UNIFIED_ATLAS_MU_SWEEP_CONTRACT Lightweight mu sweep for unified atlas route.

muValues = [80e3 158e3 320e3];
for i = 1:numel(muValues)
    result = runOneMuCase(muValues(i));
    assert(result.variant == "real-k-atlas-unified");
    assert(isfield(result.branches, 'A0Like'));
    assert(isfield(result.branches, 'S0Like'));
    assert(result.branches.S0Like.atlasUnifiedPolicy == "viscousS0AdaptiveContinuation");
    assert(result.branches.S0Like.seedMode.seedSource == "RayleighLambSeedPhysicalFloor");

    s0Valid = branchValid(result.branches.S0Like);
    assert(nnz(s0Valid) >= 14, 'S0 adaptive tracker lost too many points in mu sweep contract.');
    s0Cp = result.branches.S0Like.Cp(:);
    s0CpValid = s0Cp(s0Valid);
    if numel(s0CpValid) >= 2
        maxJump = max(abs(diff(s0CpValid)) ./ max(abs(s0CpValid(1:end-1)), eps));
        assert(maxJump < 0.18, 'S0 adaptive tracker produced an excessive jump in mu sweep contract.');
    end
    assert(all(isfinite(result.branches.S0Like.adaptiveWindowUsed(s0Valid))));
end

fprintf('test_mrlfe_unified_atlas_mu_sweep_contract passed.\n');
end

function result = runOneMuCase(mu)
params = rlDefaultParams();
params.modelType = "ShearPoisson";
params.rho = 1070;
params.mu = mu;
params.nu = 0.4999;
params.thickness = 0.5e-3;
params.fmin = 10;
params.fmax = 5000;
params.numFrequencyPoints = 18;
params.frequencySpacing = "linspace";

material = rlComputeMaterial(params);
geometryFull = rlComputeGeometry(params);
geometry = geometryFull;
if isfield(geometry, 'halfThickness')
    geometry = rmfield(geometry, 'halfThickness');
end
frequency = rlBuildFrequencyVector(params);

rlOptions = rlDefaultOptions("Fast");
rlOptions.computeA0 = true;
rlOptions.computeS0 = true;
rlOptions.computeMRLFE = false;
rlOptions.computeMRLFERealK = false;
rlOptions.computeMRLFEElasticRealK = false;
rlOptions.computeMRLFEViscoRealK = false;
rlOptions.computeMRLFEComplexK = false;
rlOptions.computeMRLFEViscoComplexK = false;
rlOptions.mrlfeUseUnifiedAtlasRoute = false;
rlResult = rlComputeFundamentalLambModes(params, rlOptions);

seedModes = struct();
seedModes.A0 = rlResult.modes.A0;
seedModes.S0 = rlResult.modes.S0;

mrlfeParams = defaultMRLFEParams();
mrlfeParams.fluidDensity = 1000;
mrlfeParams.fluidSoundSpeed = 1500;
mrlfeParams.etaS = 0.05;
mrlfeParams.etaL = 0;
mrlfeParams.useComplexLambda = false;
mrlfeParams.solveComplexK = false;

options = rlDefaultOptions("Fast");
options.mrlfeUseUnifiedAtlasRoute = true;
options.mrlfeComputeA0Like = true;
options.mrlfeComputeS0Like = true;
options.mrlfeViscoAtlasCpScanPoints = 180;
options.mrlfeA0DPCandidates = 6;
options.mrlfeA0DPRefineCandidates = false;
options.mrlfeDelayedCutMinValidRun = 3;
options.mrlfeUseAdaptiveS0AtlasTracker = true;
options.mrlfeAdaptiveCpScanPoints = 180;
options.mrlfeAdaptiveWindows = [0.12 0.20 0.35 0.50];
options.mrlfeAdaptiveEdgeGuardPoints = 3;
options.mrlfeAdaptiveRefineCandidates = false;
options.mrlfeResidualTolerance = 1e-3;

result = computeMRLFE(frequency, material, geometry, seedModes, mrlfeParams, options);
end

function valid = branchValid(branch)
cp = branch.Cp(:);
valid = isfinite(cp) & cp > 0;
if isfield(branch, 'validCp')
    valid = valid & logical(branch.validCp(:));
elseif isfield(branch, 'valid')
    valid = valid & logical(branch.valid(:));
end
end
