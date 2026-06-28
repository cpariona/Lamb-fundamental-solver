function test_mrlfe_a0_adaptive_physical_tail_contract()
%TEST_MRLFE_A0_ADAPTIVE_PHYSICAL_TAIL_CONTRACT Validate opt-in A0 adaptive physical tail policy.

muValues = [50e3 100e3 158e3];
for i = 1:numel(muValues)
    mu = muValues(i);
    [params, material, geometry, frequency, seedModes, mrlfeParams] = buildCase(mu);
    options = makeOptions();
    result = computeMRLFE(frequency, material, geometry, seedModes, mrlfeParams, options);

    assert(strcmp(string(result.variant), "real-k-atlas-unified"), 'Unexpected mRLFE variant.');
    assert(isfield(result.branches, 'A0Like'), 'Missing A0Like branch.');
    a0 = result.branches.A0Like;
    assert(strcmp(string(a0.atlasUnifiedPolicy), "viscousA0AdaptivePhysicalTailCut"), 'Unexpected A0 policy.');
    assert(isfield(a0, 'physicalCorridor'), 'Missing A0 physical corridor diagnostics.');
    assert(isfield(a0, 'candidateType'), 'Missing adaptive A0 candidate type diagnostics.');

    valid = isfinite(a0.Cp(:)) & a0.Cp(:) > 0;
    if isfield(a0, 'validCp')
        valid = valid & logical(a0.validCp(:));
    end
    validCount = nnz(valid);
    assert(validCount >= 120, 'A0 adaptive physical tail policy returned too few valid points.');

    cpValid = a0.Cp(valid);
    maxJump = maxRelativeJump(cpValid);
    assert(maxJump < 0.13, 'A0 adaptive physical tail policy has an excessive jump.');

    lastValidHz = frequency(find(valid, 1, 'last'));
    if mu <= 50e3
        assert(lastValidHz > 12e3, 'Soft A0 branch did not persist far enough.');
        assert(lastValidHz < 20e3, 'Soft A0 branch did not cut the high-frequency collapse tail.');
    elseif mu <= 100e3
        assert(lastValidHz > 20e3, 'Intermediate A0 branch did not persist far enough.');
        assert(lastValidHz < 31e3, 'Intermediate A0 branch did not cut the high-frequency collapse tail.');
    else
        assert(lastValidHz > 31e3, 'Stiffer A0 branch was cut too early.');
    end
end
end

function [params, material, geometry, frequency, seedModes, mrlfeParams] = buildCase(mu)
params = rlDefaultParams();
params.modelType = "ShearPoisson";
params.rho = 1070;
params.mu = mu;
params.nu = 0.4999;
params.thickness = 0.5e-3;
params.fmin = 10;
params.fmax = 32e3;
params.numFrequencyPoints = 80;
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

function options = makeOptions()
options = rlDefaultOptions("Fast");
options.mrlfeUseUnifiedAtlasRoute = true;
options.mrlfeComputeA0Like = true;
options.mrlfeComputeS0Like = false;
options.computeMRLFEComplexK = false;
options.computeMRLFEViscoComplexK = false;
options.mrlfeUseAdaptiveA0AtlasTracker = true;
options.mrlfeUseA0PhysicalTailCut = true;
options.mrlfeAdaptiveCpScanPoints = 500;
options.mrlfeAdaptiveWindows = [0.20 0.35 0.50 0.80 1.20];
options.mrlfeAdaptiveMaxJumpRelative = 0.12;
options.mrlfeAdaptiveMaxPredictionError = 0.12;
options.mrlfeAdaptiveEstablishedMinValidRun = 6;
options.mrlfeAdaptiveAllowValleyFallback = true;
options.mrlfeAdaptiveValleyFallbackRelativeWindow = 0.10;
options.mrlfeA0PhysicalMinRatioToGuide = 0.70;
options.mrlfeA0PhysicalMinFrequencyHz = 1000;
options.mrlfeA0PhysicalMinValidRunBeforeCut = 6;
options.mrlfeA0PhysicalMaxLocalDropRelative = 0.05;
options.mrlfeA0PhysicalMaxTwoStepDropRelative = 0.10;
options.mrlfeResidualTolerance = 1e-3;
end

function y = maxRelativeJump(x)
x = x(:);
x = x(isfinite(x) & x > 0);
if numel(x) < 2
    y = 0;
else
    y = max(abs(diff(x)) ./ max(abs(x(1:end-1)), eps));
end
end
