function h = createSetupTab(tabs, params0, callbacks)
% Build general Setup tab controls shared by all models.

tab = uitab(tabs, 'Title', 'Setup');
g = uigridlayout(tab, [13 2]);
g.ColumnWidth = {175, '1x'};
g.RowHeight = repmat({26}, 1, 13);
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

note = uilabel(g, 'Text', 'Auto hybrid frequency grid. Model-specific controls are below.', ...
    'WordWrap', 'on', 'FontAngle', 'italic', 'FontSize', 10);
note.Layout.Column = [1 2];
end
