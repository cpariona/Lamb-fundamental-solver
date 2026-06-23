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
h.rl.computeS0 = uicheckbox(gRL, 'Text', 'S0', 'Value', opts0.computeS0, 'ValueChangedFcn', callbacks.markDirty);
uilabel(gRL, 'Text', 'mRLFE forces only the seed branches required by the selected A0-like/S0-like branches.', 'WordWrap', 'on', 'FontAngle', 'italic', 'FontSize', 9);

tabMRLFE = uitab(tg, 'Title', 'mRLFE');
gM = uigridlayout(tabMRLFE, [8 4]);
gM.ColumnWidth = {105, '1x', 105, '1x'};
gM.RowHeight = {22, 24, 22, 24, 24, 24, 24, '1x'};
gM.Padding = [10 6 10 6];
gM.RowSpacing = 2;
gM.ColumnSpacing = 6;

label = uilabel(gM, 'Text', 'Fluid-loaded models', 'FontWeight', 'bold', 'FontSize', 11);
label.Layout.Row = 1;
label.Layout.Column = [1 4];

h.mrlfe.computeRealK = uicheckbox(gM, 'Text', 'Elastic real-k', 'Value', false, 'ValueChangedFcn', callbacks.markDirty);
h.mrlfe.computeRealK.Layout.Row = 2;
h.mrlfe.computeRealK.Layout.Column = [1 2];

h.mrlfe.computeViscoRealK = uicheckbox(gM, 'Text', 'Viscoelastic real-k', 'Value', false, 'ValueChangedFcn', @onViscoChanged);
h.mrlfe.computeViscoRealK.Layout.Row = 2;
h.mrlfe.computeViscoRealK.Layout.Column = [3 4];

% Temporary compatibility alias for older callbacks/tests.
h.mrlfe.computeHanViscoRealK = h.mrlfe.computeViscoRealK;

label = uilabel(gM, 'Text', 'Branches', 'FontWeight', 'bold', 'FontSize', 11);
label.Layout.Row = 3;
label.Layout.Column = [1 4];

h.mrlfe.computeA0Like = uicheckbox(gM, 'Text', 'A0-like', 'Value', true, 'ValueChangedFcn', callbacks.markDirty);
h.mrlfe.computeA0Like.Layout.Row = 4;
h.mrlfe.computeA0Like.Layout.Column = [1 2];

h.mrlfe.computeS0Like = uicheckbox(gM, 'Text', 'S0-like', 'Value', true, 'ValueChangedFcn', callbacks.markDirty);
h.mrlfe.computeS0Like.Layout.Row = 4;
h.mrlfe.computeS0Like.Layout.Column = [3 4];

label = uilabel(gM, 'Text', 'fluid density [kg/m^3]');
label.Layout.Row = 5;
label.Layout.Column = [1 2];
h.mrlfe.fluidDensity = uieditfield(gM, 'numeric', 'Value', 1000, 'Limits', [0 Inf], 'ValueChangedFcn', callbacks.markDirty);
h.mrlfe.fluidDensity.Layout.Row = 5;
h.mrlfe.fluidDensity.Layout.Column = [3 4];

label = uilabel(gM, 'Text', 'fluid sound speed [m/s]');
label.Layout.Row = 6;
label.Layout.Column = [1 2];
h.mrlfe.fluidSoundSpeed = uieditfield(gM, 'numeric', 'Value', 1500, 'Limits', [0 Inf], 'ValueChangedFcn', callbacks.markDirty);
h.mrlfe.fluidSoundSpeed.Layout.Row = 6;
h.mrlfe.fluidSoundSpeed.Layout.Column = [3 4];

label = uilabel(gM, 'Text', 'etaS [Pa*s]');
label.Layout.Row = 7;
label.Layout.Column = [1 2];
h.mrlfe.etaS = uieditfield(gM, 'numeric', 'Value', 0, 'Limits', [0 Inf], 'ValueChangedFcn', callbacks.markDirty);
h.mrlfe.etaS.Layout.Row = 7;
h.mrlfe.etaS.Layout.Column = [3 4];

note = uilabel(gM, 'Text', 'Selecting viscoelastic real-k automatically keeps elastic real-k available because it is the reference branch.', 'WordWrap', 'on', 'FontAngle', 'italic', 'FontSize', 9);
note.Layout.Row = 8;
note.Layout.Column = [1 4];

