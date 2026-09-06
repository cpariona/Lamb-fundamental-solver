function test_acoustoelastic_iop_hgo_internal_tracking_grid()
%TEST_ACOUSTOELASTIC_IOP_HGO_INTERNAL_TRACKING_GRID Validate internal tracking.

params = struct();
params.R = 7.8e-3;
params.thickness = 550e-6;
params.IOP = 15 * 133.322;
params.mu = 50e3;
params.k1 = 25e3;
params.k2 = 100;
params.rho = 1060;
params.rhoF = 1000;
params.fluidBulkModulus = 2.2e9;
params.frequency = logspace(log10(1000), log10(15e3), 35);

options = defaultAcoustoelasticIOPHGOOptions();
options.M54_variant = "corrected";
options.normalizeRows = false;
options.atlasBranchPolicy = "atlasA0";
options.atlasNumYPoints = 600;
options.atlasTopNMinima = 16;
options.invalidateAtlasFallbackOutput = true;
options.useInternalAtlasTrackingGrid = true;
options.atlasInitializationMinFrequency_Hz = 300;
options.atlasInitializationNumFrequencyPoints = 50;

result = solveAcoustoelasticIOPHGOBranch(params, options);

assert(isstruct(result), 'Result must be a struct.');
assert(isfield(result, 'internalAtlasTracking'), 'Result must report internal tracking metadata.');
assert(result.internalAtlasTracking.Used == true, 'Internal atlas tracking grid must be used.');
assert(numel(result.frequency_Hz) == numel(params.frequency), 'Official output must remain on the requested grid.');
assert(all(abs(result.frequency_Hz(:) - params.frequency(:)) < 1e-9), 'Output frequency must match requested frequency.');
assert(isfield(result, 'trackingFrequency'), 'Result must expose the internal tracking frequency grid.');
assert(numel(result.trackingFrequency) > numel(params.frequency), 'Tracking grid should contain additional internal frequencies.');
assert(min(result.trackingFrequency) <= options.atlasInitializationMinFrequency_Hz * (1 + 1e-12), ...
    'Tracking frequency should include the internal initialization range.');

if result.quality.selectionFallbackUsed
    assert(isfield(result, 'fallbackCandidateCp'), 'Fallback candidate must be preserved when fallback is used.');
    assert(all(~result.validMask), 'Fallback-selected official output must be invalidated.');
    assert(result.quality.validFraction == 0, 'Fallback-invalidated official output must report zero valid fraction.');
else
    assert(result.quality.a0StartFilterPassed == true, 'Non-fallback branch should pass the A0-like start filter.');
    assert(any(result.validMask), 'Non-fallback internal tracking output should produce official valid Cp points.');
    assert(~isfield(result, 'fallbackCandidateCp'), 'Non-fallback output should not create fallback candidate fields.');
end

fprintf('AE internal tracking grid passed. Fallback=%d, valid points: %d/%d.\n', ...
    result.quality.selectionFallbackUsed, nnz(result.validMask), numel(result.validMask));
end
