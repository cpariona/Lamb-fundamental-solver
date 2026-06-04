function h = createPlotTab(tabs, callbacks)
% Build Plot tab controls. These fields only refresh visualization.

tab = uitab(tabs, 'Title', 'Plot');
g = uigridlayout(tab, [13 2]);
g.ColumnWidth = {160, '1x'};
g.RowHeight = [repmat({30}, 1, 12), {70}];
g.Padding = [12 12 12 12];
g.RowSpacing = 6;

uilabel(g, 'Text', 'Modes to display', 'FontWeight', 'bold');
uilabel(g, 'Text', '');

h.showA0 = uicheckbox(g, 'Text', 'Show A0', 'Value', true, 'ValueChangedFcn', callbacks.refreshPlotOnly);
h.showA0.Layout.Column = [1 2];

h.showS0 = uicheckbox(g, 'Text', 'Show S0 experimental', 'Value', true, 'ValueChangedFcn', callbacks.refreshPlotOnly);
h.showS0.Layout.Column = [1 2];

uilabel(g, 'Text', 'Axes', 'FontWeight', 'bold');
uilabel(g, 'Text', '');

uilabel(g, 'Text', 'x-axis');
h.xaxis = uidropdown(g, 'Items', {'frequency', 'angularFrequency', 'wavenumber', 'kThickness'}, 'Value', 'frequency', 'ValueChangedFcn', callbacks.refreshPlotOnly);

uilabel(g, 'Text', 'y-axis');
uilabel(g, 'Text', 'Cp');

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

note = uilabel(g, 'Text', 'Note: when x-axis is wavenumber or kThickness, each mode can end at a different x-value because k = omega/Cp is mode-dependent. This does not mean the branch was truncated in frequency.', 'WordWrap', 'on', 'FontAngle', 'italic');
note.Layout.Column = [1 2];
end
