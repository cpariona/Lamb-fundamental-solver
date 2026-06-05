function h = createPlotTab(tabs, callbacks)
% Build Plot tab controls. These fields only refresh visualization.

tab = uitab(tabs, 'Title', 'Plot');
g = uigridlayout(tab, [18 2]);
g.ColumnWidth = {160, '1x'};
g.RowHeight = [repmat({30}, 1, 17), {70}];
g.Padding = [12 12 12 12];
g.RowSpacing = 6;

uilabel(g, 'Text', 'Modes to display', 'FontWeight', 'bold');
uilabel(g, 'Text', '');

h.showA0 = uicheckbox(g, 'Text', 'Show A0', 'Value', true, 'ValueChangedFcn', callbacks.refreshPlotOnly);
h.showA0.Layout.Column = [1 2];

h.showS0 = uicheckbox(g, 'Text', 'Show S0 experimental', 'Value', true, 'ValueChangedFcn', callbacks.refreshPlotOnly);
h.showS0.Layout.Column = [1 2];

uilabel(g, 'Text', 'mRLFE dispersion', 'FontWeight', 'bold');
uilabel(g, 'Text', '');

h.showMRLFEA0 = uicheckbox(g, 'Text', 'Show mRLFE A0-like', 'Value', true, 'ValueChangedFcn', callbacks.refreshPlotOnly);
h.showMRLFEA0.Layout.Column = [1 2];

h.showMRLFES0 = uicheckbox(g, 'Text', 'Show mRLFE S0-like', 'Value', true, 'ValueChangedFcn', callbacks.refreshPlotOnly);
h.showMRLFES0.Layout.Column = [1 2];

uilabel(g, 'Text', 'Approximations', 'FontWeight', 'bold');
uilabel(g, 'Text', '');

h.showA0Thin = uicheckbox(g, 'Text', 'Show A0 thin-plate', 'Value', false, 'ValueChangedFcn', callbacks.refreshPlotOnly);
h.showA0Thin.Layout.Column = [1 2];

h.showS0Ext = uicheckbox(g, 'Text', 'Show S0 extensional', 'Value', false, 'ValueChangedFcn', callbacks.refreshPlotOnly);
h.showS0Ext.Layout.Column = [1 2];

uilabel(g, 'Text', 'Axes', 'FontWeight', 'bold');
uilabel(g, 'Text', '');

uilabel(g, 'Text', 'x-axis');
h.xaxis = uidropdown(g, 'Items', {'frequency', 'angularFrequency', 'wavenumber', 'kThickness'}, ...
    'Value', 'frequency', 'ValueChangedFcn', callbacks.refreshPlotOnly);

h.yaxis = struct('Value', 'Cp');

h.autoAxes = uicheckbox(g, 'Text', 'auto axes', 'Value', true, 'ValueChangedFcn', callbacks.onAutoAxesChanged);
h.autoAxes.Layout.Column = [1 2];

uilabel(g, 'Text', 'x min');
h.xmin = uieditfield(g, 'numeric', 'Value', 0, 'ValueChangedFcn', callbacks.refreshPlotOnly);

uilabel(g, 'Text', 'x max');
h.xmax = uieditfield(g, 'numeric', 'Value', 0, 'ValueChangedFcn', callbacks.refreshPlotOnly);

uilabel(g, 'Text', 'y min');
h.ymin = uieditfield(g, 'numeric', 'Value', 0, 'ValueChangedFcn', callbacks.refreshPlotOnly);

uilabel(g, 'Text', 'y max');
h.ymax = uieditfield(g, 'numeric', 'Value', 0, 'ValueChangedFcn', callbacks.refreshPlotOnly);

resetButton = uibutton(g, 'Text', 'Reset axes to computed range', 'ButtonPushedFcn', callbacks.resetAxes);
resetButton.Layout.Column = [1 2];

useButton = uibutton(g, 'Text', 'Use current view as manual axes', 'ButtonPushedFcn', callbacks.useCurrentAxes);
useButton.Layout.Column = [1 2];

note = uilabel(g, 'Text', ['Main GUI focuses on phase-velocity dispersion Cp. ', ...
    'Spatial attenuation Im(k) is kept as an experimental advanced path outside the main workflow.'], ...
    'WordWrap', 'on', 'FontAngle', 'italic', 'FontSize', 10);
note.Layout.Column = [1 2];
end