h.mrlfe.computeComplexK = struct('Value', false);
h.mrlfe.etaL = struct('Value', 0);
h.mrlfe.useComplexLambda = struct('Value', false);

tabAE = uitab(tg, 'Title', 'AE IOP/HGO');
gAE = uigridlayout(tabAE, [7 4]);
gAE.ColumnWidth = {115, '1x', 115, '1x'};
gAE.RowHeight = {22, 24, 24, 24, 24, 24, '1x'};
gAE.Padding = [10 6 10 6];
gAE.RowSpacing = 2;
gAE.ColumnSpacing = 6;

label = uilabel(gAE, 'Text', 'Acoustoelastic A0-like setup', 'FontWeight', 'bold', 'FontSize', 11);
label.Layout.Row = 1;
label.Layout.Column = [1 4];

h.ae.computeAtlasA0 = uicheckbox(gAE, 'Text', 'Compute AE A0-like', 'Value', false, 'ValueChangedFcn', callbacks.markDirty);
h.ae.computeAtlasA0.Layout.Row = 2;
h.ae.computeAtlasA0.Layout.Column = [1 4];

label = uilabel(gAE, 'Text', 'IOP [mmHg]');
label.Layout.Row = 3;
label.Layout.Column = 1;
h.ae.IOP = uieditfield(gAE, 'numeric', 'Value', 15, 'Limits', [0 Inf], 'ValueChangedFcn', callbacks.markDirty);
h.ae.IOP.Layout.Row = 3;
h.ae.IOP.Layout.Column = 2;

label = uilabel(gAE, 'Text', 'R [mm]');
label.Layout.Row = 3;
label.Layout.Column = 3;
h.ae.R = uieditfield(gAE, 'numeric', 'Value', 7.8, 'Limits', [0 Inf], 'ValueChangedFcn', callbacks.markDirty);
h.ae.R.Layout.Row = 3;
h.ae.R.Layout.Column = 4;

label = uilabel(gAE, 'Text', 'k1 [kPa]');
label.Layout.Row = 4;
label.Layout.Column = 1;
h.ae.k1 = uieditfield(gAE, 'numeric', 'Value', 25, 'Limits', [0 Inf], 'ValueChangedFcn', callbacks.markDirty);
h.ae.k1.Layout.Row = 4;
h.ae.k1.Layout.Column = 2;

label = uilabel(gAE, 'Text', 'k2 [-]');
label.Layout.Row = 4;
label.Layout.Column = 3;
h.ae.k2 = uieditfield(gAE, 'numeric', 'Value', 100, 'Limits', [0 Inf], 'ValueChangedFcn', callbacks.markDirty);
h.ae.k2.Layout.Row = 4;
h.ae.k2.Layout.Column = 4;

label = uilabel(gAE, 'Text', 'rhoF [kg/m^3]');
label.Layout.Row = 5;
label.Layout.Column = [1 2];
h.ae.rhoF = uieditfield(gAE, 'numeric', 'Value', 1000, 'Limits', [0 Inf], 'ValueChangedFcn', callbacks.markDirty);
h.ae.rhoF.Layout.Row = 5;
h.ae.rhoF.Layout.Column = [3 4];

label = uilabel(gAE, 'Text', 'fluid bulk [GPa]');
label.Layout.Row = 6;
label.Layout.Column = [1 2];
h.ae.fluidBulkModulus = uieditfield(gAE, 'numeric', 'Value', 2.2, 'Limits', [0 Inf], 'ValueChangedFcn', callbacks.markDirty);
h.ae.fluidBulkModulus.Layout.Row = 6;
h.ae.fluidBulkModulus.Layout.Column = [3 4];

note = uilabel(gAE, 'Text', 'Shared fields come from Setup: rho, mu, thickness, fmin, and fmax. Internal atlas settings are derived from the Advanced robustness preset.', 'WordWrap', 'on', 'FontAngle', 'italic', 'FontSize', 9);
note.Layout.Row = 7;
note.Layout.Column = [1 4];

h.panel = panel;
h.tabGroup = tg;

    function onViscoChanged(~, ~)
        if h.mrlfe.computeViscoRealK.Value
            h.mrlfe.computeRealK.Value = true;
        end
        callbacks.markDirty();
    end
end
