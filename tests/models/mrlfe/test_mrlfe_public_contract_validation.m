clear; clc;
startup

fprintf('\nRunning mRLFE public validation contract test...\n');
fprintf('-----------------------------------------------\n');

request = localValidRequest("A0Like", 0.05);
mrlfeValidateRequest(mrlfeResolveConfiguration(request).request);

bad = request;
bad.frequency_Hz = [];
assertInvalid(bad, 'mrlfe:InvalidFrequency');

bad = request;
bad.frequency_Hz = [1000; 900; 1200];
assertInvalid(bad, 'mrlfe:InvalidFrequencyOrder');

bad = request;
bad.frequency_Hz = [1000; NaN; 1200];
assertInvalid(bad, 'mrlfe:InvalidFrequency');

bad = request;
bad.branch = "B1";
assertInvalid(bad, 'mrlfe:InvalidBranch');

bad = request;
bad.material.mu_Pa = 0;
assertInvalid(bad, 'mrlfe:InvalidMaterial');

bad = request;
bad.material.etaS_Pas = -0.01;
assertInvalid(bad, 'mrlfe:InvalidMaterial');

bad = request;
bad.material.rho_kgm3 = 0;
assertInvalid(bad, 'mrlfe:InvalidMaterial');

bad = request;
bad.material.nu = 0.5;
assertInvalid(bad, 'mrlfe:InvalidMaterial');

bad = request;
bad.geometry.thickness_m = 0;
assertInvalid(bad, 'mrlfe:InvalidGeometry');

bad = request;
bad.fluid.density_kgm3 = 0;
assertInvalid(bad, 'mrlfe:InvalidFluid');

bad = request;
bad.fluid.soundSpeed_mps = 0;
assertInvalid(bad, 'mrlfe:InvalidFluid');

bad = request;
bad.numerics.preset = "unsupported";
assertInvalid(bad, 'mrlfe:InvalidNumericalPreset');

bad = request;
bad.selection.strategy = "modal";
assertInvalid(bad, 'mrlfe:InvalidSelectionStrategy');

bad = request;
bad.termination.policy = "legacyFallback";
assertInvalid(bad, 'mrlfe:InvalidTerminationPolicy');

bad = request;
bad.fallback.policy = "legacy";
assertInvalid(bad, 'mrlfe:InvalidFallbackPolicy');

fprintf('mRLFE public validation contract test passed.\n');

function request = localValidRequest(branch, etaS)
request = struct();
request.branch = string(branch);
request.frequency_Hz = linspace(1000, 6000, 10).';
request.material = struct('mu_Pa', 75e3, 'etaS_Pas', etaS, 'rho_kgm3', 1000, 'nu', 0.4999);
request.geometry = struct('thickness_m', 0.5e-3);
request.fluid = struct('density_kgm3', 1000, 'soundSpeed_mps', 1500);
request.numerics = struct('preset', "fast");
request.selection = struct('strategy', "adaptive");
request.termination = struct('policy', "physicalTail");
request.fallback = struct('policy', "none");
end

function assertInvalid(request, expectedId)
try
    mrlfeResolveConfiguration(request);
catch err
    assert(strcmp(err.identifier, expectedId), ...
        'Expected error "%s", got "%s".', expectedId, err.identifier);
    return;
end
error('Expected error "%s" was not thrown.', expectedId);
end
