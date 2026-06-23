function h = createSetupTab(tabs, params0, callbacks)
% Build general Setup tab controls shared by all models.

elastic0 = elasticFromMuNu(params0.mu, params0.nu, params0.rho);

tab = uitab(tabs, 'Title', 'Setup');
g = uigridlayout(tab, [10 4]);
g.ColumnWidth = {115, '1x', 95, '1x'};
g.RowHeight = {22, 24, 24, 24, 22, 24, 24, 22, 24, '1x'};
g.Padding = [10 8 10 8];
g.RowSpacing = 3;
g.ColumnSpacing = 6;

header = uilabel(g, 'Text', 'Material inputs', 'FontWeight', 'bold');
header.Layout.Row = 1;
header.Layout.Column = [1 4];

label = uilabel(g, 'Text', 'Input model');
label.Layout.Row = 2;
label.Layout.Column = 1;
h.model = uidropdown(g, 'Items', {'ShearPoisson', 'LameParameters'}, ...
    'Value', char(params0.modelType), 'ValueChangedFcn', callbacks.onMaterialModelChanged);
h.model.Layout.Row = 2;
h.model.Layout.Column = [2 4];

label = uilabel(g, 'Text', 'rho [kg/m^3]');
label.Layout.Row = 3;
label.Layout.Column = 1;
h.rho = uieditfield(g, 'numeric', 'Value', params0.rho, 'Limits', [0 Inf], ...
    'ValueChangedFcn', callbacks.onPrimaryMaterialChanged);
h.rho.Layout.Row = 3;
h.rho.Layout.Column = 2;

h.mulabel = uilabel(g, 'Text', 'mu [kPa]');
h.mulabel.Layout.Row = 3;
h.mulabel.Layout.Column = 3;
h.mu = uieditfield(g, 'numeric', 'Value', params0.mu/1e3, 'Limits', [0 Inf], ...
    'ValueChangedFcn', callbacks.onPrimaryMaterialChanged);
h.mu.Layout.Row = 3;
h.mu.Layout.Column = 4;

h.nulabel = uilabel(g, 'Text', 'nu [-]');
h.nulabel.Layout.Row = 4;
h.nulabel.Layout.Column = 1;
h.nu = uieditfield(g, 'numeric', 'Value', params0.nu, 'Limits', [-0.999 0.499999], ...
    'ValueChangedFcn', callbacks.onPrimaryMaterialChanged);
h.nu.Layout.Row = 4;
h.nu.Layout.Column = 2;

h.lambdalabel = uilabel(g, 'Text', 'lambda_Lame [MPa]');
h.lambdalabel.Layout.Row = 4;
h.lambdalabel.Layout.Column = 3;
h.lambda = uieditfield(g, 'numeric', 'Value', elastic0.lambda/1e6, 'Limits', [0 Inf], ...
    'ValueChangedFcn', callbacks.onPrimaryMaterialChanged);
h.lambda.Layout.Row = 4;
h.lambda.Layout.Column = 4;

header = uilabel(g, 'Text', 'Derived elastic values', 'FontWeight', 'bold');
header.Layout.Row = 5;
header.Layout.Column = [1 4];

h.Elabel = uilabel(g, 'Text', 'E [kPa]');
h.Elabel.Layout.Row = 6;
h.Elabel.Layout.Column = 1;
h.E = uieditfield(g, 'numeric', 'Value', elastic0.E/1e3, 'Editable', 'off');
h.E.Layout.Row = 6;
h.E.Layout.Column = 2;

h.Klabel = uilabel(g, 'Text', 'K [MPa]');
h.Klabel.Layout.Row = 6;
h.Klabel.Layout.Column = 3;
h.K = uieditfield(g, 'numeric', 'Value', elastic0.K/1e6, 'Editable', 'off');
h.K.Layout.Row = 6;
h.K.Layout.Column = 4;

h.CTlabel = uilabel(g, 'Text', 'CT [m/s]');
h.CTlabel.Layout.Row = 7;
h.CTlabel.Layout.Column = 1;
h.CT = uieditfield(g, 'numeric', 'Value', elastic0.CT, 'Editable', 'off');
h.CT.Layout.Row = 7;
h.CT.Layout.Column = 2;

h.CLlabel = uilabel(g, 'Text', 'CL [m/s]');
h.CLlabel.Layout.Row = 7;
h.CLlabel.Layout.Column = 3;
h.CL = uieditfield(g, 'numeric', 'Value', elastic0.CL, 'Editable', 'off');
h.CL.Layout.Row = 7;
h.CL.Layout.Column = 4;

header = uilabel(g, 'Text', 'Geometry / Frequency', 'FontWeight', 'bold');
header.Layout.Row = 8;
header.Layout.Column = [1 4];

label = uilabel(g, 'Text', '2h [mm]');
label.Layout.Row = 9;
label.Layout.Column = 1;
h.thickness = uieditfield(g, 'numeric', 'Value', params0.thickness*1e3, 'Limits', [0 Inf], ...
    'ValueChangedFcn', callbacks.markDirty);
h.thickness.Layout.Row = 9;
h.thickness.Layout.Column = 2;

label = uilabel(g, 'Text', 'fmin [Hz]');
label.Layout.Row = 9;
label.Layout.Column = 3;
h.fmin = uieditfield(g, 'numeric', 'Value', params0.fmin, 'Limits', [eps Inf], ...
    'ValueChangedFcn', callbacks.markDirty);
h.fmin.Layout.Row = 9;
h.fmin.Layout.Column = 4;

label = uilabel(g, 'Text', 'fmax [Hz]');
label.Layout.Row = 10;
label.Layout.Column = 1;
h.fmax = uieditfield(g, 'numeric', 'Value', params0.fmax, 'Limits', [eps Inf], ...
    'ValueChangedFcn', callbacks.markDirty);
h.fmax.Layout.Row = 10;
h.fmax.Layout.Column = [2 4];
end
