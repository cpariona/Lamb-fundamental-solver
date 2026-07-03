function h = createFittingTab(tabs, params0, callbacks)
%CREATEFITTINGTAB Build experimental fitting controls.

registry = guiGetFitRegistry();
families = registry.modelFamilies;
modelLabels = strings(1, numel(families));
for i = 1:numel(families)
    modelLabels(i) = string(families(i).label);
end
family = families(1);

CpExample = sqrt(params0.mu / params0.rho);
defaultData = [1000, CpExample, 1; 3000, CpExample, 1; 5000, CpExample, 1; 7000, CpExample, 1];

tab = uitab(tabs, 'Title', 'Fitting');
g = uigridlayout(tab, [15 4]);
g.ColumnWidth = {105, '1x', 105, '1x'};
g.RowHeight = {22, 24, 24, 20, 155, 24, 20, 20, 20, '1x', 28, 24, 26, 34, 34};
g.Padding = [10 8 10 8];
g.RowSpacing = 3;
g.ColumnSpacing = 8;

h = struct();
h.registry = registry;
h.modelLabels = modelLabels;
h.modelFamilyIds = strings(1, numel(families));
for i = 1:numel(families)
    h.modelFamilyIds(i) = families(i).id;
end

header = uilabel(g, 'Text', 'Experimental fitting', 'FontWeight', 'bold');
header.Layout.Row = 1;
header.Layout.Column = [1 4];

label = uilabel(g, 'Text', 'Model');
label.Layout.Row = 2;
label.Layout.Column = 1;
h.model = uidropdown(g, 'Items', cellstr(modelLabels), 'Value', char(modelLabels(1)), ...
    'ValueChangedFcn', callbacks.onFitModelChanged);
h.model.Layout.Row = 2;
h.model.Layout.Column = 2;

label = uilabel(g, 'Text', 'Branch');
label.Layout.Row = 2;
label.Layout.Column = 3;
h.branch = uidropdown(g, 'Items', cellstr(family.branchNames), 'Value', char(family.defaultBranchName));
h.branch.Layout.Row = 2;
h.branch.Layout.Column = 4;

label = uilabel(g, 'Text', 'Free parameter');
label.Layout.Row = 3;
label.Layout.Column = 1;
h.freeParam = uidropdown(g, 'Items', {'mu', 'thickness'}, 'Value', 'mu', ...
    'ValueChangedFcn', callbacks.onFitParameterChanged);
h.freeParam.Layout.Row = 3;
h.freeParam.Layout.Column = 2;

label = uilabel(g, 'Text', 'Execution profile');
label.Layout.Row = 3;
label.Layout.Column = 3;
h.robustness = uidropdown(g, 'Items', cellstr(family.robustnessPresets), 'Value', char(family.defaultRobustness));
h.robustness.Layout.Row = 3;
h.robustness.Layout.Column = 4;

parameterNote = uilabel(g, 'Text', ...
    'All physical parameters are shown. Value is used for Fixed rows; Initial/Lower/Upper are used for the Fit row.', ...
    'FontSize', 9, 'WordWrap', 'on');
parameterNote.Layout.Row = 4;
parameterNote.Layout.Column = [1 4];

h.parameterTable = uitable(g, 'Data', table(), ...
    'ColumnName', {'ID', 'Parameter', 'Role', 'Value', 'Unit', 'Initial', 'Lower', 'Upper'}, ...
    'ColumnEditable', [false false false true false true true true]);
h.parameterTable.Layout.Row = 5;
h.parameterTable.Layout.Column = [1 4];

h.a0PolicyLabel = uilabel(g, 'Text', 'mRLFE A0 atlas policy');
h.a0PolicyLabel.Layout.Row = 6;
h.a0PolicyLabel.Layout.Column = [1 2];
h.a0Policy = uidropdown(g, 'Items', {'adaptivePhysicalTail', 'delayedCut'}, 'Value', 'adaptivePhysicalTail');
h.a0Policy.Layout.Row = 6;
h.a0Policy.Layout.Column = [3 4];
h.a0PolicyLabel.Visible = 'off';
h.a0Policy.Visible = 'off';

dataNote = uilabel(g, 'Text', 'Data table columns: frequency_Hz | Cp_mps | Use(1/0).', 'FontSize', 10);
dataNote.Layout.Row = 7;
dataNote.Layout.Column = [1 4];

h.dataTable = uitable(g, 'Data', defaultData, ...
    'ColumnName', {'frequency_Hz', 'Cp_mps', 'Use'}, ...
    'ColumnEditable', [true true true]);
h.dataTable.Layout.Row = [8 10];
h.dataTable.Layout.Column = [1 4];

buttonGrid = uigridlayout(g, [1 4]);
buttonGrid.Layout.Row = 11;
buttonGrid.Layout.Column = [1 4];
buttonGrid.ColumnWidth = {'1x', '1x', '1x', '1x'};
buttonGrid.Padding = [0 0 0 0];
buttonGrid.ColumnSpacing = 6;

h.loadButton = uibutton(buttonGrid, 'Text', 'Load experimental data', ...
    'ButtonPushedFcn', callbacks.onLoadFitData);
h.populateButton = uibutton(buttonGrid, 'Text', 'Generate synthetic', ...
    'ButtonPushedFcn', callbacks.onPopulateFitData);
h.resetButton = uibutton(buttonGrid, 'Text', 'Restore defaults', ...
    'ButtonPushedFcn', callbacks.onResetDefaults);
h.runButton = uibutton(buttonGrid, 'Text', 'Run fit', ...
    'ButtonPushedFcn', callbacks.onRunFit);

h.dataSource = uilabel(g, 'Text', 'Data source: editable table', 'FontSize', 10, 'WordWrap', 'on');
h.dataSource.Layout.Row = 12;
h.dataSource.Layout.Column = [1 4];

h.status = uilabel(g, 'Text', 'Fit status: ready.', 'FontSize', 10, 'WordWrap', 'on');
h.status.Layout.Row = 13;
h.status.Layout.Column = [1 4];

h.fixedHeader = uilabel(g, ...
    'Text', 'One parameter is fitted; every other registered physical parameter remains editable.', ...
    'FontSize', 10, 'WordWrap', 'on');
h.fixedHeader.Layout.Row = 14;
h.fixedHeader.Layout.Column = [1 4];

h.note = uilabel(g, ...
    'Text', 'Execution profile, route policy, and optimizer options remain separate from physical parameters.', ...
    'FontSize', 10, 'WordWrap', 'on');
h.note.Layout.Row = 15;
h.note.Layout.Column = [1 4];
end
