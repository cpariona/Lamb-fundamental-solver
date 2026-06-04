function h = createAdvancedTab(tabs, callbacks)
% Build Advanced tab controls.

tab = uitab(tabs, 'Title', 'Advanced');
g = uigridlayout(tab, [6 2]);
g.ColumnWidth = {160, '1x'};
g.RowHeight = {30, 30, 70, 30, 70, '1x'};
g.Padding = [12 12 12 12];

uilabel(g, 'Text', 'Numerical solver', 'FontWeight', 'bold');
uilabel(g, 'Text', '');

uilabel(g, 'Text', 'robustness');
h.robustness = uidropdown(g, 'Items', {'Fast', 'Balanced', 'Robust'}, 'Value', 'Balanced', 'ValueChangedFcn', callbacks.markDirty);

uilabel(g, 'Text', 'preset effect');
uilabel(g, 'Text', 'Fast uses fewer scan points. Robust uses more points and wider search windows.', 'WordWrap', 'on');

uilabel(g, 'Text', 'settings');
uilabel(g, 'Text', 'Detailed numerical tuning is currently configured in defaultOptions.m.', 'WordWrap', 'on', 'FontAngle', 'italic');
end
