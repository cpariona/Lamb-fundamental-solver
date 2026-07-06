function test_sweep_plot_renderer_contract()
%TEST_SWEEP_PLOT_RENDERER_CONTRACT Validate shared sweep plot adaptation/rendering.

oldVisibility = get(groot, 'DefaultFigureVisible');
cleanup = onCleanup(@()set(groot, 'DefaultFigureVisible', oldVisibility)); %#ok<NASGU>
set(groot, 'DefaultFigureVisible', 'off');

frequency = [1000; 2000; 3000];

%% Neutral renderer
plotData = struct();
plotData.titleText = "Synthetic sweep";
plotData.fixedParameterLines = ["mu = 50 kPa"; "2h = 0.5 mm"];
plotData.curves = [ ...
    makeCurve(frequency, [4; 5; 6], [true; true; true], "p = 1"); ...
    makeCurve(frequency, [5; 6; 7], [true; false; true], "p = 2")];

fig = plotSweepCpFigure(plotData);
assert(isgraphics(fig, 'figure'), 'Shared renderer did not return a figure.');
ax = findDataAxes(fig);
infoAx = findInfoPanel(fig);
assert(numel(findobj(ax, 'Type', 'line')) == 2, ...
    'Shared renderer should create one primary line per curve.');
assert(~hasPanelText(ax, "Fixed parameters"), ...
    'Fixed-parameter text should not be attached to the data axes.');
assert(hasPanelText(infoAx, "Fixed parameters"), ...
    'Inset panel is missing the fixed-parameter heading.');
assert(hasPanelText(infoAx, "mu = 50 kPa"), ...
    'Inset panel is missing fixed-parameter text.');
assert(hasPanelText(infoAx, "p = 1"), ...
    'Inset panel is missing sweep labels.');
assertPanelInsideLowerRight(ax, infoAx);
xl = xlim(ax);
yl = ylim(ax);
assert(xl(1) == 0, 'Frequency axis should start at zero by default.');
assert(yl(1) == 0, 'Cp axis should start at zero by default.');
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
assert(~any(contains(rlData.fixedParameterLines, "2h =")), ...
    'RL adapter should not list the swept thickness as fixed.');
assert(string(rlData.curves(1).legendLabel) == "2h = 0.4 mm", ...
    'RL adapter should use the compact 2h sweep label.');
fig = plotParametricSweepCp(rlSweep, "RayleighLamb", "A0", ...
    'FrequencyScale', 1e3, 'FrequencyUnit', "kHz", ...
    'StartFrequencyAtZero', true);
assert(hasPanelText(findInfoPanel(fig), "2h = 0.4 mm"), ...
    'RL wrapper should put compact sweep labels in the inset panel.');
assert(hasPanelText(findInfoPanel(fig), "mu = 75.0 kPa"), ...
    'RL wrapper did not use the shared inset fixed-parameter panel.');
close(fig);

%% mRLFE adapter excludes moving parameters
mrlfeSweep = rlSweep;
mrlfeSweep.parameter = "etaS";
mrlfeSweep.spec = struct('label', "etaS", 'units', "Pa*s");
mrlfeSweep.displayValues = [0, 0.1];
mrlfeSweep.params = { ...
    struct('mu', 75e3, 'nu', 0.4999, 'thickness', 0.5e-3, 'rho', 1070), ...
    struct('mu', 75e3, 'nu', 0.4999, 'thickness', 0.5e-3, 'rho', 1070)};
mrlfeSweep.options = { ...
    struct('mrlfeParams', struct('etaS', 0)), ...
    struct('mrlfeParams', struct('etaS', 0.1))};
mrlfeSweep.results = {makeMrlfeResult(frequency, [4; 5; 6]), makeMrlfeResult(frequency, [5; 6; 7])};

mrlfeData = buildParametricSweepPlotData(mrlfeSweep, "mRLFEViscoRealK", "A0Like");
assert(any(contains(mrlfeData.fixedParameterLines, "mu = 75.0 kPa")), ...
    'mRLFE adapter is missing fixed mu metadata.');
assert(~any(contains(mrlfeData.fixedParameterLines, "etaS =")), ...
    'mRLFE adapter should not list the swept etaS as fixed.');
assert(string(mrlfeData.curves(2).legendLabel) == "etaS = 0.1 Pa*s", ...
    'mRLFE adapter should use a compact etaS sweep label.');

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
assert(~any(contains(aeData.fixedParameterLines, "h =")), ...
    'AE adapter should not list the swept thickness as fixed.');
assert(string(aeData.curves(1).legendLabel) == "h = 400 um", ...
    'AE adapter should use the compact h sweep label.');
fig = aePlotSweepCp(aeSweep);
assert(hasPanelText(findInfoPanel(fig), "IOP = 15.0 mmHg"), ...
    'AE wrapper did not use the shared inset fixed-parameter panel.');
assert(hasPanelText(findInfoPanel(fig), "h = 400 um"), ...
    'AE wrapper did not use compact sweep labels.');
close(fig);

%% AE unitless k2 formatting
aeSweep.sweepField = "k1";
aeData = aeBuildSweepPlotData(aeSweep);
k2Line = aeData.fixedParameterLines(contains(aeData.fixedParameterLines, "k2 ="));
assert(numel(k2Line) == 1 && string(k2Line) == "k2 = 200", ...
    'Unitless k2 should be formatted without a fake unit.');

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

function result = makeMrlfeResult(frequency, Cp)
branch = struct('frequency', frequency, 'Cp', Cp, 'validCp', true(size(Cp)));
result = struct('models', struct('mRLFEViscoRealK', struct('branches', struct('A0Like', branch))));
end

function condition = makeAeCondition(frequency, Cp, displayValue)
result = struct('frequency', frequency, 'Cp', Cp, ...
    'validCp', true(size(Cp)));
condition = struct('result', result, 'sweepValueDisplay', string(displayValue));
end

function ax = findDataAxes(fig)
axesObjects = findobj(fig, 'Type', 'axes');
ax = axesObjects(arrayfun(@(h)~strcmp(string(h.Tag), "SweepInfoPanel"), axesObjects));
assert(numel(ax) == 1, 'Expected exactly one main data axes.');
end

function ax = findInfoPanel(fig)
ax = findobj(fig, 'Type', 'axes', 'Tag', 'SweepInfoPanel');
assert(numel(ax) == 1, 'Expected exactly one sweep information panel axes.');
end

function assertPanelInsideLowerRight(ax, infoAx)
axPos = ax.Position;
panelPos = infoAx.Position;
assert(panelPos(1) >= axPos(1) + 0.50 * axPos(3), ...
    'Information panel should be in the right half of the data axes.');
assert(panelPos(2) < axPos(2) + 0.35 * axPos(4), ...
    'Information panel should be in the lower portion of the data axes.');
assert(panelPos(1) + panelPos(3) <= axPos(1) + axPos(3), ...
    'Information panel should stay inside the data axes horizontally.');
assert(panelPos(2) + panelPos(4) <= axPos(2) + axPos(4), ...
    'Information panel should stay inside the data axes vertically.');
end

function tf = hasPanelText(ax, expectedText)
textObjects = findobj(ax, 'Type', 'text');
tf = false;
for i = 1:numel(textObjects)
    value = string(textObjects(i).String);
    if any(contains(value, expectedText))
        tf = true;
        return;
    end
end
end