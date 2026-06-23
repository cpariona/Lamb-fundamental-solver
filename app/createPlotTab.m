function h = createPlotTab(tabs, callbacks)
% Build Plot tab controls. These fields only refresh visualization.

tab = uitab(tabs, 'Title', 'Plot');
g = uigridlayout(tab, [15 4]);
g.ColumnWidth = {75, '1x', 75, '1x'};
g.RowHeight = {24, 24, 24, 24, 24, 24, 24, 24, 24, 28, 24, 28, 28, 30, '1x'};
g.Padding = [12 10 12 10];
g.RowSpacing = 3;
g.ColumnSpacing = 6;

header = uilabel(g, 'Text', 'Rayleigh-Lamb', 'FontWeight', 'bold', 'VerticalAlignment', 'center');
header.Layout.Row = 1;
header.Layout.Column = [1 4];

h.showA0 = uicheckbox(g, 'Text', 'A0', 'Value', true, 'ValueChangedFcn', callbacks.refreshPlotOnly);
h.showA0.Layout.Row = 2;
h.showA0.Layout.Column = [1 2];

h.showS0 = uicheckbox(g, 'Text', 'S0', 'Value', true, 'ValueChangedFcn', callbacks.refreshPlotOnly);
h.showS0.Layout.Row = 2;
h.showS0.Layout.Column = [3 4];

header = uilabel(g, 'Text', 'mRLFE elastic real-k', 'FontWeight', 'bold', 'VerticalAlignment', 'center');
header.Layout.Row = 3;
header.Layout.Column = [1 4];

h.showMRLFEElasticA0 = uicheckbox(g, 'Text', 'Elastic A0-like', 'Value', true, 'ValueChangedFcn', callbacks.refreshPlotOnly);
h.showMRLFEElasticA0.Layout.Row = 4;
h.showMRLFEElasticA0.Layout.Column = [1 2];

h.showMRLFEElasticS0 = uicheckbox(g, 'Text', 'Elastic S0-like', 'Value', true, 'ValueChangedFcn', callbacks.refreshPlotOnly);
h.showMRLFEElasticS0.Layout.Row = 4;
h.showMRLFEElasticS0.Layout.Column = [3 4];

header = uilabel(g, 'Text', 'mRLFE viscoelastic real-k', 'FontWeight', 'bold', 'VerticalAlignment', 'center');
header.Layout.Row = 5;
header.Layout.Column = [1 4];

h.showMRLFEViscoA0 = uicheckbox(g, 'Text', 'Viscoelastic A0-like', 'Value', true, 'ValueChangedFcn', callbacks.refreshPlotOnly);
h.showMRLFEViscoA0.Layout.Row = 6;
h.showMRLFEViscoA0.Layout.Column = [1 2];

h.showMRLFEViscoS0 = uicheckbox(g, 'Text', 'Viscoelastic S0-like', 'Value', true, 'ValueChangedFcn', callbacks.refreshPlotOnly);
h.showMRLFEViscoS0.Layout.Row = 6;
h.showMRLFEViscoS0.Layout.Column = [3 4];

% Compatibility aliases for older callback code paths.
h.showMRLFEA0 = h.showMRLFEElasticA0;
h.showMRLFES0 = h.showMRLFEElasticS0;
h.showMRLFEHanA0 = h.showMRLFEViscoA0;
h.showMRLFEHanS0 = h.showMRLFEViscoS0;

header = uilabel(g, 'Text', 'Approximations', 'FontWeight', 'bold', 'VerticalAlignment', 'center');
header.Layout.Row = 7;
header.Layout.Column = [1 4];

h.showA0Thin = uicheckbox(g, 'Text', 'A0 thin-plate', 'Value', false, 'ValueChangedFcn', callbacks.refreshPlotOnly);
h.showA0Thin.Layout.Row = 8;
h.showA0Thin.Layout.Column = [1 2];

h.showS0Ext = uicheckbox(g, 'Text', 'S0 extensional', 'Value', false, 'ValueChangedFcn', callbacks.refreshPlotOnly);
h.showS0Ext.Layout.Row = 8;
h.showS0Ext.Layout.Column = [3 4];

header = uilabel(g, 'Text', 'Axes', 'FontWeight', 'bold', 'VerticalAlignment', 'center');
header.Layout.Row = 9;
header.Layout.Column = [1 4];

lbl = uilabel(g, 'Text', 'x-axis', 'VerticalAlignment', 'center');
lbl.Layout.Row = 10;
lbl.Layout.Column = 1;
h.xaxis = uidropdown(g, 'Items', {'frequency', 'angularFrequency', 'wavenumber', 'kThickness'}, ...
    'Value', 'frequency', 'ValueChangedFcn', callbacks.refreshPlotOnly);
h.xaxis.Layout.Row = 10;
h.xaxis.Layout.Column = [2 4];

h.yaxis = struct('Value', 'Cp');

h.autoAxes = uicheckbox(g, 'Text', 'auto axes', 'Value', true, 'ValueChangedFcn', callbacks.onAutoAxesChanged);
h.autoAxes.Layout.Row = 11;
h.autoAxes.Layout.Column = [1 2];

lbl = uilabel(g, 'Text', 'x min', 'VerticalAlignment', 'center');
lbl.Layout.Row = 12;
lbl.Layout.Column = 1;
h.xmin = uieditfield(g, 'numeric', 'Value', 0, 'ValueChangedFcn', callbacks.refreshPlotOnly);
h.xmin.Layout.Row = 12;
h.xmin.Layout.Column = 2;

lbl = uilabel(g, 'Text', 'x max', 'VerticalAlignment', 'center');
lbl.Layout.Row = 12;
lbl.Layout.Column = 3;
h.xmax = uieditfield(g, 'numeric', 'Value', 0, 'ValueChangedFcn', callbacks.refreshPlotOnly);
h.xmax.Layout.Row = 12;
h.xmax.Layout.Column = 4;

lbl = uilabel(g, 'Text', 'y min', 'VerticalAlignment', 'center');
lbl.Layout.Row = 13;
lbl.Layout.Column = 1;
h.ymin = uieditfield(g, 'numeric', 'Value', 0, 'ValueChangedFcn', callbacks.refreshPlotOnly);
h.ymin.Layout.Row = 13;
h.ymin.Layout.Column = 2;

lbl = uilabel(g, 'Text', 'y max', 'VerticalAlignment', 'center');
lbl.Layout.Row = 13;
lbl.Layout.Column = 3;
h.ymax = uieditfield(g, 'numeric', 'Value', 0, 'ValueChangedFcn', callbacks.refreshPlotOnly);
h.ymax.Layout.Row = 13;
h.ymax.Layout.Column = 4;

resetButton = uibutton(g, 'Text', 'Reset axes', 'ButtonPushedFcn', callbacks.resetAxes);
resetButton.Layout.Row = 14;
resetButton.Layout.Column = [1 2];

useButton = uibutton(g, 'Text', 'Use current view', 'ButtonPushedFcn', callbacks.useCurrentAxes);
useButton.Layout.Row = 14;
useButton.Layout.Column = [3 4];

note = uilabel(g, 'Text', 'Main GUI focuses on phase velocity Cp. Complex-k attenuation is kept outside the main workflow.', ...
    'WordWrap', 'on', 'FontAngle', 'italic', 'FontSize', 9, 'VerticalAlignment', 'top');
note.Layout.Row = 15;
note.Layout.Column = [1 4];
end
