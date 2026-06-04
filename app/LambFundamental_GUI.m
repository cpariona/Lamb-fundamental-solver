function LambFundamental_GUI
% Compact GUI for fundamental Lamb modes using the modular backend.

params0 = defaultParams();
opts0 = defaultOptions("Balanced");
lastResults = [];
lastOptions = [];
inputsAreDirty = false;
colors.A0 = [0.0000 0.4470 0.7410];
colors.S0 = [1.0000 0.0000 0.0000];

fig = uifigure('Name','Fundamental Lamb Wave Phase Velocity Calculator','Position',[100 100 1360 760]);
root = uigridlayout(fig,[1 2]);
root.ColumnWidth = {430,'1x'};

left = uipanel(root,'Title','Controls');
left.Layout.Column = 1;
leftGrid = uigridlayout(left,[2 1]);
leftGrid.RowHeight = {'1x',220};
leftGrid.Padding = [5 5 5 5];
leftGrid.RowSpacing = 8;

tabs = uitabgroup(leftGrid);
tabs.Layout.Row = 1;

callbacks = struct();
callbacks.markDirty = @(~,~)markDirty();
callbacks.onMaterialModelChanged = @(~,~)onMaterialModelChanged();
callbacks.refreshPlotOnly = @(~,~)refreshPlotOnly();
callbacks.onAutoAxesChanged = @(~,~)onAutoAxesChanged();
callbacks.resetAxes = @(~,~)resetAxes();
callbacks.useCurrentAxes = @(~,~)useCurrentAxes();

setup = createSetupTab(tabs, params0, opts0, callbacks);
plotControls = createPlotTab(tabs, callbacks);
advanced = createAdvancedTab(tabs, callbacks);

runPanel = uipanel(leftGrid,'Title','Run / Export');
runPanel.Layout.Row = 2;
rg = uigridlayout(runPanel,[5 1]);
rg.RowHeight = {34,34,90,'1x',44};
rg.Padding = [10 10 10 10];
uibutton(rg,'Text','Compute selected modes','ButtonPushedFcn',@(~,~)onCompute());
uibutton(rg,'Text','Export results','ButtonPushedFcn',@(~,~)onExport());
materialInfo = uilabel(rg,'Text','Material info will appear here.','WordWrap','on');
statusLabel = uilabel(rg,'Text','Ready.','WordWrap','on');

ax = uiaxes(root);
ax.Layout.Column = 2;
grid(ax,'on');
xlabel(ax,'frequency [Hz]');
ylabel(ax,'Phase velocity Cp [m/s]');
title(ax,'Fundamental Lamb modes (Cp)');
try
    enableDefaultInteractivity(ax);
catch
end

