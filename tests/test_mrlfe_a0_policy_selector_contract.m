function test_mrlfe_a0_policy_selector_contract()
%TEST_MRLFE_A0_POLICY_SELECTOR_CONTRACT Validate high-level A0 policy routing.

[params, material, geometry, frequency, seedModes, mrlfeParams] = buildCase();

optionsDelayed = makeOptions("delayedCut");
resultDelayed = computeMRLFE(frequency, material, geometry, seedModes, mrlfeParams, optionsDelayed);
assert(isfield(resultDelayed.branches, 'A0Like'), 'Missing delayedCut A0Like branch.');
a0Delayed = resultDelayed.branches.A0Like;
assert(strcmp(string(a0Delayed.atlasUnifiedPolicy), "viscousA0DelayedCut"), 'mrlfeA0Policy="delayedCut" did not use delayed A0 policy.');
assert(isfield(a0Delayed, 'delayedViscoModalCut'), 'Delayed A0 policy did not expose delayedViscoModalCut diagnostics.');
assertHasValidA0(a0Delayed);

optionsAdaptive = makeOptions("adaptivePhysicalTail");
resultAdaptive = computeMRLFE(frequency, material, geometry, seedModes, mrlfeParams, optionsAdaptive);
assert(isfield(resultAdaptive.branches, 'A0Like'), 'Missing adaptivePhysicalTail A0Like branch.');
a0Adaptive = resultAdaptive.branches.A0Like;
assert(strcmp(string(a0Adaptive.atlasUnifiedPolicy), "viscousA0AdaptivePhysicalTailCut"), 'mrlfeA0Policy="adaptivePhysicalTail" did not use adaptive physical-tail A0 policy.');
assert(isfield(a0Adaptive, 'physicalCorridor'), 'Adaptive physical-tail A0 policy did not expose physicalCorridor diagnostics.');
assert(isfield(a0Adaptive, 'candidateType'), 'Adaptive physical-tail A0 policy did not expose candidateType diagnostics.');
assertHasValidA0(a0Adaptive);

fprintf('test_mrlfe_a0_policy_selector_contract passed.\n');
end

function [params, material, geometry, frequency, seedModes, mrlfeParams] = buildCase()
params = rlDefaultParams();
params.modelType = "ShearPoisson";
params.rho = 1070;
params.mu = 158e3;
params.nu = 0.4999;
params.thickness = 0.5e-3;
params.fmin = 10;
params.fmax = 32e3;
params.numFrequencyPoints = 50;
params.frequencySpacing = "hybrid";
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
end

function options = makeOptions(a0Policy)
options = rlDefaultOptions("Fast");
options.mrlfeUseUnifiedAtlasRoute = true;
options.mrlfeComputeA0Like = true;
options.mrlfeComputeS0Like = false;
options.computeMRLFEComplexK = false;
options.computeMRLFEViscoComplexK = false;
options.mrlfeA0Policy = string(a0Policy);
options.mrlfeViscoAtlasCpScanPoints = 300;
options.mrlfeA0DPCandidates = 6;
options.mrlfeResidualTolerance = 1e-3;
options.mrlfeAdaptiveCpScanPoints = 300;
options.mrlfeAdaptiveWindows = [0.20 0.35 0.50 0.80 1.20];
options.mrlfeAdaptiveMaxJumpRelative = 0.12;
options.mrlfeAdaptiveMaxPredictionError = 0.12;
options.mrlfeA0PhysicalMinRatioToGuide = 0.70;
options.mrlfeA0PhysicalMinFrequencyHz = 1000;
end

function assertHasValidA0(branch)
cp = branch.Cp(:);
valid = isfinite(cp) & cp > 0;
if isfield(branch, 'validCp')
    valid = valid & logical(branch.validCp(:));
end
assert(nnz(valid) >= 5, 'A0 policy returned too few valid points.');
end
