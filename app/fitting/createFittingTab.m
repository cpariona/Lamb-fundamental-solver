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
g = uigridlayout(tab, [24 4]);
g.ColumnWidth = {105, '1x', 105, '1x'};
g.RowHeight = {22, 24, 24, 20, 130, 24, 20, 20, 20, '1x', 28, 28, 22, 24, 24, 24, 22, 24, 24, 28, 24, 26, 34, 34};
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

header = uilabel(g, 'Text', 'Model configuration', 'FontWeight', 'bold');
header.Layout.Row = 1;
header.Layout.Column = [1 4];

label = uilabel(g, 'Text', 'Model');
label.Layout.Row = 2;
label.Layout.Column = 1;
h.model = uidropdown(g, 'Items', cellstr(modelLabels), 'Value', char(modelLabels(1)), ...
    'ValueChangedFcn', getCallback(callbacks, 'onFitModelChanged'));
h.model.Layout.Row = 2;
h.model.Layout.Column = 2;

label = uilabel(g, 'Text', 'Branch');
label.Layout.Row = 2;
label.Layout.Column = 3;
h.branch = uidropdown(g, 'Items', cellstr(family.branchNames), 'Value', char(family.defaultBranchName));
h.branch.Layout.Row = 2;
h.branch.Layout.Column = 4;

label = uilabel(g, 'Text', 'Fitted parameter');
label.Layout.Row = 3;
label.Layout.Column = 1;
h.freeParam = uidropdown(g, 'Items', {'mu', 'thickness'}, 'Value', 'mu', ...
    'ValueChangedFcn', getCallback(callbacks, 'onFitParameterChanged'));
h.freeParam.Layout.Row = 3;
h.freeParam.Layout.Column = 2;

label = uilabel(g, 'Text', 'Execution profile');
label.Layout.Row = 3;
label.Layout.Column = 3;
h.robustness = uidropdown(g, 'Items', cellstr(family.robustnessPresets), 'Value', char(family.defaultRobustness));
h.robustness.Layout.Row = 3;
h.robustness.Layout.Column = 4;

parameterNote = uilabel(g, 'Text', ...
    'Physical parameters. Value is used for Fixed rows; Initial/Lower/Upper are used for the Fit row.', ...
    'FontSize', 9, 'WordWrap', 'on');
parameterNote.Layout.Row = 4;
parameterNote.Layout.Column = [1 4];

h.parameterTable = uitable(g, 'Data', table(), ...
    'ColumnName', {'ID', 'Parameter', 'Role', 'Value', 'Unit', 'Initial', 'Lower', 'Upper'}, ...
    'ColumnEditable', [false false false true false true true true]);
h.parameterTable.Layout.Row = 5;
h.parameterTable.Layout.Column = [1 4];

h.a0PolicyLabel = uilabel(g, 'Text', 'A0 branch policy');
h.a0PolicyLabel.Layout.Row = 6;
h.a0PolicyLabel.Layout.Column = [1 2];
h.a0Policy = uidropdown(g, ...
    'Items', {'Physical tail'}, ...
    'ItemsData', {'physicalTail'}, ...
    'Value', 'physicalTail');
h.a0Policy.Layout.Row = 6;
h.a0Policy.Layout.Column = [3 4];
h.a0PolicyLabel.Visible = 'off';
h.a0Policy.Visible = 'off';

dataNote = uilabel(g, 'Text', 'Experimental data', 'FontWeight', 'bold');
dataNote.Layout.Row = 7;
dataNote.Layout.Column = [1 4];

h.dataTable = uitable(g, 'Data', defaultData, ...
    'ColumnName', {'Frequency [Hz]', 'Phase speed [m/s]', 'Use'}, ...
    'ColumnEditable', [true true true], ...
    'CellSelectionCallback', getCallback(callbacks, 'onFitDataCellSelected'), ...
    'CellEditCallback', getCallback(callbacks, 'onFitDataCellEdited'));
h.dataTable.Layout.Row = [8 10];
h.dataTable.Layout.Column = [1 4];

buttonGrid = uigridlayout(g, [1 4]);
buttonGrid.Layout.Row = 11;
buttonGrid.Layout.Column = [1 4];
buttonGrid.ColumnWidth = {'1x', '1x', '1x', '1x'};
buttonGrid.Padding = [0 0 0 0];
buttonGrid.ColumnSpacing = 6;

h.loadButton = uibutton(buttonGrid, 'Text', 'Load experimental data', ...
    'ButtonPushedFcn', getCallback(callbacks, 'onLoadFitData'));
h.populateButton = uibutton(buttonGrid, 'Text', 'Generate synthetic', ...
    'ButtonPushedFcn', getCallback(callbacks, 'onPopulateFitData'));

h.addRowButton = uibutton(buttonGrid, 'Text', 'Add row', ...
    'ButtonPushedFcn', getCallback(callbacks, 'onAddFitDataRow'));
h.deleteRowButton = uibutton(buttonGrid, 'Text', 'Delete selected row', ...
    'ButtonPushedFcn', getCallback(callbacks, 'onDeleteFitDataRows'));

fitButtonGrid = uigridlayout(g, [1 4]);
fitButtonGrid.Layout.Row = 12;
fitButtonGrid.Layout.Column = [1 4];
fitButtonGrid.ColumnWidth = {'1x', '1x', '1x', '1x'};
fitButtonGrid.Padding = [0 0 0 0];
fitButtonGrid.ColumnSpacing = 6;

