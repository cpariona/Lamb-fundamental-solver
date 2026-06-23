function h = createPlotTab(tabs, callbacks)
% Build Plot tab controls. These fields only refresh visualization.

tab = uitab(tabs, 'Title', 'Plot');
g = uigridlayout(tab, [13 4]);
g.ColumnWidth = {75, '1x', 75, '1x'};
g.RowHeight = {24, 24, 24, 24, 24, 24, 24, 28, 24, 28, 28, 30, '1x'};
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

header = uilabel(g, 'Text', 'mRLFE real-k', 'FontWeight', 'bold', 'VerticalAlignment', 'center');
header.Layout.Row = 3;
header.Layout.Column = [1 4];

h.showMRLFEA0 = uicheckbox(g, 'Text', 'mRLFE A0-like', 'Value', true, 'ValueChangedFcn', callbacks.refreshPlotOnly);
h.showMRLFEA0.Layout.Row = 4;
h.showMRLFEA0.Layout.Column = [1 2];

h.showMRLFES0 = uicheckbox(g, 'Text', 'mRLFE S0-like', 'Value', true, 'ValueChangedFcn', callbacks.refreshPlotOnly);
h.showMRLFES0.Layout.Row = 4;
h.showMRLFES0.Layout.Column = [3 4];

% Compatibility aliases for older callback code paths.
h.showMRLFEElasticA0 = h.showMRLFEA0;
h.showMRLFEElasticS0 = h.showMRLFES0;
h.showMRLFEViscoA0 = h.showMRLFEA0;
h.showMRLFEViscoS0 = h.showMRLFES0;

header = uilabel(g, 'Text', 'Approximations', 'FontWeight', 'bold', 'VerticalAlignment', 'center');
header.Layout.Row = 5;
header.Layout.Column = [1 4];

h.showA0Thin = uicheckbox(g, 'Text', 'A0 thin-plate', 'Value', false, 'ValueChangedFcn', callbacks.refreshPlotOnly);
h.showA0Thin.Layout.Row = 6;
h.showA0Thin.Layout.Column = [1 2];

h.showS0Ext = uicheckbox(g, 'Text', 'S0 extensional', 'Value', false, 'ValueChangedFcn', callbacks.refreshPlotOnly);
h.showS0Ext.Layout.Row = 6;
h.showS0Ext.Layout.Column = [3 4];

header = uilabel(g, 'Text', 'Axes', 'FontWeight', 'bold', 'VerticalAlignment', 'center');
header.Layout.Row = 7;
header.Layout.Column = [1 4];

lbl = uilabel(g, 'Text', 'x-axis', 'VerticalAlignment', 'center');
lbl.Layout.Row = 8;
lbl.Layout.Column = 1;
h.xaxis = uidropdown(g, 'Items', {'frequency', 'angularFrequency', 'wavenumber', 'kThickness'}, ...
    'Value', 'frequency', 'ValueChangedFcn', callbacks.refreshPlotOnly);
h.xaxis.Layout.Row = 8;
h.xaxis.Layout.Column = [2 4];

h.yaxis = struct('Value', 'Cp');

h.autoAxes = uicheckbox(g, 'Text', 'auto axes', 'Value', true, 'ValueChangedFcn', callbacks.onAutoAxesChanged);
h.autoAxes.Layout.Row = 9;
h.autoAxes.Layout.Column = [1 2];

lbl = uilabel(g, 'Text', 'x min', 'VerticalAlignment', 'center');
lbl.Layout.Row = 10;
lbl.Layout.Column = 1;
h.xmin = uieditfield(g, 'numeric', 'Value', 0, 'ValueChangedFcn', callbacks.refreshPlotOnly);
h.xmin.Layout.Row = 10;
h.xmin.Layout.Column = 2;

lbl = uilabel(g, 'Text', 'x max', 'VerticalAlignment', 'center');
lbl.Layout.Row = 10;
lbl.Layout.Column = 3;
h.xmax = uieditfield(g, 'numeric', 'Value', 0, 'ValueChangedFcn', callbacks.refreshPlotOnly);
h.xmax.Layout.Row = 10;
h.xmax.Layout.Column = 4;

lbl = uilabel(g, 'Text', 'y min', 'VerticalAlignment', 'center');
lbl.Layout.Row = 11;
lbl.Layout.Column = 1;
h.ymin = uieditfield(g, 'numeric', 'Value', 0, 'ValueChangedFcn', callbacks.refreshPlotOnly);
h.ymin.Layout.Row = 11;
h.ymin.Layout.Column = 2;

lbl = uilabel(g, 'Text', 'y max', 'VerticalAlignment', 'center');
lbl.Layout.Row = 11;
lbl.Layout.Column = 3;
h.ymax = uieditfield(g, 'numeric', 'Value', 0, 'ValueChangedFcn', callbacks.refreshPlotOnly);
h.ymax.Layout.Row = 11;
h.ymax.Layout.Column = 4;

resetButton = uibutton(g, 'Text', 'Reset axes', 'ButtonPushedFcn', callbacks.resetAxes);
resetButton.Layout.Row = 12;
resetButton.Layout.Column = [1 2];

useButton = uibutton(g, 'Text', 'Use current view', 'ButtonPushedFcn', callbacks.useCurrentAxes);
useButton.Layout.Row = 12;
useButton.Layout.Column = [3 4];

note = uilabel(g, 'Text', 'mRLFE real-k uses etaS = 0 as the elastic limit and etaS > 0 as the viscous case.', ...
    'WordWrap', 'on', 'FontAngle', 'italic', 'FontSize', 9, 'VerticalAlignment', 'top');
note.Layout.Row = 13;
note.Layout.Column = [1 4];
end
