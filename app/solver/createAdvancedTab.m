function h = createAdvancedTab(tabs, callbacks)
%CREATEADVANCEDTAB Build advanced solver controls.

tab = uitab(tabs, 'Title', 'Advanced');
g = uigridlayout(tab, [6 2]);
g.ColumnWidth = {160, '1x'};
g.RowHeight = {30, 30, 70, 30, 70, '1x'};
g.Padding = [12 12 12 12];

uilabel(g, 'Text', 'Numerical solver', 'FontWeight', 'bold');
uilabel(g, 'Text', '');

uilabel(g, 'Text', 'Execution profile');
h.executionProfile = uidropdown(g, 'Items', cellstr(guiExecutionProfileValues()), ...
    'Value', 'Balanced', 'ValueChangedFcn', callbacks.markDirty);

uilabel(g, 'Text', 'Preset effect');
uilabel(g, 'Text', 'Model-specific cost and numerical-stability profile. Metadata reports the effective internal preset.', 'WordWrap', 'on');

uilabel(g, 'Text', 'Settings');
uilabel(g, 'Text', 'Route policy, branch selection, and optimizer options remain configured separately.', 'WordWrap', 'on', 'FontAngle', 'italic');
end
