function h = createModelTabs(parent, opts0, callbacks)
% Build model-specific controls below the general Setup/Plot/Advanced tabs.

panel = uipanel(parent, 'Title', 'Model-specific settings');
panelGrid = uigridlayout(panel, [1 1]);
panelGrid.Padding = [3 3 3 3];
panelGrid.RowSpacing = 0;
panelGrid.ColumnSpacing = 0;

tg = uitabgroup(panelGrid);
tg.Layout.Row = 1;
tg.Layout.Column = 1;

% Rayleigh-Lamb tab
tabRL = uitab(tg, 'Title', 'Rayleigh-Lamb');
gRL = uigridlayout(tabRL, [4 1]);
gRL.RowHeight = {24, 26, 26, '1x'};
gRL.Padding = [10 8 10 8];
gRL.RowSpacing = 3;

uilabel(gRL, 'Text', 'Fundamental modes to compute', 'FontWeight', 'bold', 'FontSize', 11);
h.rl.computeA0 = uicheckbox(gRL, 'Text', 'A0', 'Value', opts0.computeA0, ...
    'ValueChangedFcn', callbacks.markDirty);
h.rl.computeS0 = uicheckbox(gRL, 'Text', 'S0 experimental', 'Value', opts0.computeS0, ...
    'ValueChangedFcn', callbacks.markDirty);
uilabel(gRL, 'Text', 'mRLFE uses these Rayleigh-Lamb branches as seeds.', ...
    'WordWrap', 'on', 'FontAngle', 'italic', 'FontSize', 10);

% mRLFE tab
tabMRLFE = uitab(tg, 'Title', 'mRLFE');
gM = uigridlayout(tabMRLFE, [8 2]);
gM.ColumnWidth = {165, '1x'};
gM.RowHeight = {24, 24, 24, 26, 26, 26, 26, '1x'};
gM.Padding = [10 8 10 8];
gM.RowSpacing = 3;

uilabel(gM, 'Text', 'Fluid-loaded model', 'FontWeight', 'bold', 'FontSize', 11);
uilabel(gM, 'Text', '');

h.mrlfe.computeRealK = uicheckbox(gM, 'Text', 'compute real-k prototype', 'Value', false, ...
    'ValueChangedFcn', callbacks.markDirty);
h.mrlfe.computeRealK.Layout.Column = [1 2];

h.mrlfe.computeComplexK = uicheckbox(gM, 'Text', 'compute complex-k prototype', 'Value', false, ...
    'ValueChangedFcn', callbacks.markDirty);
h.mrlfe.computeComplexK.Layout.Column = [1 2];

uilabel(gM, 'Text', 'fluid density [kg/m^3]');
h.mrlfe.fluidDensity = uieditfield(gM, 'numeric', 'Value', 1000, 'Limits', [0 Inf], ...
    'ValueChangedFcn', callbacks.markDirty);

uilabel(gM, 'Text', 'fluid sound speed [m/s]');
h.mrlfe.fluidSoundSpeed = uieditfield(gM, 'numeric', 'Value', 1500, 'Limits', [0 Inf], ...
    'ValueChangedFcn', callbacks.markDirty);

uilabel(gM, 'Text', 'etaL [Pa*s]');
h.mrlfe.etaL = uieditfield(gM, 'numeric', 'Value', 0, 'Limits', [0 Inf], ...
    'ValueChangedFcn', callbacks.markDirty);

uilabel(gM, 'Text', 'etaS [Pa*s]');
h.mrlfe.etaS = uieditfield(gM, 'numeric', 'Value', 0, 'Limits', [0 Inf], ...
    'ValueChangedFcn', callbacks.markDirty);

note = uilabel(gM, 'Text', 'Complex-k is a first prototype. It reports Cp from real(k) and attenuation from imag(k).', ...
    'WordWrap', 'on', 'FontAngle', 'italic', 'FontSize', 10);
note.Layout.Column = [1 2];

h.panel = panel;
h.tabGroup = tg;
end
