function test_fit_display_curve_no_solver_contract()
%TEST_FIT_DISPLAY_CURVE_NO_SOLVER_CONTRACT Validate interpolation-only display curve.

fprintf('\nRunning fit display-curve no-solver contract test...\n');
fprintf('--------------------------------------------------\n');

fitResult = struct();
fitResult.modelFamily = "mrlfe";
fitResult.branchName = "A0Like";
fitResult.frequency_Hz = [1000; 2000; 3000; 4000];
fitResult.Cp_fit_mps = [2.0; 2.4; 2.8; 3.1];
fitResult.validMask = true(4, 1);

curve = guiBuildFitDisplayCurve(fitResult, 80);

assert(curve.source == "fitObjectiveInterpolation", ...
    'Display curve source metadata mismatch.');
assert(curve.solverEvaluated == false, ...
    'Display curve must not report a solver evaluation.');
assert(numel(curve.frequency_Hz) == 80, ...
    'Display curve should use the requested plotting point count.');
assert(all(isfinite(curve.Cp_mps(curve.validMask))), ...
    'Display curve interpolation must be finite on valid points.');
assert(isempty(curve.denseSolver.frequency_Hz), ...
    'Automatic dense solver evaluation must remain absent.');
assert(contains(curve.extension.errorMessage, "explicit user request"), ...
    'Display curve must state that full evaluation is user-triggered.');

checkGapRendering();
fprintf('Fit display-curve no-solver contract test passed.\n');
end

function checkGapRendering()
fig = figure('Visible', 'off');
cleanup = onCleanup(@() close(fig)); %#ok<NASGU>
ax = axes(fig);
masks = {[true;false;true], true(3,1), ...
    [true;true;false;true;true;false;true], [false;true;true;false], ...
    false(3,1), [false;true;false]};
for k = 1:numel(masks)
    mask = masks{k};
    frequency = 300 + (0:numel(mask)-1)' * 200;
    for finiteInvalid = [false, true]
        cp = 2 + (0:numel(mask)-1)';
        if ~finiteInvalid
            cp(~mask) = nan;
        end
        input = struct('modelFamily', "mrlfe", 'branchName', "A0Like", ...
            'frequency_Hz', frequency, 'Cp_fit_mps', cp, 'validMask', mask);
        original = input;
        curve = guiBuildFitDisplayCurve(input, 21);
        assert(isequaln(input, original), 'Display builder mutated its input.');
        assert(isequal(curve.anchorValidMask, mask));
        assert(isequaln(curve.anchorCp_mps, cp));
        assert(~curve.solverEvaluated && curve.source == "fitObjectiveInterpolation");
        % Each finite run must have exactly the endpoints of one input run.
        assertRuns(curve.frequency_Hz, curve.Cp_mps, frequency, mask);
        for invalidFrequency = frequency(~mask)'
            atInvalid = curve.frequency_Hz == invalidFrequency;
            assert(any(atInvalid) && all(isnan(curve.Cp_mps(atInvalid))));
            assert(~any(curve.validMask(atInvalid)));
        end
        if all(mask)
            assert(numel(curve.frequency_Hz) == 21);
            assert(all(isfinite(curve.Cp_mps)));
            assert(any(~ismember(curve.frequency_Hz, frequency)), ...
                'Contiguous valid support should still be densified.');
        end
        normalized = input;
        normalized.modelName = "mRLFERealK";
        normalized.Cp_exp_mps = cp;
        normalized.fullCurve = curve;
        normalized.requestedCurve = struct('frequency_Hz', frequency, ...
            'Cp_mps', cp, 'validMask', mask);
        before = normalized;
        guiPlotFitResult(normalized, ax);
        assert(isequaln(normalized, before), 'Renderer mutated canonical data.');
        lines = findobj(ax, 'Type', 'line');
        curveCount = 0;
        for j = 1:numel(lines)
            if string(lines(j).LineStyle) == "none"
                continue;
            end
            curveCount = curveCount + 1;
            assertRuns(lines(j).XData(:)*1000, lines(j).YData(:), frequency, mask);
        end
        assert(curveCount == 2 * any(mask));
    end
end
end

function assertRuns(x, y, frequency, mask)
edges = diff([false; mask; false]);
expectedStart = frequency(edges(1:end-1) == 1);
expectedStop = frequency(find(edges == -1)-1);
valid = isfinite(x(:)) & isfinite(y(:));
edges = diff([false; valid; false]);
actualStart = x(find(edges == 1));
actualStop = x(find(edges == -1)-1);
assert(isequal(actualStart(:), expectedStart(:)) && ...
    isequal(actualStop(:), expectedStop(:)), ...
    'Rendering must preserve each canonical valid run without bridging or extrapolation.');
end
