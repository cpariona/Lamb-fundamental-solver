function h = createModelTabs(parent, opts0, callbacks)
% Build model-specific controls below the general Setup/Plot/Advanced tabs.

panel = uipanel(parent, 'Title', 'Model-specific settings');
tg = uitabgroup(panel);
tg.Position = [5 5 panel.Position(3)-10 panel.Position(4)-25];
panel.SizeChangedFcn = @(src,~)resizeTabGroup(src, tg);

% Rayleigh-Lamb tab
tabRL = uitab(tg, 'Title', 'Rayleigh-Lamb');
gRL = uigridlayout(tabRL, [5 1]);
gRL.RowHeight = {26, 28, 28, '1x', 42};
gRL.Padding = [12 10 12 10];
gRL.RowSpacing = 4;

uilabel(gRL, 'Text', 'Fundamental modes to compute', 'FontWeight', 'bold');
h.rl.computeA0 = uicheckbox(gRL, 'Text', 'A0', 'Value', opts0.computeA0, ...
    'ValueChangedFcn', callbacks.markDirty);
h.rl.computeS0 = uicheckbox(gRL, 'Text', 'S0 experimental', 'Value', opts0.computeS0, ...
    'ValueChangedFcn', callbacks.markDirty);
uilabel(gRL, 'Text', '');
uilabel(gRL, 'Text', 'mRLFE uses these Rayleigh-Lamb branches as seeds when enabled.', ...
    'WordWrap', 'on', 'FontAngle', 'italic');

% mRLFE tab
tabMRLFE = uitab(tg, 'Title', 'mRLFE');
gM = uigridlayout(tabMRLFE, [7 2]);
gM.ColumnWidth = {175, '1x'};
gM.RowHeight = {26, 28, 28, 28, 28, '1x', 42};
gM.Padding = [12 10 12 10];
gM.RowSpacing = 4;

uilabel(gM, 'Text', 'Fluid-loaded prototype', 'FontWeight', 'bold');
uilabel(gM, 'Text', '');

h.mrlfe.compute = uicheckbox(gM, 'Text', 'compute mRLFE real-k prototype', 'Value', false, ...
    'ValueChangedFcn', callbacks.markDirty);
h.mrlfe.compute.Layout.Column = [1 2];

uilabel(gM, 'Text', 'fluid density [kg/m^3]');
h.mrlfe.fluidDensity = uieditfield(gM, 'numeric', 'Value', 1000, 'Limits', [0 Inf], ...
    'ValueChangedFcn', callbacks.markDirty);

uilabel(gM, 'Text', 'fluid sound speed [m/s]');
h.mrlfe.fluidSoundSpeed = uieditfield(gM, 'numeric', 'Value', 1500, 'Limits', [0 Inf], ...
    'ValueChangedFcn', callbacks.markDirty);

uilabel(gM, 'Text', '');
uilabel(gM, 'Text', '');

note = uilabel(gM, 'Text', 'Current mRLFE implementation is an elastic real-k prototype. It computes A0-like/S0-like branches only.', ...
    'WordWrap', 'on', 'FontAngle', 'italic');
note.Layout.Column = [1 2];

h.panel = panel;
h.tabGroup = tg;
end

function resizeTabGroup(panel, tg)
pos = panel.Position;
tg.Position = [5 5 max(pos(3)-10, 50) max(pos(4)-25, 50)];
end