updateMaterialInputState();
updateAxisFieldState();

    function onMaterialModelChanged()
        updateMaterialInputState();
        markDirty();
    end

    function updateMaterialInputState()
        ypOn = string(setup.model.Value) == "YoungPoissonFixedCL";
        setup.Elabel.Enable = onOff(ypOn); setup.E.Enable = onOff(ypOn);
        setup.nulabel.Enable = onOff(ypOn); setup.nu.Enable = onOff(ypOn);
        setup.CLlabel.Enable = onOff(ypOn); setup.CL.Enable = onOff(ypOn);
        setup.lambdalabel.Enable = onOff(~ypOn); setup.lambda.Enable = onOff(~ypOn);
        setup.mulabel.Enable = onOff(~ypOn); setup.mu.Enable = onOff(~ypOn);
    end

    function markDirty()
        inputsAreDirty = true;
        if isempty(lastResults)
            statusLabel.Text = 'Ready. Press Compute selected modes.';
        else
            statusLabel.Text = 'Inputs changed. Press Compute selected modes to update the solution.';
        end
    end

    function onCompute()
        try
            statusLabel.Text = 'Computing...'; drawnow;
            params = readParamsFromGui();
            options = defaultOptions(string(advanced.robustness.Value));
            options.computeA0 = logical(setup.computeA0.Value);
            options.computeS0 = logical(setup.computeS0.Value);
            lastResults = computeFundamentalLambModes(params, options);
            lastOptions = options;
            inputsAreDirty = false;
            plotControls.showA0.Value = isfield(lastResults.modes,'A0');
            plotControls.showS0.Value = isfield(lastResults.modes,'S0') && any(isfinite(lastResults.modes.S0.Cp));
            updatePlot();
            updateLabels();
        catch ME
            statusLabel.Text = ['Error: ', ME.message];
            uialert(fig, ME.message, 'Compute error');
        end
    end

    function params = readParamsFromGui()
        params = defaultParams();
        params.modelType = string(setup.model.Value);
        params.rho = setup.rho.Value;
        params.E = setup.E.Value * 1e3;
        params.nu = setup.nu.Value;
        params.CL = setup.CL.Value;
        params.lambda = setup.lambda.Value * 1e6;
        params.mu = setup.mu.Value * 1e3;
        params.thickness = setup.thickness.Value * 1e-3;
        params.fmin = setup.fmin.Value;
        params.fmax = setup.fmax.Value;
        params.numFrequencyPoints = round(setup.N.Value);
        params.frequencySpacing = string(setup.spacing.Value);
    end

    function refreshPlotOnly()
        updateAxisFieldState();
        if isempty(lastResults)
            xlabel(ax, getXLabel(string(plotControls.xaxis.Value)));
            return;
        end
        updatePlot();
        updateLabels();
    end

    function onAutoAxesChanged()
        updateAxisFieldState();
        refreshPlotOnly();
    end

    function resetAxes()
        plotControls.autoAxes.Value = true;
        updateAxisFieldState();
        refreshPlotOnly();
    end

    function useCurrentAxes()
        xl = xlim(ax);
        yl = ylim(ax);
        plotControls.xmin.Value = xl(1); plotControls.xmax.Value = xl(2);
        plotControls.ymin.Value = yl(1); plotControls.ymax.Value = yl(2);
        plotControls.autoAxes.Value = false;
        updateAxisFieldState();
        refreshPlotOnly();
    end

    function updateAxisFieldState()
        manualOn = ~plotControls.autoAxes.Value;
        plotControls.xmin.Enable = onOff(manualOn); plotControls.xmax.Enable = onOff(manualOn);
        plotControls.ymin.Enable = onOff(manualOn); plotControls.ymax.Enable = onOff(manualOn);
    end

    function updatePlot()
        cla(ax); hold(ax,'on');
        xSel = string(plotControls.xaxis.Value);
        plotCount = 0;
        if plotControls.showA0.Value && isfield(lastResults.modes,'A0')
            mode = lastResults.modes.A0;
            plot(ax, getModeX(mode,lastResults.grid,xSel), mode.Cp, '-', 'LineWidth', 2, 'Color', colors.A0, 'DisplayName', 'A0');
            plotCount = plotCount + 1;
        end
        if plotControls.showS0.Value && isfield(lastResults.modes,'S0') && any(isfinite(lastResults.modes.S0.Cp))
            mode = lastResults.modes.S0;
            plot(ax, getModeX(mode,lastResults.grid,xSel), mode.Cp, '-', 'LineWidth', 2, 'Color', colors.S0, 'DisplayName', 'S0 experimental');
            plotCount = plotCount + 1;
        end
        xlabel(ax, getXLabel(xSel)); ylabel(ax, 'Phase velocity Cp [m/s]');
        title(ax, 'Fundamental Lamb modes (Cp)'); grid(ax,'on');
        if plotCount > 0, legend(ax,'Location','best'); else, legend(ax,'off'); end
        if plotControls.autoAxes.Value
            xlim(ax,'auto'); ylim(ax,'auto');
        else
            if plotControls.xmax.Value > plotControls.xmin.Value, xlim(ax,[plotControls.xmin.Value plotControls.xmax.Value]); end
            if plotControls.ymax.Value > plotControls.ymin.Value, ylim(ax,[plotControls.ymin.Value plotControls.ymax.Value]); end
        end
        hold(ax,'off');
    end

    function updateLabels()
        if isempty(lastResults) || isempty(lastOptions), return; end
        m = lastResults.material; thickness = lastResults.geometry.thickness; halfThickness = thickness/2;
        materialInfo.Text = sprintf(['E = %.4g kPa, nu = %.6f\n', ...
            'lambda = %.4g MPa, mu = %.4g kPa\n', ...
            'CL = %.4f m/s, CT = %.4f m/s\n', ...
            'thickness = %.6g m, halfThickness = %.6g m'], ...
            m.E/1e3, m.nu, m.lambda/1e6, m.mu/1e3, m.CL, m.CT, thickness, halfThickness);
        txt = {sprintf('Robustness: %s', string(lastOptions.robustness))};
        if inputsAreDirty, txt{end+1} = 'Inputs changed after this solution. Press Compute selected modes to update.'; end %#ok<AGROW>
        if isfield(lastResults.modes,'A0')
            a0 = lastResults.modes.A0;
            txt{end+1} = sprintf('A0 valid points: %d/%d', sum(a0.valid), numel(a0.valid)); %#ok<AGROW>
            if any(isfinite(a0.residual)), txt{end+1} = sprintf('A0 max residual: %.3e', max(a0.residual(isfinite(a0.residual)))); end %#ok<AGROW>
        end
        if isfield(lastResults.modes,'S0')
            s0 = lastResults.modes.S0;
            txt{end+1} = sprintf('S0 experimental valid points: %d/%d', sum(s0.valid), numel(s0.valid)); %#ok<AGROW>
            if any(isfinite(s0.residual)), txt{end+1} = sprintf('S0 experimental max residual: %.3e', max(s0.residual(isfinite(s0.residual)))); end %#ok<AGROW>
        end
        statusLabel.Text = strjoin(txt,newline);
    end

    function onExport()
        if isempty(lastResults)
            uialert(fig,'No results to export.','Export error'); return;
        end
        LambResults = lastResults; %#ok<NASGU>
        assignin('base','LambResults',LambResults);
        if isfield(lastResults.modes,'A0')
            A0_table = modeToTable(lastResults.modes.A0); %#ok<NASGU>
            assignin('base','A0_table',A0_table);
        end
        if isfield(lastResults.modes,'S0') && any(isfinite(lastResults.modes.S0.Cp))
            S0_table = modeToTable(lastResults.modes.S0); %#ok<NASGU>
            assignin('base','S0_table',S0_table);
        end
        statusLabel.Text = 'Exported LambResults and available mode tables to workspace.';
    end
