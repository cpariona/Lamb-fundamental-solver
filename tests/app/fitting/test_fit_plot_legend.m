function test_fit_plot_legend()
%TEST_FIT_PLOT_LEGEND Legends represent actual data, including partial inputs.
fig = figure('Visible', 'off');
cleanup = onCleanup(@() close(fig)); %#ok<NASGU>
ax = axes(fig);
warningState = warning('error', 'MATLAB:legend:IgnoringExtraEntries');
restoreWarning = onCleanup(@() warning(warningState)); %#ok<NASGU>
r = struct('frequency_Hz', [300;500;700], 'Cp_exp_mps', [2;3;4], ...
    'Cp_fit_mps', [2;3;4], 'validMask', true(3,1), ...
    'modelName', "mRLFERealK", 'branchName', "A0Like");
for scenario = [4,1,2,3,5,4,1]
    input = r;
    switch scenario
        case 1
            input.validMask(:) = false;
            expected = strings(0,1);
        case 2
            input.Cp_fit_mps(:) = nan;
            expected = "Experimental data";
        case 3
            input.Cp_exp_mps(:) = nan;
            input.Cp_fit_mps(:) = nan;
            input.fullCurve = struct('frequency_Hz', r.frequency_Hz, ...
                'Cp_mps', [2;nan;4], 'validMask', [true;false;true]);
            expected = "Fitted curve";
        case 4
            expected = ["Experimental data"; "Model at data points"];
        case 5
            input.Cp_exp_mps(:) = nan;
            expected = "Model at data points";
    end
    before = input;
    guiPlotFitResult(input, ax);
    assert(isequaln(input, before));
    lines = findobj(ax, 'Type', 'line');
    names = strings(numel(lines),1);
    for k = 1:numel(lines), names(k) = string(lines(k).DisplayName); end
    assert(isequal(sort(names), sort(expected(:))));
    lg = findobj(fig, 'Type', 'legend');
    if isempty(expected)
        assert(isempty(lines) && isempty(lg), 'All-invalid data must produce no fake curves or legend.');
    else
        assert(numel(lg) == 1 && isequal(sort(string(lg.String(:))), sort(expected(:))));
    end
    if scenario == 3
        assert(isnan(lines.YData(2)), 'Legend changes must preserve curve gaps.');
    end
end
fprintf('Fit plot legend test passed.\n');
end
