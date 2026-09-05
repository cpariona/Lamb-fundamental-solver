function test_gui_acoustoelastic_iop_hgo_main_adapter_smoke()
%TEST_GUI_ACOUSTOELASTIC_IOP_HGO_MAIN_ADAPTER_SMOKE Validate AE Main GUI adapter.

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
assert(all(isfield(builtRequest, {'params','options'})), ...
    'AE Main GUI request schema is incomplete.');
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
    'Main GUI request builder must not apply an alternate surface bundle.');
assert(string(builtRequest.options.executionProfileMetadata.requestedExecutionProfile) == "Balanced");
assert(string(builtRequest.options.executionProfileMetadata.effectiveExecutionProfile) == "Balanced");

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

guiRequest = struct('params', params, 'options', options);
result = guiRunAcoustoelasticIOPHGOModel(guiRequest);
expectedRawResult = solveAcoustoelasticIOPHGOBranch(params, result.metadata.options);
expectedView = guiBuildModelResultView(expectedRawResult, "expectedAEView");

assertCommonView(result);
assertCommonBranches(result.branches);
assert(string(result.modelName) == "AcoustoelasticIOPHGO");
assert(string(result.branchName) == "atlasA0");
assert(isfield(result.metadata, 'modelResult'));
assert(numel(result.frequency) == numel(params.frequency));
assert(numel(result.phaseVelocity) == numel(params.frequency));
assert(numel(result.frequency) > 100, ...
    'AE adapter fixture must use the shared dense output grid.');
assert(any(isfinite(result.phaseVelocity)), ...
    'AE adapter must produce at least one finite Cp value.');

assert(isequaln(result.metadata.modelResult.phaseVelocity_mps, ...
    expectedRawResult.phaseVelocity_mps), ...
    'AE Main GUI Cp must equal the maintained public solver output.');
assert(isequal(result.metadata.modelResult.validMask, expectedRawResult.validMask), ...
    'AE Main GUI validMask must equal the maintained public solver output.');
assert(isequaln(result.metadata.modelResult.quality, expectedRawResult.quality), ...
    'AE Main GUI quality must equal the maintained public solver output.');
assert(isequaln(result.branches, expectedView.branches), ...
    'AE Main GUI must use the shared normalized branch builder unchanged.');
assert(isequal(result.branches.phaseVelocity, ...
    result.metadata.modelResult.phaseVelocity_mps(:)), ...
    'AE normalized branch must consume canonical Cp directly.');
assert(isequal(result.branches.diagnostics.valid, ...
    result.metadata.modelResult.validMask(:)), ...
    'AE normalized branch must consume canonical validity directly.');
assert(isfield(result.metadata, 'elapsedSeconds') && isfinite(result.metadata.elapsedSeconds));

fprintf('Acoustoelastic IOP/HGO main GUI adapter smoke test passed.\n');
end

function assertCommonView(result)
required = {'modelName','branchName','frequency','phaseVelocity','wavenumber', ...
    'kThickness','branches','metadata','diagnostics'};
assert(all(isfield(result, required)), 'Main GUI normalized view schema is incomplete.');
end

function assertCommonBranches(branches)
required = {'modelName','rawModelName','branchName','frequency','phaseVelocity', ...
    'wavenumber','kThickness','metadata','diagnostics'};
assert(all(isfield(branches, required)), 'Normalized branch schema is incomplete.');
assert(iscolumn(branches.frequency));
assert(iscolumn(branches.phaseVelocity));
assert(iscolumn(branches.wavenumber));
assert(iscolumn(branches.kThickness));
end
