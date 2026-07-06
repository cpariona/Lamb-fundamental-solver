function test_sweep_plot_renderer_contract()
%TEST_SWEEP_PLOT_RENDERER_CONTRACT Validate shared sweep plot adaptation/rendering.

oldVisibility = get(groot, 'DefaultFigureVisible');
cleanup = onCleanup(@()set(groot, 'DefaultFigureVisible', oldVisibility)); %#ok<NASGU>
set(groot, 'DefaultFigureVisible', 'off');

frequency = [1000; 2000; 3000];

%% Neutral renderer
plotData = struct();
plotData.titleText = "Synthetic sweep";
plotData.fixedParameterLines = ["mu = 50 kPa"; "Thickness = 0.5 mm"];
plotData.curves = [ ...
    makeCurve(frequency, [4; 5; 6], [true; true; true], "p = 1"); ...
    makeCurve(frequency, [5; 6; 7], [true; false; true], "p = 2")];

fig = plotSweepCpFigure(plotData);
assert(isgraphics(fig, 'figure'), 'Shared renderer did not return a figure.');
ax = findobj(fig, 'Type', 'axes');
assert(~isempty(ax), 'Shared renderer did not create axes.');
assert(numel(findobj(ax, 'Type', 'line')) == 2, ...
    'Shared renderer should create one primary line per curve.');
assert(hasFixedParameterBlock(ax), ...
    'Shared renderer did not create the fixed-parameter block.');
assert(xlim(ax(1))(1) == 0, 'Frequency axis should start at zero by default.');
assert(ylim(ax(1))(1) == 0, 'Cp axis should start at zero by default.');
close(fig);

%% Rayleigh-Lamb adapter and wrapper
rlSweep = struct();
rlSweep.spec = struct('label', "Full thickness 2h", 'units', "mm");
rlSweep.parameter = "thickness";
rlSweep.displayValues = [0.4, 0.6];
rlSweep.params = { ...
    struct('mu', 75e3, 'nu', 0.4999, 'thickness', 0.4e-3, 'rho', 1070), ...
    struct('mu', 75e3, 'nu', 0.4999, 'thickness', 0.6e-3, 'rho', 1070)};
rlSweep.options = {struct(), struct()};
rlSweep.results = {makeRlResult(frequency, [4; 5; 6]), makeRlResult(frequency, [5; 6; 7])};

rlData = buildParametricSweepPlotData(rlSweep, "RayleighLamb", "A0");
assert(numel(rlData.curves) == 2, 'RL adapter returned the wrong curve count.');
assert(any(contains(rlData.fixedParameterLines, "mu = 75.0 kPa")), ...
    'RL adapter is missing fixed mu metadata.');
assert(~any(contains(rlData.fixedParameterLines, "Full thickness")), ...
    'RL adapter should not list the swept thickness as fixed.');
fig = plotParametricSweepCp(rlSweep, "RayleighLamb", "A0", ...
    'FrequencyScale', 1e3, 'FrequencyUnit', "kHz", ...
    'StartFrequencyAtZero', true);
assert(hasFixedParameterBlock(findobj(fig, 'Type', 'axes')), ...
    'RL wrapper did not use the shared fixed-parameter block.');
close(fig);

%% AE adapter and wrapper
aeSweep = struct();
aeSweep.label = "Thickness";
aeSweep.sweepField = "thickness";
aeSweep.baseParams = struct('IOP', 15 * 133.322, 'R', 7.8e-3, ...
    'thickness', 550e-6, 'mu', 64e3, 'k1', 50e3, 'k2', 200);
aeSweep.conditions = [ ...
    makeAeCondition(frequency, [4; 5; 6], "400 um"); ...
    makeAeCondition(frequency, [5; 6; 7], "700 um")];

aeData = aeBuildSweepPlotData(aeSweep);
assert(numel(aeData.curves) == 2, 'AE adapter returned the wrong curve count.');
assert(any(contains(aeData.fixedParameterLines, "IOP = 15.0 mmHg")), ...
    'AE adapter is missing fixed IOP metadata.');
assert(~any(contains(aeData.fixedParameterLines, "Thickness =")), ...
    'AE adapter should not list the swept thickness as fixed.');
fig = aePlotSweepCp(aeSweep);
assert(hasFixedParameterBlock(findobj(fig, 'Type', 'axes')), ...
    'AE wrapper did not use the shared fixed-parameter block.');
close(fig);

fprintf('Shared sweep plot renderer contract test passed.\n');
end

function curve = makeCurve(frequency, Cp, valid, label)
curve = struct('frequency_Hz', frequency, 'Cp_mps', Cp, ...
    'valid', valid, 'legendLabel', string(label));
end

function result = makeRlResult(frequency, Cp)
branch = struct('frequency', frequency, 'Cp', Cp, 'validCp', true(size(Cp)));
result = struct('modes', struct('A0', branch));
end

function condition = makeAeCondition(frequency, Cp, displayValue)
result = struct('frequency', frequency, 'Cp', Cp, ...
    'validCp', true(size(Cp)));
condition = struct('result', result, 'sweepValueDisplay', string(displayValue));
end

function tf = hasFixedParameterBlock(ax)
if numel(ax) > 1
    ax = ax(1);
end
textObjects = findobj(ax, 'Type', 'text');
tf = false;
for i = 1:numel(textObjects)
    value = string(textObjects(i).String);
    if any(contains(value, "Fixed parameters"))
        tf = true;
        return;
    end
end
end