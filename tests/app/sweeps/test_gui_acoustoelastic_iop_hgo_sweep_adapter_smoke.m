function test_gui_acoustoelastic_iop_hgo_sweep_adapter_smoke()
%TEST_GUI_ACOUSTOELASTIC_IOP_HGO_SWEEP_ADAPTER_SMOKE Validate AE SweepTool adapter.

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

assert(isstruct(sweepOutput));
assert(string(sweepOutput.modelFamily) == "acoustoelastic_iop_hgo");
assert(string(sweepOutput.modelName) == "AcoustoelasticIOPHGO");
assert(string(sweepOutput.branchName) == "atlasA0");
assert(isfield(sweepOutput, 'sweepResult'));
assert(isfield(sweepOutput, 'summary'));
assert(isfield(sweepOutput, 'summaryTable'));
assert(isfield(sweepOutput, 'normalized'));
assert(isequal(sweepOutput.sweepSpec.values, [10 15] * 133.322));
assert(string(sweepOutput.sweepSpec.units) == "mmHg");
assert(numel(sweepOutput.sweepResult.conditions) == 2);
assert(height(sweepOutput.summaryTable) == 2);
assert(numel(sweepOutput.normalized.curves) == 2);
assert(~isempty(sweepOutput.normalized.dispersionTable));
assert(sweepOutput.sweepResult.options.atlasNumYPoints == 180);
assert(sweepOutput.sweepResult.options.atlasTopNMinima == 8);
assert(string(sweepOutput.executionProfile.requestedExecutionProfile) == "Fast");
assert(string(sweepOutput.executionProfile.surfaceDefaultExecutionProfile) == "Fast");
assert(isfield(sweepOutput, 'elapsedSeconds') && isfinite(sweepOutput.elapsedSeconds));

fallbackInvalidationObserved = false;
officialValidPointObserved = false;
for i = 1:numel(sweepOutput.normalized.curves)
    curve = sweepOutput.normalized.curves(i);
    modelResult = sweepOutput.sweepResult.conditions(i).result;

    required = {'label','sweepValue','sweepValueDisplay','frequency_Hz', ...
        'Cp_mps','validMask','lastValidFrequency_Hz','rawBranch'};
    assert(all(isfield(curve, required)), 'AE normalized curve schema is incomplete.');
    assert(~isempty(curve.frequency_Hz));
    assert(~isempty(curve.Cp_mps));
    assert(~isempty(curve.validMask));
    assert(isequal(size(curve.frequency_Hz), size(curve.Cp_mps)));
    assert(isequal(size(curve.Cp_mps), size(curve.validMask)));
    assert(isequal(curve.validMask(:), modelResult.validMask(:)));

    officialValidPointObserved = officialValidPointObserved || any(curve.validMask(:));
    if isfield(modelResult, 'fallbackCandidateCp')
        fallbackInvalidationObserved = true;
        assert(all(~modelResult.validMask));
        assert(any(isfinite(modelResult.fallbackCandidateCp)));
    end
end

firstCondition = sweepOutput.sweepResult.conditions(1);
expectedFirstResult = solveAcoustoelasticIOPHGOBranch( ...
    firstCondition.params, sweepOutput.sweepResult.options);
assert(isequaln(firstCondition.result.phaseVelocity_mps, expectedFirstResult.phaseVelocity_mps));
assert(isequal(firstCondition.result.validMask, expectedFirstResult.validMask));
assert(isequaln(firstCondition.quality, expectedFirstResult.quality));
assert(isequaln(firstCondition.diagnostics, expectedFirstResult.diagnostics));
assert(fallbackInvalidationObserved || officialValidPointObserved, ...
    'AE sweep adapter must expose valid official points or preserved fallback diagnostics.');

fprintf('Acoustoelastic IOP/HGO GUI sweep adapter smoke test passed.\n');
end
