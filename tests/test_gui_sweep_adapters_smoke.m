%TEST_GUI_SWEEP_ADAPTERS_SMOKE Smoke test for GUI sweep adapter dispatch.
%
% This test validates the non-interactive SweepTool path:
% guiBuildSweepRequest -> guiRunSweep -> model adapter -> normalized curves.

fprintf('Running GUI sweep adapters smoke test...\n');

testMRLFEAdapter();
testRLAdapter();

fprintf('GUI sweep adapters smoke test passed.\n');

function testMRLFEAdapter()
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
    'displayUnit', "kPa", ...
    'displayScale', 1e3, ...
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

assertNormalizedCurves(sweepOutput.normalized.curves);
end

function testRLAdapter()
params = rlDefaultParams();
params.fmin = 100;
params.fmax = 300;
params.numFrequencyPoints = 8;
params.frequencySpacing = "linspace";

controls = struct();
controls.robustness = "Fast";

request = guiBuildSweepRequest("rayleigh_lamb", ...
    'modelLabel', "Rayleigh-Lamb", ...
    'branchName', "A0", ...
    'sweepField', "thickness", ...
    'sweepLabel', "thickness", ...
    'sweepValuesDisplay', [0.1 0.2], ...
    'displayUnit', "mm", ...
    'displayScale', 1e-3, ...
    'baseParams', params, ...
    'controls', controls, ...
    'outputMode', "workspace", ...
    'outputTaskName', "test_rl_sweep");

sweepOutput = guiRunSweep(request);

assert(isstruct(sweepOutput), 'RL GUI sweep adapter must return a struct.');
assert(isfield(sweepOutput, 'rawResults'), 'RL GUI sweep output must include rawResults.');
assert(isfield(sweepOutput, 'summaryTable'), 'RL GUI sweep output must include summaryTable.');
assert(isfield(sweepOutput, 'normalized'), 'RL GUI sweep output must include normalized output.');
assert(string(sweepOutput.modelFamily) == "rayleigh_lamb", 'RL GUI sweep output modelFamily must be rayleigh_lamb.');
assert(string(sweepOutput.modelName) == "RayleighLamb", 'RL sweep must use RayleighLamb modelName.');
assert(string(sweepOutput.branchName) == "A0", 'RL sweep branch must be A0.');

assert(isequal(sweepOutput.sweepSpec.values, [0.1 0.2] * 1e-3), ...
    'RL displayScale must propagate to solver-unit sweep values.');
assert(string(sweepOutput.sweepSpec.units) == "mm", ...
    'RL displayUnit must propagate to sweepSpec units.');
assert(numel(sweepOutput.rawResults.results) == 2, 'RL GUI sweep must run one result per sweep value.');
assert(height(sweepOutput.summaryTable) == 2, 'RL GUI sweep summary must have one row per sweep value.');
assert(numel(sweepOutput.normalized.curves) == 2, 'RL normalized sweep must have one curve per sweep value.');

assertNormalizedCurves(sweepOutput.normalized.curves);
end

function assertNormalizedCurves(curves)
for i = 1:numel(curves)
    curve = curves(i);
    assert(isfield(curve, 'frequency_Hz') && ~isempty(curve.frequency_Hz), 'Normalized curve must include frequency_Hz.');
    assert(isfield(curve, 'Cp_mps') && ~isempty(curve.Cp_mps), 'Normalized curve must include Cp_mps.');
    assert(isfield(curve, 'validMask') && ~isempty(curve.validMask), 'Normalized curve must include validMask.');
    assert(isequal(size(curve.frequency_Hz), size(curve.Cp_mps)), 'Normalized frequency and Cp vectors must match.');
    assert(isequal(size(curve.Cp_mps), size(curve.validMask)), 'Normalized Cp and validity vectors must match.');
    assert(any(isfinite(curve.Cp_mps(:))), 'Normalized curve must contain finite Cp values.');
end
end
