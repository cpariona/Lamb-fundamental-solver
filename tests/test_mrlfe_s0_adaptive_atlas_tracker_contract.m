function test_mrlfe_s0_adaptive_atlas_tracker_contract()
%TEST_MRLFE_S0_ADAPTIVE_ATLAS_TRACKER_CONTRACT S0 unified atlas uses adaptive local continuation.

params = rlDefaultParams();
params.modelType = "ShearPoisson";
params.rho = 1070;
params.mu = 158e3;
params.nu = 0.4999;
params.thickness = 0.5e-3;
params.fmin = 10;
params.fmax = 3200;
params.numFrequencyPoints = 18;
params.frequencySpacing = "linspace";

material = rlComputeMaterial(params);
geometryFull = rlComputeGeometry(params);
geometry = geometryFull;
if isfield(geometry, 'halfThickness')
    geometry = rmfield(geometry, 'halfThickness');
end
frequency = rlBuildFrequencyVector(params);
omega = 2*pi*frequency(:);

seedModes = struct();
seedModes.A0 = makeCheapRLSeed("A0", frequency, omega, material.CT);
seedModes.S0 = makeCheapRLSeed("S0", frequency, omega, sqrt(material.E / (material.rho * (1 - material.nu^2))));

mrlfeParams = defaultMRLFEParams();
mrlfeParams.fluidDensity = 1000;
mrlfeParams.fluidSoundSpeed = 1500;
mrlfeParams.etaS = 0.02;
mrlfeParams.etaL = 0;
mrlfeParams.useComplexLambda = false;
mrlfeParams.solveComplexK = false;

options = rlDefaultOptions("Fast");
options.mrlfeUseUnifiedAtlasRoute = true;
options.mrlfeComputeA0Like = false;
options.mrlfeComputeS0Like = true;
options.mrlfeUseAdaptiveS0AtlasTracker = true;
options.mrlfeAdaptiveCpScanPoints = 160;
options.mrlfeAdaptiveWindows = [0.12 0.20 0.35 0.50];
options.mrlfeAdaptiveEdgeGuardPoints = 3;
options.mrlfeAdaptiveRefineCandidates = false;
options.mrlfeAdaptiveMaxJumpRelative = 0.18;
options.mrlfeAdaptiveMaxPredictionError = 0.18;
options.mrlfeResidualTolerance = 1e-3;

result = computeMRLFE(frequency, material, geometry, seedModes, mrlfeParams, options);

assert(result.variant == "real-k-atlas-unified");
assert(result.atlasUnified.usesElasticMRLFEReference == false);
assert(isfield(result.branches, 'S0Like'));

branch = result.branches.S0Like;
assert(branch.solverRoute == "atlasUnified");
assert(branch.atlasUnifiedPolicy == "viscousS0AdaptiveContinuation");
assert(branch.seedMode.seedSource == "RayleighLambSeedPhysicalFloor");
assert(isfield(branch, 'adaptiveWindowUsed'));
assert(isfield(branch, 'adaptiveCenterCp'));
assert(isfield(branch, 'adaptiveCandidateCount'));
assert(isfield(branch.dpOptions, 'windows'));
assert(all(abs(branch.dpOptions.windows(:).' - [0.12 0.20 0.35 0.50]) < 1e-12));

valid = isfinite(branch.Cp(:)) & branch.Cp(:) > 0 & logical(branch.validCp(:));
assert(nnz(valid) >= 12, 'Adaptive S0 tracker should retain most low-frequency points.');
assert(all(isfinite(branch.adaptiveWindowUsed(valid))));
assert(max(branch.adaptiveWindowUsed(valid)) <= 0.50 + eps);

cpValid = branch.Cp(valid);
if numel(cpValid) >= 2
    maxJump = max(abs(diff(cpValid)) ./ max(abs(cpValid(1:end-1)), eps));
    assert(maxJump < 0.18, 'Adaptive S0 branch has an excessive point-to-point jump.');
end

fprintf('test_mrlfe_s0_adaptive_atlas_tracker_contract passed.\n');
end

function seed = makeCheapRLSeed(name, frequency, omega, cp0)
frequency = frequency(:);
cp = cp0 * ones(size(frequency));
if string(name) == "A0"
    scale = sqrt(max(frequency ./ max(max(frequency), eps), 0.02));
    cp = max(0.2 * cp0, min(cp0, 0.35 * cp0 .* scale));
end
seed = struct();
seed.name = string(name);
seed.family = string(name);
seed.frequency = frequency;
seed.omega = omega(:);
seed.Cp = cp(:);
seed.k = seed.omega ./ seed.Cp;
seed.valid = true(size(frequency));
end