h.resetButton = uibutton(fitButtonGrid, 'Text', 'Restore defaults', ...
    'ButtonPushedFcn', getCallback(callbacks, 'onResetDefaults'));
h.runButton = uibutton(fitButtonGrid, 'Text', 'Run fit', ...
    'ButtonPushedFcn', getCallback(callbacks, 'onRunFit'));
h.runButton.FontWeight = 'bold';
h.evaluateCurveButton = uibutton(fitButtonGrid, 'Text', 'Evaluate fitted curve', ...
    'ButtonPushedFcn', getCallback(callbacks, 'onEvaluateFittedCurve'));

h.curveHeader = uilabel(g, 'Text', 'Curve evaluation', 'FontWeight', 'bold');
h.curveHeader.Layout.Row = 13;
h.curveHeader.Layout.Column = [1 4];

label = uilabel(g, 'Text', 'Frequency min [kHz]');
label.Layout.Row = 14;
label.Layout.Column = 1;
h.curveMinKHz = uieditfield(g, 'numeric', 'Value', 1);
h.curveMinKHz.Layout.Row = 14;
h.curveMinKHz.Layout.Column = 2;

label = uilabel(g, 'Text', 'Frequency max [kHz]');
label.Layout.Row = 14;
label.Layout.Column = 3;
h.curveMaxKHz = uieditfield(g, 'numeric', 'Value', 8);
h.curveMaxKHz.Layout.Row = 14;
h.curveMaxKHz.Layout.Column = 4;

label = uilabel(g, 'Text', 'Curve points');
label.Layout.Row = 15;
label.Layout.Column = 1;
h.curvePoints = uieditfield(g, 'numeric', 'Value', 200, 'Limits', [2 Inf]);
h.curvePoints.Layout.Row = 15;
h.curvePoints.Layout.Column = 2;

h.axisHeader = uilabel(g, 'Text', 'Axis view (Auto)', 'FontWeight', 'bold');
h.axisHeader.Layout.Row = 16;
h.axisHeader.Layout.Column = [1 4];

label = uilabel(g, 'Text', 'X min [kHz]');
label.Layout.Row = 17;
label.Layout.Column = 1;
h.axisXMinKHz = uieditfield(g, 'text', 'Value', '');
h.axisXMinKHz.Layout.Row = 17;
h.axisXMinKHz.Layout.Column = 2;

label = uilabel(g, 'Text', 'X max [kHz]');
label.Layout.Row = 17;
label.Layout.Column = 3;
h.axisXMaxKHz = uieditfield(g, 'text', 'Value', '');
h.axisXMaxKHz.Layout.Row = 17;
h.axisXMaxKHz.Layout.Column = 4;

label = uilabel(g, 'Text', 'Y min [m/s]');
label.Layout.Row = 18;
label.Layout.Column = 1;
h.axisYMinMps = uieditfield(g, 'text', 'Value', '');
h.axisYMinMps.Layout.Row = 18;
h.axisYMinMps.Layout.Column = 2;

label = uilabel(g, 'Text', 'Y max [m/s]');
label.Layout.Row = 18;
label.Layout.Column = 3;
h.axisYMaxMps = uieditfield(g, 'text', 'Value', '');
h.axisYMaxMps.Layout.Row = 18;
h.axisYMaxMps.Layout.Column = 4;

axisButtonGrid = uigridlayout(g, [1 2]);
axisButtonGrid.Layout.Row = 19;
axisButtonGrid.Layout.Column = [1 4];
axisButtonGrid.ColumnWidth = {'1x', '1x'};
axisButtonGrid.Padding = [0 0 0 0];
axisButtonGrid.ColumnSpacing = 6;
h.applyAxesButton = uibutton(axisButtonGrid, 'Text', 'Apply axes', ...
    'ButtonPushedFcn', getCallback(callbacks, 'onApplyFitAxes'));
h.autoAxesButton = uibutton(axisButtonGrid, 'Text', 'Auto axes', ...
    'ButtonPushedFcn', getCallback(callbacks, 'onAutoFitAxes'));

h.dataSource = uilabel(g, 'Text', 'Data source: editable table', 'FontSize', 10, 'WordWrap', 'on');
h.dataSource.Layout.Row = 20;
h.dataSource.Layout.Column = [1 4];

h.status = uilabel(g, 'Text', 'Fit status: ready.', 'FontSize', 10, 'WordWrap', 'on');
h.status.Layout.Row = 21;
h.status.Layout.Column = [1 4];

h.fixedHeader = uilabel(g, ...
    'Text', 'One parameter is fitted; every other registered physical parameter remains editable.', ...
    'FontSize', 10, 'WordWrap', 'on');
h.fixedHeader.Layout.Row = 22;
h.fixedHeader.Layout.Column = [1 4];

h.note = uilabel(g, ...
    'Text', 'Execution profile, route policy, and optimizer options remain separate from physical parameters.', ...
    'FontSize', 10, 'WordWrap', 'on');
h.note.Layout.Row = [23 24];
h.note.Layout.Column = [1 4];
end

function callback = getCallback(callbacks, fieldName)
callback = @(~,~)[];
if isstruct(callbacks) && isfield(callbacks, fieldName) && ~isempty(callbacks.(fieldName))
    callback = callbacks.(fieldName);
end
end
