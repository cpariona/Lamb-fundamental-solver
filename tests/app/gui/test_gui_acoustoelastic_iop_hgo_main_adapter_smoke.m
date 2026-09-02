%TEST_GUI_ACOUSTOELASTIC_IOP_HGO_MAIN_ADAPTER_SMOKE Smoke test for main GUI AE adapter.

fprintf('Running Acoustoelastic IOP/HGO main GUI adapter smoke test...\n');

baseGridParams = rlDefaultParams();
baseGridParams.fmin = 300;
baseGridParams.fmax = 15e3;
baseGridParams.numFrequencyPoints = "auto";
baseGridParams.frequencySpacing = "hybrid";
requestedFrequency = rlBuildFrequencyVector(baseGridParams);

aeControls = struct();
aeControls.R = struct('Value', 7.8);
aeControls.IOP = struct('Value', 15);
aeControls.k1 = struct('Value', 25);
aeControls.k2 = struct('Value', 100);
aeControls.rhoF = struct('Value', 1000);
aeControls.fluidBulkModulus = struct('Value', 2.2);
builtRequest = guiBuildAcoustoelasticIOPHGORequest(baseGridParams, aeControls, "Balanced");
assert(isequal(fieldnames(builtRequest), {'params'; 'options'}), ...
    'AE Main GUI request schema changed.');
assert(builtRequest.params.R == 7.8e-3, 'Main GUI radius conversion changed.');
assert(builtRequest.params.IOP == 15 * 133.322, 'Main GUI IOP conversion changed.');
assert(builtRequest.params.k1 == 25e3, 'Main GUI k1 conversion changed.');
assert(builtRequest.params.fluidBulkModulus == 2.2e9, ...
    'Main GUI fluid bulk-modulus conversion changed.');
assert(isequal(builtRequest.params.frequency, requestedFrequency), ...
    'Main GUI frequency request construction changed.');
assert(builtRequest.options.atlasNumYPoints == 600, ...
    'Main GUI Balanced atlas density changed.');
assert(builtRequest.options.atlasTopNMinima == 16, ...
    'Main GUI Balanced candidate count changed.');
assert(~isfield(builtRequest.options, 'aeGuiAtlasPreset'), ...
    'Main GUI request builder must not apply the interactive surface bundle.');
assert(string(builtRequest.options.executionProfileMetadata.requestedExecutionProfile) == "Balanced", ...
    'Main GUI requested execution-profile metadata changed.');
assert(string(builtRequest.options.executionProfileMetadata.effectiveExecutionProfile) == "Balanced", ...
    'Main GUI effective execution-profile metadata changed.');

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
params.frequency = requestedFrequency;

options = defaultAcoustoelasticIOPHGOOptions();
options.M54_variant = "corrected";
options.normalizeRows = false;
options.atlasBranchPolicy = "atlasA0";
options.atlasNumYPoints = 300;
options.atlasTopNMinima = 12;

guiRequest = struct();
guiRequest.params = params;
guiRequest.options = options;

result = guiRunAcoustoelasticIOPHGOModel(guiRequest);
expectedRawResult = solveAcoustoelasticIOPHGOBranch( ...
    params, result.metadata.options);

assert(isequal(fieldnames(result), {'modelName'; 'branchName'; 'frequency'; ...
    'phaseVelocity'; 'wavenumber'; 'kThickness'; 'branches'; 'metadata'; ...
    'diagnostics'}), 'AE Main GUI normalized result schema changed.');
assert(isequal(fieldnames(result.branches), {'modelName'; 'branchName'; ...
    'frequency'; 'phaseVelocity'; 'wavenumber'; 'kThickness'; 'metadata'; ...
    'diagnostics'}), 'AE Main GUI branch schema changed.');
assert(isequal(fieldnames(result.metadata), {'params'; 'options'; 'rawResult'; ...
    'adapter'; 'elapsedSeconds'; 'executionProfile'}), ...
    'AE Main GUI metadata schema changed.');
assert(isstruct(result), 'AE main GUI adapter must return a struct.');
assert(string(result.modelName) == "AcoustoelasticIOPHGO", 'Unexpected AE modelName.');
assert(isfield(result, 'branches') && isstruct(result.branches), 'AE adapter must return normalized branches.');
assert(isfield(result, 'metadata') && isfield(result.metadata, 'rawResult'), 'AE adapter must preserve rawResult.');
assert(numel(result.frequency) == numel(params.frequency), 'AE frequency length mismatch.');
assert(numel(result.phaseVelocity) == numel(params.frequency), 'AE Cp length mismatch.');
assert(numel(result.frequency) > 100, 'AE adapter fixture must use the shared dense output grid.');
assert(any(isfinite(result.phaseVelocity)), 'AE adapter must produce at least one finite Cp value.');
assert(isfield(result.metadata.rawResult, 'validCp'), 'AE raw result must include validCp.');
assert(any(result.metadata.rawResult.validCp), 'AE raw result must contain at least one valid Cp point.');
assert(isfield(result.metadata.rawResult, 'trackingFrequency'), 'AE raw result must include internal tracking frequency.');
assert(numel(result.metadata.rawResult.trackingFrequency) >= numel(result.frequency), ...
    'AE tracking grid must be at least as dense as the requested output grid.');
assert(isfield(result.branches, 'frequency'), 'AE normalized branch must include frequency.');
assert(isfield(result.branches, 'phaseVelocity'), 'AE normalized branch must include phaseVelocity.');
assert(isfield(result.branches, 'diagnostics'), 'AE normalized branch must include diagnostics.');
assert(isequaln(result.metadata.rawResult.Cp, expectedRawResult.Cp), ...
    'AE Main GUI Cp must equal the maintained public solver output.');
assert(isequal(result.metadata.rawResult.validCp, expectedRawResult.validCp), ...
    'AE Main GUI validCp must equal the maintained public solver output.');
assert(isequaln(result.metadata.rawResult.reliability, expectedRawResult.reliability), ...
    'AE Main GUI reliability must equal the maintained public solver output.');
assert(isequal(result.branches.phaseVelocity, result.metadata.rawResult.Cp(:)), ...
    'AE Main GUI branch normalization must consume canonical Cp directly.');
assert(isequal(result.branches.diagnostics.valid, result.metadata.rawResult.validCp), ...
    'AE Main GUI branch normalization must consume canonical validCp directly.');
assert(isfield(result.metadata, 'elapsedSeconds') && isfinite(result.metadata.elapsedSeconds), ...
    'AE Main GUI elapsed time placement changed.');

fprintf('Acoustoelastic IOP/HGO main GUI adapter smoke test passed.\n');
