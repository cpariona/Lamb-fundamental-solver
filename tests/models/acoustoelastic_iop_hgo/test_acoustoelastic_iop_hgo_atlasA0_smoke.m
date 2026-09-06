function test_acoustoelastic_iop_hgo_atlasA0_smoke()
%TEST_ACOUSTOELASTIC_IOP_HGO_ATLASA0_SMOKE Validate maintained atlasA0 solve.

params = struct();
params.R = 7.8e-3;
params.thickness = 550e-6;
params.mu = 50e3;
params.k1 = 25e3;
params.k2 = 100;
params.rho = 1060;
params.rhoF = 1000;
params.fluidBulkModulus = 2.2e9;
params.frequency = logspace(log10(300), log10(15e3), 35);
params.IOP = 15 * 133.322;

options = lamb.models.acoustoelastic_iop_hgo.defaultAcoustoelasticIOPHGOOptions();
options.M54_variant = "corrected";
options.normalizeRows = false;
options.atlasNumYPoints = 300;
options.atlasTopNMinima = 12;
options.atlasBranchPolicy = "atlasA0";

result = lamb.models.acoustoelastic_iop_hgo.solveAcoustoelasticIOPHGOBranch(params, options);
resolvedOptions = result.options;

assert(isstruct(result), 'Result must be a struct.');
assert(isfield(result, 'phaseVelocity_mps'), 'Result must contain phaseVelocity_mps.');
assert(isfield(result, 'validMask'), 'Result must contain validMask.');
assert(isfield(result, 'quality'), 'Result must contain quality.');
assert(isfield(result, 'options'), 'Result must contain resolved solver options.');
assert(iscolumn(result.phaseVelocity_mps));
assert(iscolumn(result.validMask));
assert(numel(result.phaseVelocity_mps) == numel(params.frequency), 'Cp length must match frequency length.');
assert(numel(result.validMask) == numel(params.frequency), 'validMask length must match frequency length.');
assert(any(result.validMask), 'At least one phase-speed point must be valid.');
assert(resolvedOptions.atlasBranchPolicy == "atlasA0", 'Resolved policy must be atlasA0.');
assert(result.quality.policyName == "atlasA0", 'Quality policyName must report atlasA0.');
assert(result.quality.validCount == nnz(result.validMask), 'Quality valid-point count mismatch.');
assert(result.quality.validFraction > 0, 'validFraction must be positive.');
assert(result.quality.a0StartFilterPassed == true, 'Selected branch must pass the A0 start filter.');
assert(result.quality.selectionFallbackUsed == false, 'Smoke test should not require fallback selection.');
assert(result.quality.yStart <= resolvedOptions.atlasMaxStartY, 'yStart must satisfy atlas-A0 filter.');
assert(result.quality.startRank <= resolvedOptions.atlasMaxStartRank, 'startRank must satisfy atlas-A0 filter.');

fprintf('AE atlasA0 smoke passed. Policy: %s. Valid points: %d/%d. Last valid frequency: %.3f kHz.\n', ...
    string(result.quality.policyName), result.quality.validCount, result.quality.pointCount, result.quality.lastValidFrequency_kHz);
end
