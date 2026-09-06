function test_gui_sweep_adapters_smoke()
%TEST_GUI_SWEEP_ADAPTERS_SMOKE Smoke test for GUI sweep adapter dispatch.

fprintf('Running GUI sweep adapters smoke test...\n');
testMRLFEAdapter();
testRLAdapter();
fprintf('GUI sweep adapters smoke test passed.\n');
end

function testMRLFEAdapter()
params = lamb.models.rayleigh_lamb.rlDefaultParams();
params.fmin = 100;
params.fmax = 300;
params.numFrequencyPoints = 10;
params.frequencySpacing = "linspace";

controls = struct();
controls.robustness = "Fast";
controls.etaS = 0.05;
controls.fluidDensity = 1000;
controls.fluidSoundSpeed = 1500;

request = guiBuildSweepRequest("mrlfe", ...
    'modelLabel', "mRLFE real-k", ...
    'branchName', "A0Like", ...
    'sweepField', "mu", ...
    'sweepLabel', "mu", ...
    'sweepValuesDisplay', [60 75], ...
    'displayUnit', "kPa", ...
    'displayScale', 1e3, ...
    'baseParams', params, ...
    'controls', controls, ...
    'outputMode', "workspace", ...
    'outputTaskName', "test_mrlfe_sweep");

sweepOutput = guiRunSweep(request);
assert(isstruct(sweepOutput), 'GUI sweep adapter must return a struct.');
assert(isfield(sweepOutput, 'sweepResult'));
assert(isfield(sweepOutput, 'summaryTable'));
assert(isfield(sweepOutput, 'normalized'));
assert(string(sweepOutput.modelFamily) == "mrlfe");
assert(string(sweepOutput.modelName) == "mRLFERealK");
assert(string(sweepOutput.branchName) == "A0Like");
assert(isequal(sweepOutput.sweepSpec.values, [60 75] * 1e3));
assert(numel(sweepOutput.sweepResult.results) == 2);
assert(height(sweepOutput.summaryTable) == 2);
assert(numel(sweepOutput.normalized.curves) == 2);
assertNormalizedCurves(sweepOutput.normalized.curves);
end

function testRLAdapter()
params = lamb.models.rayleigh_lamb.rlDefaultParams();
params.fmin = 100;
params.fmax = 300;
params.numFrequencyPoints = 10;
params.frequencySpacing = "linspace";

controls = struct('robustness', "Fast");
request = guiBuildSweepRequest("rayleigh_lamb", ...
    'modelLabel', "Rayleigh-Lamb", ...
    'branchName', "A0", ...
    'sweepField', "thickness", ...
    'sweepLabel', "thickness", ...
    'sweepValuesDisplay', [0.3 0.4], ...
    'displayUnit', "mm", ...
    'displayScale', 1e-3, ...
    'baseParams', params, ...
    'controls', controls, ...
    'outputMode', "workspace", ...
    'outputTaskName', "test_rl_sweep");

sweepOutput = guiRunSweep(request);
assert(isstruct(sweepOutput), 'RL GUI sweep adapter must return a struct.');
assert(isfield(sweepOutput, 'sweepResult'));
assert(isfield(sweepOutput, 'summaryTable'));
assert(isfield(sweepOutput, 'normalized'));
assert(string(sweepOutput.modelFamily) == "rayleigh_lamb");
assert(string(sweepOutput.modelName) == "RayleighLamb");
assert(string(sweepOutput.branchName) == "A0");
assert(isequal(sweepOutput.sweepSpec.values, [0.3 0.4] * 1e-3));
assert(string(sweepOutput.sweepSpec.units) == "mm");
assert(numel(sweepOutput.sweepResult.results) == 2);
assert(height(sweepOutput.summaryTable) == 2);
assert(numel(sweepOutput.normalized.curves) == 2);
assertNormalizedCurves(sweepOutput.normalized.curves);
end

function assertNormalizedCurves(curves)
for i = 1:numel(curves)
    curve = curves(i);
    assert(isfield(curve, 'frequency_Hz') && ~isempty(curve.frequency_Hz));
    assert(isfield(curve, 'Cp_mps') && ~isempty(curve.Cp_mps));
    assert(isfield(curve, 'validMask') && ~isempty(curve.validMask));
    assert(isequal(size(curve.frequency_Hz), size(curve.Cp_mps)));
    assert(isequal(size(curve.Cp_mps), size(curve.validMask)));
    assert(any(isfinite(curve.Cp_mps(:))));
end
end
