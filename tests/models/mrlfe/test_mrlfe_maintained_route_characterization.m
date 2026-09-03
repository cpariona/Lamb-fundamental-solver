clear; clc;
configureTestPath;
fprintf('\nRunning mRLFE maintained-route characterization test...\n');
fprintf('----------------------------------------------------\n');

cases = [ ...
    struct('branch', "A0Like", 'etaS', 0), ...
    struct('branch', "A0Like", 'etaS', 0.05), ...
    struct('branch', "S0Like", 'etaS', 0), ...
    struct('branch', "S0Like", 'etaS', 0.05)];

for i = 1:numel(cases)
    request = localRequest(cases(i).branch, cases(i).etaS);
    direct = mrlfeSolve(request);
    assert(direct.execution.effectivePreset == "fast", 'Direct solve effective preset must be fast.');
    assert(any(direct.execution.internalEngine == ["elastic_adaptive", "viscoelastic_adaptive"]), ...
        'Direct solve must expose neutral engine metadata.');
    assert(direct.fallback.policy == "none" && direct.fallback.applied == false, ...
        'Direct solve must not apply fallback.');

    gui = guiRunMRLFEModel(struct('params', localParams(), ...
        'options', localGuiOptions(cases(i).branch, cases(i).etaS), ...
        'mrlfeParams', localMrlfeParams(cases(i).etaS), ...
        'computeVisco', cases(i).etaS > 0));
    guiResult = gui.metadata.modelResults.(char(cases(i).branch));
    assertSameResult(guiResult, direct, 'Main GUI');
end

% FitTool route and optimized-grid equivalence are covered by dedicated tests in
% the same extended tier. Keeping that work out of this test avoids duplicate
% solver evaluations and grid-policy coupling.

fprintf('mRLFE maintained-route characterization test passed.\n');

function params = localParams()
params = rlDefaultParams();
params.fmin = 1000;
params.fmax = 6000;
params.numFrequencyPoints = 10;
params.frequencySpacing = "linspace";
params.mu = 75e3;
params.thickness = 0.5e-3;
params.rho = 1070;
params.nu = 0.4999;
end

function request = localRequest(branch, etaS)
params = localParams();
request = mrlfeBuildSolveRequest(params, rlBuildFrequencyVector(params), branch, localGuiOptions(branch, etaS));
end

function options = localGuiOptions(branch, etaS)
options = mrlfeDefaultSweepOptions(branch, 'EtaS', etaS);
options.branchNames = branch;
options.mrlfeParams = localMrlfeParams(etaS);
end

function params = localMrlfeParams(etaS)
params = mrlfeDefaultInternalParameters();
params.etaS = etaS;
params.fluidDensity = 1000;
params.fluidSoundSpeed = 1500;
end

function assertSameResult(actual, expected, label)
assertSameVector(actual.phaseVelocity_mps, expected.phaseVelocity_mps, label + " Cp mismatch.");
assert(isequal(actual.validMask(:), expected.validMask(:)), label + " valid mask mismatch.");
assert(actual.execution.internalEngine == expected.execution.internalEngine, label + " engine mismatch.");
assert(actual.termination.policy == expected.termination.policy, label + " termination mismatch.");
assert(actual.fallback.policy == "none" && actual.fallback.applied == false, label + " fallback mismatch.");
end

function assertSameVector(a, b, message)
a = a(:);
b = b(:);
assert(isequal(isfinite(a), isfinite(b)), message);
finite = isfinite(a) & isfinite(b);
if any(finite)
    assert(max(abs(a(finite) - b(finite))) == 0, message);
end
end
