function test_ae_result_schema_characterization()
%TEST_AE_RESULT_SCHEMA_CHARACTERIZATION Protect canonical AE semantics.

params = representativeParams(logspace(log10(300), log10(15e3), 12));
options = representativeOptions();
options.useInternalAtlasTrackingGrid = false;

result = solveAcoustoelasticIOPHGOBranch(params, options);
assertCanonicalResult(result, params.frequency);
assert(result.model == "acoustoelastic_iop_hgo" && result.branch == "atlasA0");
assert(~isfield(result, 'Cp') && ~isfield(result, 'validCp') && ...
    ~isfield(result, 'frequency') && ~isfield(result, 'reliability'), ...
    'Historical AE output aliases must not remain public.');
assert(isfield(result.configuration, 'requested') && isfield(result.configuration, 'effective'));
assert(isequaln(result.configuration.requested.parameters, params));
assert(isequaln(result.configuration.requested.options, options));
assert(result.configuration.effective.parameters.alpha == result.directParams.alpha);
assert(isfield(result, 'execution') && result.execution.engine == "atlasA0_iop_hgo");
assertQualityParity(result);
assertDiagnosticParity(result);

directResult = solveAcoustoelasticAtlasBranch(result.directParams, options);
assertCanonicalResult(directResult, params.frequency);
assert(isfield(directResult.configuration, 'requested') && ...
    isfield(directResult.configuration, 'effective'));

internalOptions = options;
internalOptions.useInternalAtlasTrackingGrid = true;
internalOptions.atlasInitializationMinFrequency_Hz = 200;
internalOptions.atlasInitializationNumFrequencyPoints = 20;
internalResult = solveAcoustoelasticIOPHGOBranch(params, internalOptions);
assertCanonicalResult(internalResult, params.frequency);
assert(isempty(internalResult.objectiveMap));
assert(size(internalResult.trackingObjectiveMap, 2) == numel(internalResult.trackingFrequency));
assert(internalResult.diagnostics.internalAtlasTrackingUsed == true);

identityOptions = options;
identityOptions.atlasBranchPolicy = "identityA0Diagnostic";
identityResult = solveAcoustoelasticIOPHGOBranch(params, identityOptions);
assertCanonicalResult(identityResult, params.frequency);
assert(isfield(identityResult.diagnostics, 'identityA0'), ...
    'identityA0 must remain diagnostic-only.');
identity = identityResult.diagnostics.identityA0;
assert(isequal(size(identity.CpCandidate), size(identityResult.phaseVelocity_mps)));
assert(isa(identity.candidateClass, 'string'));

fallbackParams = representativeParams(logspace(log10(1000), log10(15e3), 35));
fallbackOptions = representativeOptions();
fallbackOptions.atlasNumYPoints = 300;
fallbackOptions.atlasTopNMinima = 12;
fallbackOptions.invalidateAtlasFallbackOutput = true;
fallbackOptions.useInternalAtlasTrackingGrid = false;
fallbackResult = solveAcoustoelasticIOPHGOBranch(fallbackParams, fallbackOptions);
assert(fallbackResult.quality.SelectionFallbackUsed == true);
assert(all(isnan(fallbackResult.phaseVelocity_mps)) && all(~fallbackResult.validMask));
assert(any(isfinite(fallbackResult.fallbackCandidateCp)));

physicalSweep = aeRunSweep(params, "IOP", params.IOP, options, ...
    struct('Name', "iop", 'Label', "IOP"));
assert(isequaln(physicalSweep.conditions.result.quality, physicalSweep.conditions.quality));
assert(~isfield(physicalSweep.conditions, 'reliability'));

axisSpec = struct('Field', "IOP", 'Values', params.IOP, 'Name', "IOP", ...
    'Label', "IOP", 'Unit', "Pa", 'ValueScale', 1, 'ValueFormatter', "%.6g");
gridSweep = aeRunGridSweep(params, axisSpec, options, struct('Name', "grid"));
assert(isequaln(gridSweep.conditions.result.quality, gridSweep.conditions.quality));
assert(~isfield(gridSweep.conditions, 'reliability'));

fprintf('AE result schema characterization passed.\n');
end

function params = representativeParams(frequency)
params = struct('R', 7.8e-3, 'thickness', 550e-6, 'mu', 50e3, ...
    'k1', 25e3, 'k2', 100, 'rho', 1060, 'rhoF', 1000, ...
    'fluidBulkModulus', 2.2e9, 'frequency', frequency, 'IOP', 15 * 133.322);
end

function options = representativeOptions()
options = defaultAcoustoelasticIOPHGOOptions();
options.M54_variant = "corrected";
options.normalizeRows = false;
options.atlasBranchPolicy = "atlasA0";
options.atlasNumYPoints = 180;
options.atlasTopNMinima = 8;
options.invalidateAtlasFallbackOutput = false;
end

function assertCanonicalResult(result, requestedFrequency)
required = {'model', 'branch', 'frequency_Hz', 'phaseVelocity_mps', ...
    'wavenumber_radpm', 'validMask', 'quality', 'diagnostics', ...
    'configuration', 'execution'};
assert(all(isfield(result, required)), 'Canonical AE result fields are incomplete.');
rowSize = size(requestedFrequency(:).');
assert(isequal(size(result.frequency_Hz), rowSize));
assert(isequal(size(result.phaseVelocity_mps), rowSize));
assert(isequal(size(result.wavenumber_radpm), rowSize));
assert(isequal(size(result.validMask), rowSize));
assert(isequaln(result.frequency_Hz, requestedFrequency(:).'));
assert(isa(result.validMask, 'logical'));
assert(all(isnan(result.phaseVelocity_mps(~result.validMask))));
end

function assertQualityParity(result)
valid = result.validMask & isfinite(result.phaseVelocity_mps);
quality = result.quality;
assert(quality.TotalPoints == numel(result.phaseVelocity_mps));
assert(quality.ValidPoints == nnz(valid));
assert(quality.MissingPoints == nnz(~valid));
assert(quality.ValidFraction == nnz(valid) / max(numel(valid), 1));
assert(quality.InterpolatedPoints == nnz(result.interpolatedCp));
assert(quality.ExplicitBranchPoints == nnz(result.branchExistsAtFrequency));
end

function assertDiagnosticParity(result)
diagnostics = result.diagnostics;
assert(diagnostics.validCpPoints == nnz(result.validMask));
assert(diagnostics.totalPoints == numel(result.phaseVelocity_mps));
assert(diagnostics.missingBranchPoints == nnz(~result.validMask));
assert(diagnostics.validFraction == result.quality.ValidFraction);
end
