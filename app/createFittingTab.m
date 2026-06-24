function h = createFittingTab(tabs, params0, callbacks)
%CREATEFITTINGTAB Build minimal experimental fitting controls.
%
% The tab prepares GUI inputs for the app-level fitting backend and does not
% implement model-specific fitting algorithms.

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
g = uigridlayout(tab, [13 4]);
g.ColumnWidth = {115, '1x', 115, '1x'};
g.RowHeight = {22, 24, 24, 24, 24, 24, 24, 24, 24, '1x', 28, 26, 26};
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

label = uilabel(g, 'Text', 'Robustness');
label.Layout.Row = 3;
label.Layout.Column = 3;
h.robustness = uidropdown(g, 'Items', cellstr(family.robustnessPresets), 'Value', char(family.defaultRobustness));
h.robustness.Layout.Row = 3;
h.robustness.Layout.Column = 4;

h.initialGuessLabel = uilabel(g, 'Text', 'Initial mu [kPa]');
h.initialGuessLabel.Layout.Row = 4;
h.initialGuessLabel.Layout.Column = 1;
h.initialGuess = uieditfield(g, 'numeric', 'Value', params0.mu / 1e3, 'Limits', [0 Inf]);
h.initialGuess.Layout.Row = 4;
h.initialGuess.Layout.Column = 2;

h.lowerBoundLabel = uilabel(g, 'Text', 'Lower mu [kPa]');
h.lowerBoundLabel.Layout.Row = 4;
h.lowerBoundLabel.Layout.Column = 3;
h.lowerBound = uieditfield(g, 'numeric', 'Value', max(1, 0.20 * params0.mu / 1e3), 'Limits', [0 Inf]);
h.lowerBound.Layout.Row = 4;
h.lowerBound.Layout.Column = 4;

h.upperBoundLabel = uilabel(g, 'Text', 'Upper mu [kPa]');
h.upperBoundLabel.Layout.Row = 5;
h.upperBoundLabel.Layout.Column = 1;
h.upperBound = uieditfield(g, 'numeric', 'Value', 5.0 * params0.mu / 1e3, 'Limits', [0 Inf]);
h.upperBound.Layout.Row = 5;
h.upperBound.Layout.Column = 2;

h.fixedHeader = uilabel(g, 'Text', 'Fixed defaults depend on the selected model.', 'FontSize', 10);
h.fixedHeader.Layout.Row = 5;
h.fixedHeader.Layout.Column = [3 4];

note = uilabel(g, 'Text', 'Data table columns: frequency_Hz | Cp_mps | Use(1/0).', 'FontSize', 10);
note.Layout.Row = 6;
note.Layout.Column = [1 4];

h.dataTable = uitable(g, 'Data', defaultData, ...
    'ColumnName', {'frequency_Hz', 'Cp_mps', 'Use'}, ...
    'ColumnEditable', [true true true]);
h.dataTable.Layout.Row = [7 10];
h.dataTable.Layout.Column = [1 4];

buttonGrid = uigridlayout(g, [1 2]);
buttonGrid.Layout.Row = 11;
buttonGrid.Layout.Column = [1 4];
buttonGrid.ColumnWidth = {'1x', '1x'};
buttonGrid.Padding = [0 0 0 0];
buttonGrid.ColumnSpacing = 6;

h.populateButton = uibutton(buttonGrid, 'Text', 'Generate synthetic from setup', ...
    'ButtonPushedFcn', callbacks.onPopulateFitData);
h.runButton = uibutton(buttonGrid, 'Text', 'Run fit', ...
    'ButtonPushedFcn', callbacks.onRunFit);

h.status = uilabel(g, 'Text', 'Fit status: ready.', 'FontSize', 10, 'WordWrap', 'on');
h.status.Layout.Row = 12;
h.status.Layout.Column = [1 4];

h.note = uilabel(g, 'Text', 'Validated visible fitting: Rayleigh-Lamb mu/thickness, mRLFE mu, AE IOP/HGO atlasA0 mu.', ...
    'FontSize', 10, 'WordWrap', 'on');
h.note.Layout.Row = 13;
h.note.Layout.Column = [1 4];
end
