function test_ae_gui_main_adapter_smoke()
%TEST_AE_GUI_MAIN_ADAPTER_SMOKE Validate AE Main GUI adapter.

fprintf('Running AE IOP/HGO main GUI adapter smoke test...\n');

baseGridParams = lamb.models.rayleigh_lamb.rlDefaultParams();
baseGridParams.fmin = 300;
baseGridParams.fmax = 16e3;
baseGridParams.mu = 158e3;
baseGridParams.rho = 1070;
baseGridParams.nu = 0.4999;
baseGridParams.thickness = 0.5e-3;
baseGridParams.numFrequencyPoints = "auto";
baseGridParams.frequencySpacing = "hybrid";
requestedFrequency = lamb.grids.buildFrequencyVector(baseGridParams);

aeControls = struct();
aeControls.R = struct('Value', 7.8);
aeControls.IOP = struct('Value', 15);
aeControls.k1 = struct('Value', 25);
aeControls.k2 = struct('Value', 100);
aeControls.rhoF = struct('Value', 1000);
aeControls.fluidBulkModulus = struct('Value', 2.2);
builtRequest = aeGuiBuildRequest(baseGridParams, aeControls, "Balanced");
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

params = builtRequest.params;
guiRequest = builtRequest;
result = aeGuiRunModel(guiRequest);
expectedRawResult = lamb.models.acoustoelastic_iop_hgo.aeSolveBranch(params, result.metadata.options);
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
assert(all(isfinite(result.phaseVelocity)) && all(result.metadata.modelResult.validMask), ...
    'Actual Main GUI request must retain the complete initialized atlasA0 branch.');

assert(isequaln(result.metadata.modelResult.phaseVelocity_mps, ...
    expectedRawResult.phaseVelocity_mps), ...
    'AE Main GUI Cp must equal the maintained public solver output.');
assert(isequal(result.metadata.modelResult.validMask, expectedRawResult.validMask), ...
    'AE Main GUI validMask must equal the maintained public solver output.');
assert(isequaln(result.metadata.modelResult.quality, expectedRawResult.quality), ...
    'AE Main GUI quality must equal the maintained public solver output.');
assertSameNormalizedCurve(result.branches, expectedView.branches);
assert(isequal(result.branches.phaseVelocity, ...
    result.metadata.modelResult.phaseVelocity_mps(:)), ...
    'AE normalized branch must consume canonical Cp directly.');
assert(isequal(result.branches.diagnostics.valid, ...
    result.metadata.modelResult.validMask(:)), ...
    'AE normalized branch must consume canonical validity directly.');
assert(isfield(result.metadata, 'elapsedSeconds') && isfinite(result.metadata.elapsedSeconds));

fprintf('AE IOP/HGO main GUI adapter smoke test passed.\n');
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

function assertSameNormalizedCurve(actual, expected)
assert(actual.modelName == expected.modelName);
assert(actual.rawModelName == expected.rawModelName);
assert(actual.branchName == expected.branchName);
assert(isequaln(actual.frequency, expected.frequency));
assert(isequaln(actual.phaseVelocity, expected.phaseVelocity));
assert(isequaln(actual.wavenumber, expected.wavenumber));
assert(isequaln(actual.kThickness, expected.kThickness));
assert(isequal(actual.diagnostics.valid, expected.diagnostics.valid));
end
