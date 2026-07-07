clear; clc;
startup

fprintf('\nRunning mRLFE public defaults contract test...\n');
fprintf('---------------------------------------------\n');

params = mrlfeDefaultParameters();
requiredParams = ["mu_Pa", "etaS_Pas", "rho_kgm3", "nu", ...
    "thickness_m", "fluidDensity_kgm3", "fluidSoundSpeed_mps"];
assertHasFields(params, requiredParams);
assert(params.mu_Pa == 75e3, 'Unexpected default mu.');
assert(params.etaS_Pas == 0.05, 'Unexpected default etaS.');
assert(params.rho_kgm3 == 1000, 'Unexpected default density.');
assert(params.thickness_m == 0.5e-3, 'Unexpected default thickness.');

options = mrlfeDefaultOptions();
assert(options.numerics.preset == "fast", 'Default numerical preset must be fast.');
assert(options.selection.strategy == "adaptive", 'Default selection strategy must be adaptive.');
assert(options.termination.A0Like == "physicalTail", 'Default A0 termination must be physicalTail.');
assert(options.termination.S0Like == "none", 'Default S0 termination must be none.');
assert(options.fallback.policy == "none", 'Default fallback policy must be none.');

fast = mrlfeGetNumericalPreset("fast");
assert(fast.name == "fast", 'Fast preset name mismatch.');
assert(fast.scanPoints == 260, 'Fast preset scan points mismatch.');
assert(fast.candidateCount == 5, 'Fast preset candidate count mismatch.');
assert(fast.refineCandidates == false, 'Fast preset must not refine candidates.');
assert(isequal(fast.adaptiveWindows, [0.20 0.40 0.80]), 'Fast adaptive windows mismatch.');

dense = mrlfeGetNumericalPreset("dense");
assert(dense.name == "dense", 'Dense preset name mismatch.');
assert(dense.scanPoints == 900, 'Dense preset scan points mismatch.');
assert(dense.candidateCount == 8, 'Dense preset candidate count mismatch.');
assert(dense.refineCandidates == true, 'Dense preset must refine candidates.');

assertErrorId(@() mrlfeGetNumericalPreset("balanced"), 'mrlfe:InvalidNumericalPreset');

fprintf('mRLFE public defaults contract test passed.\n');

function assertHasFields(s, names)
for i = 1:numel(names)
    assert(isfield(s, char(names(i))), 'Missing field: %s', names(i));
end
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
