function h = createAdvancedTab(tabs, callbacks)
% Build Advanced tab controls.

tab = uitab(tabs, 'Title', 'Advanced');
g = uigridlayout(tab, [6 2]);
g.ColumnWidth = {160, '1x'};
g.RowHeight = {30, 30, 70, 30, 70, '1x'};
g.Padding = [12 12 12 12];

uilabel(g, 'Text', 'Numerical solver', 'FontWeight', 'bold');
uilabel(g, 'Text', '');

uilabel(g, 'Text', 'execution profile');
h.robustness = uidropdown(g, 'Items', {'Fast', 'Balanced', 'Robust'}, 'Value', 'Balanced', 'ValueChangedFcn', callbacks.markDirty);

uilabel(g, 'Text', 'preset effect');
uilabel(g, 'Text', 'Model-specific cost/robustness profile. Metadata reports the effective internal preset.', 'WordWrap', 'on');

uilabel(g, 'Text', 'settings');
uilabel(g, 'Text', 'Route policy, atlas branch selection, and optimizer options remain configured separately.', 'WordWrap', 'on', 'FontAngle', 'italic');
end
