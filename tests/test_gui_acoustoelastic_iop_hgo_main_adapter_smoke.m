%TEST_GUI_ACOUSTOELASTIC_IOP_HGO_MAIN_ADAPTER_SMOKE Smoke test for main GUI AE adapter.

fprintf('Running Acoustoelastic IOP/HGO main GUI adapter smoke test...\n');

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
params.frequency = logspace(log10(300), log10(15e3), 35);

options = defaultAcoustoelasticIOPHGOOptions();
options.M54_variant = "corrected";
options.normalizeRows = false;
options.usePhysicalCpWindow = false;
options.atlasBranchPolicy = "atlasA0";
options.atlasNumYPoints = 300;
options.atlasTopNMinima = 12;

guiRequest = struct();
guiRequest.params = params;
guiRequest.options = options;

result = guiRunAcoustoelasticIOPHGOModel(guiRequest);

assert(isstruct(result), 'AE main GUI adapter must return a struct.');
assert(string(result.modelName) == "AcoustoelasticIOPHGO", 'Unexpected AE modelName.');
assert(isfield(result, 'branches') && isstruct(result.branches), 'AE adapter must return normalized branches.');
assert(isfield(result, 'metadata') && isfield(result.metadata, 'rawResult'), 'AE adapter must preserve rawResult.');
assert(numel(result.frequency) == numel(params.frequency), 'AE frequency length mismatch.');
assert(numel(result.phaseVelocity) == numel(params.frequency), 'AE Cp length mismatch.');
assert(any(isfinite(result.phaseVelocity)), 'AE adapter must produce at least one finite Cp value.');
assert(isfield(result.metadata.rawResult, 'validCp'), 'AE raw result must include validCp.');
assert(any(result.metadata.rawResult.validCp), 'AE raw result must contain at least one valid Cp point.');
assert(isfield(result.branches, 'frequency'), 'AE normalized branch must include frequency.');
assert(isfield(result.branches, 'phaseVelocity'), 'AE normalized branch must include phaseVelocity.');
assert(isfield(result.branches, 'diagnostics'), 'AE normalized branch must include diagnostics.');

fprintf('Acoustoelastic IOP/HGO main GUI adapter smoke test passed.\n');
