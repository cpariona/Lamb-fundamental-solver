clear; clc;
startup

% Test that the IOP/HGO wrapper can decouple atlas branch identification from
% the requested output-frequency start. The requested output starts at 1 kHz,
% but the internal tracking grid starts at 300 Hz and should recover the same
% A0-like identity used by GUI-like runs.

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
assert(result.reliability.SelectionFallbackUsed == false, 'Internal tracking should avoid unfiltered fallback for this fixture.');
assert(result.reliability.A0StartFilterPassed == true, 'Internal tracking should pass the A0-like start filter.');
assert(any(result.validCp), 'Internal tracking fixture should produce official valid Cp points.');
assert(~isfield(result, 'fallbackCandidateCp'), 'Valid internal tracking output should not create fallback candidate fields.');
assert(min(result.trackingFrequency) <= options.atlasInitializationMinFrequency_Hz * (1 + 1e-12), ...
    'Tracking frequency should include the internal initialization range.');

fprintf('test_acoustoelastic_iop_hgo_internal_tracking_grid passed. Valid points: %d/%d.\n', ...
    nnz(result.validCp), numel(result.validCp));
