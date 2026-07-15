clear; clc;
if isempty(which('mrlfeBuildPublicSolveRequest'))
    startup
end

fprintf('\nRunning shared mRLFE public-request builder test...\n');
fprintf('-------------------------------------------------\n');

frequency_Hz = [1000; 2000; 4000];
params = struct('mu', 81e3, 'etaS', 0.07, 'rho', 1060, 'nu', 0.48, ...
    'thickness', 0.62e-3, 'fluidDensity', 998, 'fluidSoundSpeed', 1480);
options = struct('mrlfeNumericalPreset', "balanced", ...
    'mrlfeParams', struct('etaS', 0.09, 'fluidDensity', 1010, 'fluidSoundSpeed', 1510));
policy = struct('parameterOptions', options);

a0 = mrlfeBuildPublicSolveRequest(params, frequency_Hz, "A0Like", policy);
assertRequest(a0, "A0Like", "balanced", "physicalTail", 0.07);
assert(a0.material.mu_Pa == params.mu && a0.material.rho_kgm3 == params.rho);
assert(a0.material.nu == params.nu && a0.geometry.thickness_m == params.thickness);
assert(a0.fluid.density_kgm3 == params.fluidDensity);
assert(a0.fluid.soundSpeed_mps == params.fluidSoundSpeed);

s0 = mrlfeBuildPublicSolveRequest(rmfield(params, 'etaS'), frequency_Hz, "S0Like", policy);
assertRequest(s0, "S0Like", "balanced", "none", 0.09);

canonical = struct('mu_Pa', 82e3, 'etaS_Pas', 0, 'rho_kgm3', 1070, 'nu', 0.47, ...
    'thickness_m', 0.55e-3, 'fluidDensity_kgm3', 997, 'fluidSoundSpeed_mps', 1492);
canonicalRequest = mrlfeBuildPublicSolveRequest(canonical, frequency_Hz, "A0Like", struct());
assertRequest(canonicalRequest, "A0Like", "fast", "physicalTail", 0);
assert(canonicalRequest.fluid.density_kgm3 == canonical.fluidDensity_kgm3);
assert(canonicalRequest.fluid.soundSpeed_mps == canonical.fluidSoundSpeed_mps);

gui = mrlfeBuildGuiSolveRequest(params, frequency_Hz, "A0Like", options);
fit = mrlfeBuildFitSolveRequest(params, frequency_Hz, "A0Like", options);
sweep = mrlfeBuildSweepSolveRequest(params, struct(), frequency_Hz, "A0Like", options);
assert(isequaln(gui, a0) && isequaln(fit, a0) && isequaln(sweep, a0), ...
    'All surface wrappers must produce the shared request when surface state is equivalent.');

point = struct('parameterName', "mu", 'parameterValue', 92e3);
sweepPoint = mrlfeBuildSweepSolveRequest(params, point, frequency_Hz, "A0Like", options);
assert(sweepPoint.material.mu_Pa == point.parameterValue, ...
    'Sweep wrapper must apply the point before shared request construction.');

numericsOptions = options;
numericsOptions.numerics = struct('preset', "robust");
robust = mrlfeBuildFitSolveRequest(params, frequency_Hz, "A0Like", numericsOptions);
assert(robust.numerics.preset == "robust", ...
    'Explicit numerics.preset must take precedence over mrlfeNumericalPreset.');

assertErrorId(@() mrlfeBuildPublicSolveRequest(params, frequency_Hz, "B1", policy), 'mrlfe:InvalidBranch');
assertErrorId(@() mrlfeBuildPublicSolveRequest(params, [1000; 900], "A0Like", policy), 'mrlfe:InvalidFrequencyOrder');
assertErrorId(@() mrlfeBuildPublicSolveRequest(setfield(params, 'mu', 0), frequency_Hz, "A0Like", policy), 'mrlfe:InvalidMaterial');
assertErrorId(@() mrlfeBuildFitSolveRequest(params, frequency_Hz, "A0Like", struct('mrlfeNumericalPreset', "unsupported")), 'mrlfe:InvalidNumericalPreset');
assertErrorId(@() mrlfeBuildSweepSolveRequest(params, struct('parameterName', "unsupported", 'parameterValue', 1), frequency_Hz, "A0Like", options), 'mrlfe:UnsupportedSweepParameter');

fprintf('Shared mRLFE public-request builder test passed.\n');

function assertRequest(request, branch, preset, termination, etaS)
assert(request.branch == branch);
assert(request.numerics.preset == preset);
assert(request.selection.strategy == "adaptive");
assert(request.termination.policy == termination);
assert(request.fallback.policy == "none");
assert(request.material.etaS_Pas == etaS);
end

function assertErrorId(fcn, expectedId)
try
    fcn();
catch err
    assert(strcmp(err.identifier, expectedId), ...
        'Expected error "%s", got "%s".', expectedId, err.identifier);
    return;
end
error('Expected error "%s" was not thrown.', expectedId);
end