end

function txt = onOff(flag)
if flag, txt = 'on'; else, txt = 'off'; end
end

function x = getModeX(mode, gridData, xSel)
switch xSel
    case "frequency"
        if isfield(mode,'frequency'), x = mode.frequency; else, x = gridData.frequency; end
    case "angularFrequency"
        if isfield(mode,'omega'), x = mode.omega; else, x = gridData.omega; end
    case "wavenumber"
        x = mode.k;
    case "kThickness"
        x = mode.kThickness;
    otherwise
        x = gridData.frequency;
end
end

function lbl = getXLabel(xSel)
switch xSel
    case "frequency"
        lbl = 'frequency [Hz]';
    case "angularFrequency"
        lbl = 'angularFrequency [rad/s]';
    case "wavenumber"
        lbl = 'wavenumber k [1/m]';
    case "kThickness"
        lbl = 'kThickness = k * thickness [-]';
    otherwise
        lbl = 'frequency [Hz]';
end
end

function out = modeToTable(mode)
out = table(mode.frequency(:), mode.omega(:), mode.Cp(:), mode.k(:), mode.kThickness(:), mode.residual(:), mode.valid(:), ...
    'VariableNames', {'Frequency_Hz','Omega_rad_s','Cp','k','kThickness','Residual','Valid'});
end
