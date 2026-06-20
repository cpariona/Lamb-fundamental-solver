%TEST_GUI_SWEEP_REGISTRY_SMOKE Smoke test for declarative GUI sweep registry.
%
% This validates that SweepTool metadata is available without instantiating the
% interactive GUI and that the registry feeds the request/adapter pipeline.

fprintf('Running GUI sweep registry smoke test...\n');

registry = guiGetSweepRegistry();
assert(isstruct(registry), 'Sweep registry must be a struct.');
assert(isfield(registry, 'defaultModelFamily'), 'Sweep registry must define defaultModelFamily.');
assert(isfield(registry, 'modelFamilies') && ~isempty(registry.modelFamilies), ...
    'Sweep registry must define at least one model family.');

family = guiGetSweepFamilyConfig(registry, "mrlfe");
assert(string(family.id) == "mrlfe", 'mRLFE family id must be mrlfe.');
assert(ismember("Viscoelastic real-k", family.modelLabels), 'mRLFE registry must expose Viscoelastic real-k.');
assert(ismember("Elastic real-k", family.modelLabels), 'mRLFE registry must expose Elastic real-k.');
assert(ismember("A0Like", family.branchNames), 'mRLFE registry must expose A0Like.');
assert(ismember("S0Like", family.branchNames), 'mRLFE registry must expose S0Like.');

etaS = guiGetSweepParameterConfig(family, "etaS");
E = guiGetSweepParameterConfig(family, "E");
thickness = guiGetSweepParameterConfig(family, "thickness");

assert(isequal(etaS.defaultValuesDisplay, [0, 0.01, 0.05, 0.10, 0.20, 0.30, 0.50]), ...
    'etaS defaults changed unexpectedly.');
assert(etaS.displayScale == 1, 'etaS displayScale must be 1.');
assert(string(etaS.displayUnit) == "Pa*s", 'etaS display unit must be Pa*s.');

assert(isequal(E.defaultValuesDisplay, [50, 100, 300, 500, 1000, 1500]), ...
    'E defaults changed unexpectedly.');
assert(E.displayScale == 1e3, 'E displayScale must convert kPa to Pa.');
assert(string(E.displayUnit) == "kPa", 'E display unit must be kPa.');

assert(isequal(thickness.defaultValuesDisplay, [0.3, 0.5, 0.7, 1.0]), ...
    'thickness defaults changed unexpectedly.');
assert(thickness.displayScale == 1e-3, 'thickness displayScale must convert mm to m.');
assert(string(thickness.displayUnit) == "mm", 'thickness display unit must be mm.');

assert(strcmp(guiFormatSweepValues([50, 100, 300]), '50, 100, 300'), ...
    'guiFormatSweepValues must return comma-separated numeric text.');

params = rlDefaultParams();
params.fmin = 100;
params.fmax = 300;
params.numFrequencyPoints = 8;
params.frequencySpacing = "linspace";

controls = struct();
controls.robustness = family.defaultRobustness;
controls.etaS = 0.05;
controls.fluidDensity = 1000;
controls.fluidSoundSpeed = 1500;

request = guiBuildSweepRequest(family.id, ...
    'modelLabel', "Elastic real-k", ...
    'branchName', family.defaultBranchName, ...
    'sweepField', E.id, ...
    'sweepLabel', E.label, ...
    'sweepValuesDisplay', [50 100], ...
    'displayUnit', E.displayUnit, ...
    'displayScale', E.displayScale, ...
    'baseParams', params, ...
    'controls', controls, ...
    'outputMode', "workspace", ...
    'outputTaskName', family.outputTaskName);

sweepOutput = guiRunSweep(request);
assert(isequal(sweepOutput.sweepSpec.values, [50 100] * 1e3), ...
    'Registry displayScale must propagate to solver-unit sweep values.');
assert(string(sweepOutput.sweepSpec.units) == "kPa", ...
    'Registry displayUnit must propagate to sweepSpec units.');
assert(numel(sweepOutput.normalized.curves) == 2, ...
    'Registry-backed GUI sweep must produce one curve per requested value.');

fprintf('GUI sweep registry smoke test passed.\n');
