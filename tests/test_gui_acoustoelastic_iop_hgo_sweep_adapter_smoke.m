%TEST_GUI_ACOUSTOELASTIC_IOP_HGO_SWEEP_ADAPTER_SMOKE Smoke test for AE GUI sweep adapter.
%
% This validates the non-interactive GUI sweep adapter path without exposing the
% Acoustoelastic IOP/HGO family in SweepTool_GUI controls yet.

fprintf('Running Acoustoelastic IOP/HGO GUI sweep adapter smoke test...\n');

params = struct();
params.R = 7.8e-3;
params.thickness = 550e-6;
params.mu = 50e3;
params.k1 = 25e3;
params.k2 = 100;
params.rho = 1060;
params.rhoF = 1000;
params.fluidBulkModulus = 2.2e9;
params.frequency = logspace(log10(300), log10(8e3), 12);
params.IOP = 15 * 133.322;

controls = struct();
controls.M54_variant = "corrected";
controls.normalizeRows = false;
controls.usePhysicalCpWindow = false;
controls.atlasBranchPolicy = "atlasA0";
controls.atlasNumYPoints = 180;
controls.atlasTopNMinima = 8;

request = guiBuildSweepRequest("acoustoelastic_iop_hgo", ...
    'modelLabel', "Acoustoelastic IOP/HGO", ...
    'branchName', "atlasA0", ...
    'sweepField', "IOP", ...
    'sweepLabel', "IOP", ...
    'sweepValuesDisplay', [10 15], ...
    'displayUnit', "mmHg", ...
    'displayScale', 133.322, ...
    'baseParams', params, ...
    'controls', controls, ...
    'outputMode', "workspace", ...
    'outputTaskName', "test_ae_iop_sweep");

sweepOutput = guiRunSweep(request);

assert(isstruct(sweepOutput), 'AE GUI sweep adapter must return a struct.');
assert(string(sweepOutput.modelFamily) == "acoustoelastic_iop_hgo", 'Unexpected model family.');
assert(string(sweepOutput.modelName) == "AcoustoelasticIOPHGO", 'Unexpected model name.');
assert(string(sweepOutput.branchName) == "atlasA0", 'Unexpected branch name.');
assert(isfield(sweepOutput, 'rawResults'), 'AE sweep output must include rawResults.');
assert(isfield(sweepOutput, 'summary'), 'AE sweep output must include summary.');
assert(isfield(sweepOutput, 'summaryTable'), 'AE sweep output must include summaryTable.');
assert(isfield(sweepOutput, 'normalized'), 'AE sweep output must include normalized output.');

assert(isequal(sweepOutput.sweepSpec.values, [10 15] * 133.322), ...
    'IOP display values must be converted from mmHg to Pa.');
assert(string(sweepOutput.sweepSpec.units) == "mmHg", ...
    'IOP display unit must propagate to sweepSpec units.');
assert(numel(sweepOutput.rawResults.conditions) == 2, ...
    'AE sweep must run one condition per requested value.');
assert(height(sweepOutput.summaryTable) == 2, ...
    'AE summary table must have one row per requested value.');
assert(numel(sweepOutput.normalized.curves) == 2, ...
    'AE normalized output must have one curve per requested value.');
assert(~isempty(sweepOutput.normalized.dispersionTable), ...
    'AE normalized output must expose the dispersion table.');

for i = 1:numel(sweepOutput.normalized.curves)
    curve = sweepOutput.normalized.curves(i);
    assert(~isempty(curve.frequency_Hz), 'AE normalized curve must include frequency_Hz.');
    assert(~isempty(curve.Cp_mps), 'AE normalized curve must include Cp_mps.');
    assert(~isempty(curve.validMask), 'AE normalized curve must include validMask.');
    assert(isequal(size(curve.frequency_Hz), size(curve.Cp_mps)), ...
        'AE normalized frequency and Cp vectors must match.');
    assert(isequal(size(curve.Cp_mps), size(curve.validMask)), ...
        'AE normalized Cp and validity vectors must match.');
    assert(any(curve.validMask), 'AE normalized curve must contain at least one valid point.');
end

fprintf('Acoustoelastic IOP/HGO GUI sweep adapter smoke test passed.\n');
