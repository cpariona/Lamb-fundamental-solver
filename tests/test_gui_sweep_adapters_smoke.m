%TEST_GUI_SWEEP_ADAPTERS_SMOKE Smoke test for GUI sweep adapter dispatch.
%
% This test validates the non-interactive SweepTool path:
% guiBuildSweepRequest -> guiRunSweep -> guiRunMRLFESweep -> normalized curves.

fprintf('Running GUI sweep adapters smoke test...\n');

params = rlDefaultParams();
params.fmin = 100;
params.fmax = 300;
params.numFrequencyPoints = 8;
params.frequencySpacing = "linspace";

controls = struct();
controls.robustness = "Fast";
controls.etaS = 0.05;
controls.fluidDensity = 1000;
controls.fluidSoundSpeed = 1500;

request = guiBuildSweepRequest("mrlfe", ...
    'modelLabel', "Elastic real-k", ...
    'branchName', "A0Like", ...
    'sweepField', "E", ...
    'sweepLabel', "E", ...
    'sweepValuesDisplay', [50 100], ...
    'baseParams', params, ...
    'controls', controls, ...
    'outputMode', "workspace", ...
    'outputTaskName', "test_mrlfe_sweep");

sweepOutput = guiRunSweep(request);

assert(isstruct(sweepOutput), 'GUI sweep adapter must return a struct.');
assert(isfield(sweepOutput, 'rawResults'), 'GUI sweep output must include rawResults.');
assert(isfield(sweepOutput, 'summaryTable'), 'GUI sweep output must include summaryTable.');
assert(isfield(sweepOutput, 'normalized'), 'GUI sweep output must include normalized output.');
assert(string(sweepOutput.modelFamily) == "mrlfe", 'GUI sweep output modelFamily must be mrlfe.');
assert(string(sweepOutput.modelName) == "mRLFEElasticRealK", 'Elastic mRLFE sweep must use mRLFEElasticRealK.');
assert(string(sweepOutput.branchName) == "A0Like", 'Sweep branch must be A0Like.');

assert(numel(sweepOutput.rawResults.results) == 2, 'GUI sweep must run one result per sweep value.');
assert(height(sweepOutput.summaryTable) == 2, 'GUI sweep summary must have one row per sweep value.');
assert(numel(sweepOutput.normalized.curves) == 2, 'Normalized sweep must have one curve per sweep value.');

for i = 1:numel(sweepOutput.normalized.curves)
    curve = sweepOutput.normalized.curves(i);
    assert(isfield(curve, 'frequency_Hz') && ~isempty(curve.frequency_Hz), 'Normalized curve must include frequency_Hz.');
    assert(isfield(curve, 'Cp_mps') && ~isempty(curve.Cp_mps), 'Normalized curve must include Cp_mps.');
    assert(isfield(curve, 'validMask') && ~isempty(curve.validMask), 'Normalized curve must include validMask.');
    assert(isequal(size(curve.frequency_Hz), size(curve.Cp_mps)), 'Normalized frequency and Cp vectors must match.');
    assert(isequal(size(curve.Cp_mps), size(curve.validMask)), 'Normalized Cp and validity vectors must match.');
    assert(any(isfinite(curve.Cp_mps(:))), 'Normalized curve must contain finite Cp values.');
end

fprintf('GUI sweep adapters smoke test passed.\n');
