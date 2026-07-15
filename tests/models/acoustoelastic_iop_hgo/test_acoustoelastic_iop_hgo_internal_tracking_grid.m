clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

% Test that the IOP/HGO wrapper decouples atlas branch identification from
% the requested output-frequency grid. This test does not assume that the
% internal grid always resolves the A0-like branch; it verifies the structural
% contract and the conservative fallback behavior.

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
options.usePhysicalCpWindow = false;
options.atlasBranchPolicy = "atlasA0";
options.atlasNumYPoints = 600;
options.atlasTopNMinima = 16;
options.invalidateAtlasFallbackOutput = true;
options.useInternalAtlasTrackingGrid = true;
options.atlasInitializationMinFrequency_Hz = 300;
options.atlasInitializationNumFrequencyPoints = 50;

result = solveAcoustoelasticIOPHGOAtlasBranch(params, options);

assert(isstruct(result), 'Result must be a struct.');
assert(isfield(result, 'internalAtlasTracking'), 'Result must report internal tracking metadata.');
assert(result.internalAtlasTracking.Used == true, 'Internal atlas tracking grid must be used.');
assert(numel(result.frequency) == numel(params.frequency), 'Official output must remain on the requested grid.');
assert(all(abs(result.frequency(:) - params.frequency(:)) < 1e-9), 'Output frequency must match requested frequency.');
assert(isfield(result, 'trackingFrequency'), 'Result must expose the internal tracking frequency grid.');
assert(numel(result.trackingFrequency) > numel(params.frequency), 'Tracking grid should contain additional internal frequencies.');
assert(min(result.trackingFrequency) <= options.atlasInitializationMinFrequency_Hz * (1 + 1e-12), ...
    'Tracking frequency should include the internal initialization range.');

if result.reliability.SelectionFallbackUsed
    assert(isfield(result, 'fallbackCandidateCp'), 'Fallback candidate must be preserved when fallback is used.');
    assert(all(~result.validCp), 'Fallback-selected official output must be invalidated.');
    assert(result.reliability.ValidFraction == 0, 'Fallback-invalidated official output must report zero valid fraction.');
else
    assert(result.reliability.A0StartFilterPassed == true, 'Non-fallback branch should pass the A0-like start filter.');
    assert(any(result.validCp), 'Non-fallback internal tracking output should produce official valid Cp points.');
    assert(~isfield(result, 'fallbackCandidateCp'), 'Non-fallback output should not create fallback candidate fields.');
end

fprintf('test_acoustoelastic_iop_hgo_internal_tracking_grid passed. Fallback=%d, valid points: %d/%d.\n', ...
    result.reliability.SelectionFallbackUsed, nnz(result.validCp), numel(result.validCp));
