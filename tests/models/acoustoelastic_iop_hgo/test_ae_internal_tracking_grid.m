function test_ae_internal_tracking_grid()
%TEST_AE_INTERNAL_TRACKING_GRID Validate internal tracking.

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

options = lamb.models.acoustoelastic_iop_hgo.aeDefaultOptions();
options.M54_variant = "corrected";
options.normalizeRows = false;
options.atlasBranchPolicy = "atlasA0";
options.atlasNumYPoints = 600;
options.atlasTopNMinima = 16;
options.invalidateAtlasFallbackOutput = true;
options.useInternalAtlasTrackingGrid = true;
options.atlasInitializationMinFrequency_Hz = 300;
options.atlasInitializationNumFrequencyPoints = 50;

result = lamb.models.acoustoelastic_iop_hgo.aeSolveBranch(params, options);

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
assertRequestedSamplingInvariant();
end

function assertRequestedSamplingInvariant()
params = struct('R', 7.8e-3, 'thickness', 0.5e-3, 'mu', 158e3, ...
    'IOP', 15*133.322, 'k1', 25e3, 'k2', 100, 'rho', 1070, ...
    'rhoF', 1000, 'fluidBulkModulus', 2.2e9);
options = lamb.models.acoustoelastic_iop_hgo.configuration.aeResolveConfiguration( ...
    struct('normalizeRows', false), 'NumericalPreset', "Balanced");
commonFrequency = [300, 1000, 4000, 8000, 16000];
sparseFrequency = unique([commonFrequency, logspace(log10(300), log10(16000), 20)]);
denseFrequency = unique([sparseFrequency, linspace(300, 16000, 300)]);
params.frequency = sparseFrequency;
sparse = lamb.models.acoustoelastic_iop_hgo.aeSolveBranch(params, options);
params.frequency = denseFrequency;
dense = lamb.models.acoustoelastic_iop_hgo.aeSolveBranch(params, options);
sparseCp = sparse.phaseVelocity_mps;
denseCp = dense.phaseVelocity_mps;
assert(all(sparse.validMask) && all(dense.validMask));
assert(isequal(sparse.trackingFrequency, dense.trackingFrequency));
assert(isequaln(sparse.minimaTable, dense.minimaTable));
assert(isequaln(sparse.branchTable, dense.branchTable));
assert(isequaln(sparse.selectedBranch, dense.selectedBranch));
assert(sparse.selectedBranch.FrequencyStart_Hz == sparse.trackingFrequency(1));
[present, indices] = ismember(sparseFrequency, denseFrequency);
assert(all(present));
% Identical frequency/seed/objective/refinement inputs must give exact parity.
assert(isequaln(sparseCp, denseCp(indices)));
assert(isequaln(sparse.nearestRank, dense.nearestRank(indices)));
assert(isequaln(sparse.nearestBranchID, dense.nearestBranchID(indices)));

% Removing an internal identity endpoint must not allow requested evaluation
% to bridge that gap, even with an otherwise complete selected branch.
trackingParams = sparse.directParams;
trackingParams.frequency = sparse.trackingFrequency;
tracking = lamb.models.acoustoelastic_iop_hgo.solvers.aeSolveAtlasBranch(trackingParams, options);
removedFrequency = tracking.frequency_Hz(10);
tracking.minimaTable(tracking.minimaTable.Frequency_Hz == removedFrequency & ...
    tracking.minimaTable.BranchID == tracking.selectedBranchID, :) = [];
trackingParams.frequency = sqrt(tracking.frequency_Hz(9)*removedFrequency);
fields = lamb.models.acoustoelastic_iop_hgo.tracking.aeEvaluateSelectedAtlasBranch(tracking, trackingParams, options);
assert(~fields.validCp && isnan(fields.Cp) && ~fields.interpolatedCp);
params.frequency = [];
emptyResult = lamb.models.acoustoelastic_iop_hgo.aeSolveBranch(params, options);
assert(isempty(emptyResult.frequency_Hz) && isempty(emptyResult.validMask));
fprintf('AE requested sampling identity and gap guards passed.\n');
end
