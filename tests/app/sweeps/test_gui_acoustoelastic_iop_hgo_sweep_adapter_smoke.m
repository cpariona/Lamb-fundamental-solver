%TEST_GUI_ACOUSTOELASTIC_IOP_HGO_SWEEP_ADAPTER_SMOKE Smoke test for AE GUI sweep adapter.

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

assert(isequal(fieldnames(sweepOutput), {'request'; 'modelFamily'; 'modelName'; ...
    'branchName'; 'sweepSpec'; 'rawResults'; 'summary'; 'summaryTable'; ...
    'normalized'; 'executionProfile'; 'elapsedSeconds'}), ...
    'AE SweepTool aggregate schema changed.');
assert(isequal(fieldnames(sweepOutput.rawResults), {'name'; 'label'; ...
    'sweepField'; 'sweepValues'; 'options'; 'baseParams'; 'conditions'; ...
    'summaryTable'}), 'AE SweepTool raw aggregate schema changed.');
assert(isequal(fieldnames(sweepOutput.rawResults.conditions), {'index'; ...
    'sweepField'; 'sweepValue'; 'sweepValueDisplay'; 'params'; 'result'; ...
    'reliability'; 'diagnostics'}), 'AE SweepTool point schema changed.');
assert(isequal(fieldnames(sweepOutput.normalized), {'modelFamily'; 'modelName'; ...
    'branchName'; 'sweepField'; 'sweepLabel'; 'sweepUnit'; 'displayScale'; ...
    'curves'; 'summaryTable'; 'dispersionTable'; 'branchTable'; 'metadata'}), ...
    'AE SweepTool normalized aggregate schema changed.');
assert(isstruct(sweepOutput), 'AE GUI sweep adapter must return a struct.');
assert(string(sweepOutput.modelFamily) == "acoustoelastic_iop_hgo", 'Unexpected model family.');
assert(string(sweepOutput.modelName) == "AcoustoelasticIOPHGO", 'Unexpected model name.');
assert(string(sweepOutput.branchName) == "atlasA0", 'Unexpected branch name.');
assert(isfield(sweepOutput, 'rawResults'), 'AE sweep output must include rawResults.');
assert(isfield(sweepOutput, 'summary'), 'AE sweep output must include summary.');
assert(isfield(sweepOutput, 'summaryTable'), 'AE sweep output must include summaryTable.');
assert(isfield(sweepOutput, 'normalized'), 'AE sweep output must include normalized output.');
assert(isequal(sweepOutput.sweepSpec.values, [10 15] * 133.322), 'IOP display values must be converted from mmHg to Pa.');
assert(string(sweepOutput.sweepSpec.units) == "mmHg", 'IOP display unit must propagate to sweepSpec units.');
assert(numel(sweepOutput.rawResults.conditions) == 2, 'AE sweep must run one condition per requested value.');
assert(height(sweepOutput.summaryTable) == 2, 'AE summary table must have one row per requested value.');
assert(numel(sweepOutput.normalized.curves) == 2, 'AE normalized output must have one curve per requested value.');
assert(~isempty(sweepOutput.normalized.dispersionTable), 'AE normalized output must expose the dispersion table.');
assert(sweepOutput.rawResults.options.atlasNumYPoints == 180, ...
    'AE SweepTool atlas density override changed.');
assert(sweepOutput.rawResults.options.atlasTopNMinima == 8, ...
    'AE SweepTool candidate-count override changed.');
assert(string(sweepOutput.executionProfile.requestedExecutionProfile) == "Fast", ...
    'AE SweepTool requested execution-profile metadata changed.');
assert(string(sweepOutput.executionProfile.surfaceDefaultExecutionProfile) == "Fast", ...
    'AE SweepTool surface-default metadata changed.');
assert(isfield(sweepOutput, 'elapsedSeconds') && isfinite(sweepOutput.elapsedSeconds), ...
    'AE SweepTool elapsed time placement changed.');

fallbackInvalidationObserved = false;
officialValidPointObserved = false;
for i = 1:numel(sweepOutput.normalized.curves)
    curve = sweepOutput.normalized.curves(i);
    rawResult = sweepOutput.rawResults.conditions(i).result;

    assert(isequal(fieldnames(curve), {'label'; 'sweepValue'; ...
        'sweepValueDisplay'; 'frequency_Hz'; 'Cp_mps'; 'validMask'; ...
        'lastValidFrequency_Hz'; 'rawBranch'}), ...
        'AE SweepTool normalized point schema changed.');
    assert(~isempty(curve.frequency_Hz), 'AE normalized curve must include frequency_Hz.');
    assert(~isempty(curve.Cp_mps), 'AE normalized curve must include Cp_mps.');
    assert(~isempty(curve.validMask), 'AE normalized curve must include validMask.');
    assert(isequal(size(curve.frequency_Hz), size(curve.Cp_mps)), 'AE normalized frequency and Cp vectors must match.');
    assert(isequal(size(curve.Cp_mps), size(curve.validMask)), 'AE normalized Cp and validity vectors must match.');
    assert(isequal(curve.validMask(:), rawResult.validCp(:)), 'AE normalized validMask must mirror raw validCp.');

    officialValidPointObserved = officialValidPointObserved || any(curve.validMask(:));

    if isfield(rawResult, 'fallbackCandidateCp')
        fallbackInvalidationObserved = true;
        assert(all(~rawResult.validCp), 'Fallback-invalidated raw result must not expose official validCp points.');
        assert(any(isfinite(rawResult.fallbackCandidateCp)), 'Fallback-invalidated raw result must preserve diagnostic candidate Cp.');
    end
end

firstCondition = sweepOutput.rawResults.conditions(1);
expectedFirstResult = solveAcoustoelasticIOPHGOBranch( ...
    firstCondition.params, sweepOutput.rawResults.options);
assert(isequaln(firstCondition.result.Cp, expectedFirstResult.Cp), ...
    'AE SweepTool point Cp must equal one maintained public solver call.');
assert(isequal(firstCondition.result.validCp, expectedFirstResult.validCp), ...
    'AE SweepTool point validCp must equal one maintained public solver call.');
assert(isequaln(firstCondition.reliability, expectedFirstResult.reliability), ...
    'AE SweepTool point reliability must remain the canonical model value.');
assert(isequaln(firstCondition.diagnostics, expectedFirstResult.diagnostics), ...
    'AE SweepTool point diagnostics must remain the canonical model value.');

assert(fallbackInvalidationObserved || officialValidPointObserved, ...
    'AE sweep adapter must either expose valid official points or preserved fallback diagnostics.');

fprintf('Acoustoelastic IOP/HGO GUI sweep adapter smoke test passed.\n');
