function h = createSetupTab(tabs, params0, opts0, callbacks)
% Build Setup tab controls. These fields change the numerical solution.

tab = uitab(tabs, 'Title', 'Setup');
g = uigridlayout(tab, [21 2]);
g.ColumnWidth = {175, '1x'};
g.RowHeight = repmat({26}, 1, 21);
g.Padding = [12 10 12 10];
g.RowSpacing = 4;

uilabel(g, 'Text', 'Material', 'FontWeight', 'bold');
uilabel(g, 'Text', '');

uilabel(g, 'Text', 'Input model');
h.model = uidropdown(g, 'Items', {'YoungPoissonFixedCL', 'LameParameters'}, ...
    'Value', char(params0.modelType), 'ValueChangedFcn', callbacks.onMaterialModelChanged);

uilabel(g, 'Text', 'rho [kg/m^3]');
h.rho = uieditfield(g, 'numeric', 'Value', params0.rho, 'Limits', [0 Inf], ...
    'ValueChangedFcn', callbacks.markDirty);

h.Elabel = uilabel(g, 'Text', 'E [kPa]');
h.E = uieditfield(g, 'numeric', 'Value', params0.E/1e3, 'Limits', [0 Inf], ...
    'ValueChangedFcn', callbacks.markDirty);

h.nulabel = uilabel(g, 'Text', 'nu [-]');
h.nu = uieditfield(g, 'numeric', 'Value', params0.nu, 'Limits', [0 0.5], ...
    'ValueChangedFcn', callbacks.markDirty);

h.CLlabel = uilabel(g, 'Text', 'CL [m/s]');
h.CL = uieditfield(g, 'numeric', 'Value', params0.CL, 'Limits', [0 Inf], ...
    'ValueChangedFcn', callbacks.markDirty);

h.lambdalabel = uilabel(g, 'Text', 'lambda [MPa]');
h.lambda = uieditfield(g, 'numeric', 'Value', params0.lambda/1e6, 'Limits', [0 Inf], ...
    'ValueChangedFcn', callbacks.markDirty);

h.mulabel = uilabel(g, 'Text', 'mu [kPa]');
h.mu = uieditfield(g, 'numeric', 'Value', params0.mu/1e3, 'Limits', [0 Inf], ...
    'ValueChangedFcn', callbacks.markDirty);

uilabel(g, 'Text', 'Geometry / Frequency', 'FontWeight', 'bold');
uilabel(g, 'Text', '');

uilabel(g, 'Text', 'thickness [mm]');
h.thickness = uieditfield(g, 'numeric', 'Value', params0.thickness*1e3, 'Limits', [0 Inf], ...
    'ValueChangedFcn', callbacks.markDirty);

uilabel(g, 'Text', 'fmin [Hz]');
h.fmin = uieditfield(g, 'numeric', 'Value', params0.fmin, 'Limits', [eps Inf], ...
    'ValueChangedFcn', callbacks.markDirty);

uilabel(g, 'Text', 'fmax [Hz]');
h.fmax = uieditfield(g, 'numeric', 'Value', params0.fmax, 'Limits', [eps Inf], ...
    'ValueChangedFcn', callbacks.markDirty);

spacingNote = uilabel(g, 'Text', 'Frequency grid: automatic internal hybrid spacing.', ...
    'WordWrap', 'on', 'FontAngle', 'italic');
spacingNote.Layout.Column = [1 2];

uilabel(g, 'Text', 'mRLFE fluid loading', 'FontWeight', 'bold');
uilabel(g, 'Text', '');

uilabel(g, 'Text', 'fluid density [kg/m^3]');
h.mrlfeFluidDensity = uieditfield(g, 'numeric', 'Value', 1000, 'Limits', [0 Inf], ...
    'ValueChangedFcn', callbacks.markDirty);

uilabel(g, 'Text', 'fluid sound speed [m/s]');
h.mrlfeFluidSoundSpeed = uieditfield(g, 'numeric', 'Value', 1500, 'Limits', [0 Inf], ...
    'ValueChangedFcn', callbacks.markDirty);

uilabel(g, 'Text', 'Modes / models to compute', 'FontWeight', 'bold');
uilabel(g, 'Text', '');

h.computeA0 = uicheckbox(g, 'Text', 'A0', 'Value', opts0.computeA0, ...
    'ValueChangedFcn', callbacks.markDirty);
h.computeA0.Layout.Column = [1 2];

h.computeS0 = uicheckbox(g, 'Text', 'S0 experimental', 'Value', opts0.computeS0, ...
    'ValueChangedFcn', callbacks.markDirty);
h.computeS0.Layout.Column = [1 2];

h.computeMRLFE = uicheckbox(g, 'Text', 'mRLFE real-k prototype', 'Value', false, ...
    'ValueChangedFcn', callbacks.markDirty);
h.computeMRLFE.Layout.Column = [1 2];

note = uilabel(g, 'Text', 'Changes in this tab require Compute selected modes. mRLFE currently needs A0/S0 seeds and computes A0-like/S0-like branches only.', ...
    'WordWrap', 'on', 'FontAngle', 'italic');
note.Layout.Column = [1 2];
end
