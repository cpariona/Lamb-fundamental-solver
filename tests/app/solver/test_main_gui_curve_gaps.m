function test_main_gui_curve_gaps()
%TEST_MAIN_GUI_CURVE_GAPS Protect Main GUI line data and presentation routing.
fig = figure('Visible', 'off');
cleanup = onCleanup(@() close(fig)); %#ok<NASGU>
ax = axes(fig);
masks = {[true;false;true], true(3,1), ...
    [true;true;false;true;true;false;true], [false;true;true;false], ...
    false(3,1), [false;true;false]};
for k = 1:numel(masks)
    mask = masks{k};
    x = 300 + (0:numel(mask)-1)'*200;
    for finiteInvalid = [false, true]
        cp = 2 + (0:numel(mask)-1)';
        if ~finiteInvalid
            cp(~mask) = nan;
        end
        before = {x, cp, mask};
        h = guiPlotSolverCurve(ax, x, cp, mask, '-', ...
            'Color', [0.1,0.2,0.3], 'DisplayName', 'A0');
        assert(isequal(h.XData(:), x));
        assert(isequal(h.YData(mask)', cp(mask)));
        assert(all(isnan(h.YData(~mask))), 'Invalid points must break the line.');
        assert(isequaln(before, {x, cp, mask}));
        assert(strcmp(h.DisplayName, 'A0') && isequal(h.Color, [0.1,0.2,0.3]));
    end
end
% Guard the nested GUI callers as well as the executable renderer boundary.
source = fileread(which('LambFundamental_GUI'));
assert(numel(strfind(source, 'guiPlotSolverCurve(ax, x, Cp, valid,')) == 3, ...
    'Normalized branches, approximations and raw branches must use gap-aware rendering.');
assert(~contains(source, 'plot(ax, x(valid), Cp(valid)'));
fprintf('Main GUI curve gap test passed.\n');
end
