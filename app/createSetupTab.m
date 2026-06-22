function h = createSetupTab(tabs, params0, callbacks)
% Build general Setup tab controls shared by all models.

elastic0 = elasticFromMuNu(params0.mu, params0.nu, params0.rho);

tab = uitab(tabs, 'Title', 'Setup');
g = uigridlayout(tab, [15 2]);
g.ColumnWidth = {175, '1x'};
g.RowHeight = repmat({26}, 1, 15);
g.Padding = [12 10 12 10];
g.RowSpacing = 4;

uilabel(g, 'Text', 'Material', 'FontWeight', 'bold');
uilabel(g, 'Text', '');

uilabel(g, 'Text', 'Input model');
h.model = uidropdown(g, 'Items', {'ShearPoisson', 'LameParameters'}, ...
    'Value', char(params0.modelType), 'ValueChangedFcn', callbacks.onMaterialModelChanged);

uilabel(g, 'Text', 'rho [kg/m^3]');
h.rho = uieditfield(g, 'numeric', 'Value', params0.rho, 'Limits', [0 Inf], ...
    'ValueChangedFcn', callbacks.onPrimaryMaterialChanged);

h.mulabel = uilabel(g, 'Text', 'mu [kPa]');
h.mu = uieditfield(g, 'numeric', 'Value', params0.mu/1e3, 'Limits', [0 Inf], ...
    'ValueChangedFcn', callbacks.onPrimaryMaterialChanged);

h.nulabel = uilabel(g, 'Text', 'nu [-]');
h.nu = uieditfield(g, 'numeric', 'Value', params0.nu, 'Limits', [-0.999 0.499999], ...
    'ValueChangedFcn', callbacks.onPrimaryMaterialChanged);

h.lambdalabel = uilabel(g, 'Text', 'lambda_Lame [MPa]');
h.lambda = uieditfield(g, 'numeric', 'Value', elastic0.lambda/1e6, 'Limits', [0 Inf], ...
    'ValueChangedFcn', callbacks.onPrimaryMaterialChanged);

h.Elabel = uilabel(g, 'Text', 'E [kPa]');
h.E = uieditfield(g, 'numeric', 'Value', elastic0.E/1e3, 'Editable', 'off');

h.Klabel = uilabel(g, 'Text', 'K [MPa]');
h.K = uieditfield(g, 'numeric', 'Value', elastic0.K/1e6, 'Editable', 'off');

h.CTlabel = uilabel(g, 'Text', 'CT [m/s]');
h.CT = uieditfield(g, 'numeric', 'Value', elastic0.CT, 'Editable', 'off');

h.CLlabel = uilabel(g, 'Text', 'CL [m/s]');
h.CL = uieditfield(g, 'numeric', 'Value', elastic0.CL, 'Editable', 'off');

uilabel(g, 'Text', 'Geometry / Frequency', 'FontWeight', 'bold');
uilabel(g, 'Text', '');

uilabel(g, 'Text', 'full thickness 2h [mm]');
h.thickness = uieditfield(g, 'numeric', 'Value', params0.thickness*1e3, 'Limits', [0 Inf], ...
    'ValueChangedFcn', callbacks.markDirty);

uilabel(g, 'Text', 'fmin [Hz]');
h.fmin = uieditfield(g, 'numeric', 'Value', params0.fmin, 'Limits', [eps Inf], ...
    'ValueChangedFcn', callbacks.markDirty);

uilabel(g, 'Text', 'fmax [Hz]');
h.fmax = uieditfield(g, 'numeric', 'Value', params0.fmax, 'Limits', [eps Inf], ...
    'ValueChangedFcn', callbacks.markDirty);

note = uilabel(g, 'Text', 'Use mu and nu as the primary soft-material inputs. E, lambda_Lame, K, CT, and CL are derived immediately.', ...
    'WordWrap', 'on', 'FontAngle', 'italic', 'FontSize', 10);
note.Layout.Column = [1 2];
end
