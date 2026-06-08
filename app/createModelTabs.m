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

tabRL = uitab(tg, 'Title', 'Rayleigh-Lamb');
gRL = uigridlayout(tabRL, [4 1]);
gRL.RowHeight = {22, 24, 24, '1x'};
gRL.Padding = [10 6 10 6];
gRL.RowSpacing = 2;

uilabel(gRL, 'Text', 'Fundamental modes', 'FontWeight', 'bold', 'FontSize', 11);
h.rl.computeA0 = uicheckbox(gRL, 'Text', 'A0', 'Value', opts0.computeA0, 'ValueChangedFcn', callbacks.markDirty);
h.rl.computeS0 = uicheckbox(gRL, 'Text', 'S0 experimental', 'Value', opts0.computeS0, 'ValueChangedFcn', callbacks.markDirty);
uilabel(gRL, 'Text', 'mRLFE forces only the seed branches required by the selected A0-like/S0-like branches.', 'WordWrap', 'on', 'FontAngle', 'italic', 'FontSize', 9);

tabMRLFE = uitab(tg, 'Title', 'mRLFE');
gM = uigridlayout(tabMRLFE, [9 2]);
gM.ColumnWidth = {150, '1x'};
gM.RowHeight = {22, 24, 24, 22, 24, 24, 24, 24, '1x'};
gM.Padding = [10 6 10 6];
gM.RowSpacing = 2;

uilabel(gM, 'Text', 'Fluid-loaded models', 'FontWeight', 'bold', 'FontSize', 11);
uilabel(gM, 'Text', '');

h.mrlfe.computeRealK = uicheckbox(gM, 'Text', 'Elastic real-k', 'Value', false, 'ValueChangedFcn', callbacks.markDirty);
h.mrlfe.computeRealK.Layout.Column = [1 2];

h.mrlfe.computeHanViscoRealK = uicheckbox(gM, 'Text', 'Han visco real-k', 'Value', false, 'ValueChangedFcn', callbacks.markDirty);
h.mrlfe.computeHanViscoRealK.Layout.Column = [1 2];

uilabel(gM, 'Text', 'Branches', 'FontWeight', 'bold', 'FontSize', 11);
uilabel(gM, 'Text', '');

h.mrlfe.computeA0Like = uicheckbox(gM, 'Text', 'A0-like', 'Value', true, 'ValueChangedFcn', callbacks.markDirty);
h.mrlfe.computeA0Like.Layout.Column = [1 2];

h.mrlfe.computeS0Like = uicheckbox(gM, 'Text', 'S0-like', 'Value', true, 'ValueChangedFcn', callbacks.markDirty);
h.mrlfe.computeS0Like.Layout.Column = [1 2];

uilabel(gM, 'Text', 'fluid density [kg/m^3]');
h.mrlfe.fluidDensity = uieditfield(gM, 'numeric', 'Value', 1000, 'Limits', [0 Inf], 'ValueChangedFcn', callbacks.markDirty);

uilabel(gM, 'Text', 'fluid sound speed [m/s]');
h.mrlfe.fluidSoundSpeed = uieditfield(gM, 'numeric', 'Value', 1500, 'Limits', [0 Inf], 'ValueChangedFcn', callbacks.markDirty);

uilabel(gM, 'Text', 'etaS [Pa*s]');
h.mrlfe.etaS = uieditfield(gM, 'numeric', 'Value', 0, 'Limits', [0 Inf], 'ValueChangedFcn', callbacks.markDirty);

note = uilabel(gM, 'Text', 'Selecting one branch can reduce runtime. Han uses the matching elastic branch as reference.', 'WordWrap', 'on', 'FontAngle', 'italic', 'FontSize', 9);
note.Layout.Column = [1 2];

h.mrlfe.computeComplexK = struct('Value', false);
h.mrlfe.etaL = struct('Value', 0);
h.mrlfe.useComplexLambda = struct('Value', false);

h.panel = panel;
h.tabGroup = tg;
end
