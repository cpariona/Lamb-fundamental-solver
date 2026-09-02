clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

% Test conservative official-output policy for fallback-selected atlasA0 branches.
% This test disables the internal tracking grid deliberately, so the fixture
% still exercises the fallback-invalidation path directly.

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
options.atlasNumYPoints = 300;
options.atlasTopNMinima = 12;
options.invalidateAtlasFallbackOutput = true;
options.useInternalAtlasTrackingGrid = false;

result = solveAcoustoelasticIOPHGOBranch(params, options);

assert(isstruct(result), 'Result must be a struct.');
assert(isfield(result, 'reliability'), 'Result must include reliability.');
assert(result.quality.SelectionFallbackUsed == true, ...
    'This fixture should exercise an unfiltered fallback selection.');
assert(result.quality.A0StartFilterPassed == false, ...
    'Fallback fixture should fail the A0-like start filter.');
assert(isfield(result, 'fallbackCandidateCp'), ...
    'Fallback candidate Cp must be preserved for diagnostics.');
assert(any(isfinite(result.fallbackCandidateCp)), ...
    'Fallback candidate should preserve the finite diagnostic curve.');
assert(all(~result.validMask), ...
    'Official validCp must be false when fallback output is invalidated.');
assert(all(~isfinite(result.phaseVelocity_mps)), ...
    'Official Cp must be NaN when fallback output is invalidated.');
assert(result.quality.ValidFraction == 0, ...
    'Official reliability must report zero valid fraction after fallback invalidation.');
assert(all(result.pointStatus == "fallbackRejectedA0StartFilter"), ...
    'Point status must identify fallback rejection.');

fprintf('test_acoustoelastic_iop_hgo_fallback_invalidation passed. Fallback candidate preserved; official Cp invalidated.\n');
