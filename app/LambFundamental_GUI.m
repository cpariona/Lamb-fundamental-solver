function LambFundamental_GUI
% Compact GUI for fundamental Lamb modes using the modular backend.

params0 = defaultParams();
opts0 = defaultOptions("Balanced");
lastResults = [];
lastOptions = [];
inputsAreDirty = false;
colors.A0 = [0.0000 0.4470 0.7410];
colors.S0 = [1.0000 0.0000 0.0000];
colors.MRLFEA0 = [0.0000 0.4470 0.7410];
colors.MRLFES0 = [1.0000 0.0000 0.0000];

fig = uifigure('Name','Fundamental Lamb Wave Phase Velocity Calculator','Position',[100 100 1360 820]);
root = uigridlayout(fig,[1 2]);
root.ColumnWidth = {430,'1x'};

left = uipanel(root,'Title','Controls');
left.Layout.Column = 1;
leftGrid = uigridlayout(left,[3 1]);
leftGrid.RowHeight = {'1x',185,260};
leftGrid.Padding = [5 5 5 5];
leftGrid.RowSpacing = 8;

globalTabs = uitabgroup(leftGrid);
globalTabs.Layout.Row = 1;

callbacks = struct();
callbacks.markDirty = @(~,~)markDirty();
callbacks.onMaterialModelChanged = @(~,~)onMaterialModelChanged();
callbacks.refreshPlotOnly = @(~,~)refreshPlotOnly();
callbacks.onAutoAxesChanged = @(~,~)onAutoAxesChanged();
callbacks.resetAxes = @(~,~)resetAxes();
callbacks.useCurrentAxes = @(~,~)useCurrentAxes();

setup = createSetupTab(globalTabs, params0, callbacks);
plotControls = createPlotTab(globalTabs, callbacks);
advanced = createAdvancedTab(globalTabs, callbacks);
modelControls = createModelTabs(leftGrid, opts0, callbacks);
modelControls.panel.Layout.Row = 2;

runPanel = uipanel(leftGrid,'Title','Run / Export / Status');
runPanel.Layout.Row = 3;
rg = uigridlayout(runPanel,[5 1]);
rg.RowHeight = {30,30,58,58,30};
rg.Padding = [8 8 8 8];
rg.RowSpacing = 6;
uibutton(rg,'Text','Compute selected modes','ButtonPushedFcn',@(~,~)onCompute());
uibutton(rg,'Text','Export results','ButtonPushedFcn',@(~,~)onExport());
materialInfo = uilabel(rg,'Text','Material info will appear here.','WordWrap','on','FontSize',9,'VerticalAlignment','top');
statusLabel = uilabel(rg,'Text','Status: ready.','WordWrap','on','FontSize',9,'VerticalAlignment','top');
uibutton(rg,'Text','Show diagnostics','ButtonPushedFcn',@(~,~)onShowDiagnostics());

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
            statusLabel.Text = 'Status: ready. Press Compute.';
        else
            statusLabel.Text = 'Status: inputs changed. Press Compute to update.';
        end
    end

    function onCompute()
        try
            statusLabel.Text = 'Status: computing...'; drawnow;
            params = readParamsFromGui();
            options = defaultOptions(string(advanced.robustness.Value));
            options.computeA0 = logical(modelControls.rl.computeA0.Value);
            options.computeS0 = logical(modelControls.rl.computeS0.Value);
            options.computeMRLFERealK = logical(modelControls.mrlfe.computeRealK.Value);
            options.computeMRLFEComplexK = logical(modelControls.mrlfe.computeComplexK.Value);
            if options.computeMRLFERealK || options.computeMRLFEComplexK
                options.computeA0 = true;
                options.computeS0 = true;
                modelControls.rl.computeA0.Value = true;
                modelControls.rl.computeS0.Value = true;
                options.mrlfeParams = readMRLFEParamsFromGui();
            end
            lastResults = computeFundamentalLambModes(params, options);
            lastOptions = options;
            inputsAreDirty = false;
            plotControls.showA0.Value = isfield(lastResults.modes,'A0');
            plotControls.showS0.Value = isfield(lastResults.modes,'S0') && any(isfinite(lastResults.modes.S0.Cp));
            updatePlot();
            updateLabels();
        catch ME
            statusLabel.Text = ['Status: error: ', ME.message];
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
        params.numFrequencyPoints = "auto";
        params.frequencySpacing = "hybrid";
    end

    function mrlfeParams = readMRLFEParamsFromGui()
        mrlfeParams = defaultMRLFEParams();
        mrlfeParams.fluidDensity = modelControls.mrlfe.fluidDensity.Value;
        mrlfeParams.fluidSoundSpeed = modelControls.mrlfe.fluidSoundSpeed.Value;
        mrlfeParams.etaL = modelControls.mrlfe.etaL.Value;
        mrlfeParams.etaS = modelControls.mrlfe.etaS.Value;
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
        if plotControls.showMRLFEA0.Value
            plotCount = plotCount + plotMRLFEBranch('mRLFERealK', 'A0Like', ':', 'mRLFE real-k A0-like', colors.MRLFEA0, xSel);
            plotCount = plotCount + plotMRLFEBranch('mRLFEComplexK', 'A0Like', '-.', 'mRLFE complex-k A0-like', colors.MRLFEA0, xSel);
        end
        if plotControls.showMRLFES0.Value
            plotCount = plotCount + plotMRLFEBranch('mRLFERealK', 'S0Like', ':', 'mRLFE real-k S0-like', colors.MRLFES0, xSel);
            plotCount = plotCount + plotMRLFEBranch('mRLFEComplexK', 'S0Like', '-.', 'mRLFE complex-k S0-like', colors.MRLFES0, xSel);
        end
        if plotControls.showA0Thin.Value && isfield(lastResults, 'approximations') && isfield(lastResults.approximations, 'A0ThinPlate')
            mode = lastResults.approximations.A0ThinPlate;
            plot(ax, getModeX(mode,lastResults.grid,xSel), mode.Cp, '--', 'LineWidth', 1.5, 'Color', colors.A0, 'DisplayName', 'A0 thin plate');
            plotCount = plotCount + 1;
        end
        if plotControls.showS0Ext.Value && isfield(lastResults, 'approximations') && isfield(lastResults.approximations, 'S0Extensional')
            mode = lastResults.approximations.S0Extensional;
            plot(ax, getModeX(mode,lastResults.grid,xSel), mode.Cp, '--', 'LineWidth', 1.5, 'Color', colors.S0, 'DisplayName', 'S0 extensional');
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

    function didPlot = plotMRLFEBranch(modelName, branchName, lineStyle, displayName, colorValue, xSel)
        didPlot = 0;
        if hasMRLFEBranch(modelName, branchName)
            mode = lastResults.models.(modelName).branches.(branchName);
            plot(ax, getModeX(mode,lastResults.grid,xSel), mode.Cp, lineStyle, 'LineWidth', 2.0, 'Color', colorValue, 'DisplayName', displayName);
            didPlot = 1;
        end
    end

    function tf = hasMRLFEBranch(modelName, branchName)
        tf = isfield(lastResults, 'models') && isfield(lastResults.models, modelName) && ...
            isfield(lastResults.models.(modelName), 'branches') && ...
            isfield(lastResults.models.(modelName).branches, branchName) && ...
            any(isfinite(lastResults.models.(modelName).branches.(branchName).Cp));
    end

    function updateLabels()
        if isempty(lastResults) || isempty(lastOptions), return; end
        m = lastResults.material; thickness = lastResults.geometry.thickness; halfThickness = thickness/2;
        materialInfo.Text = sprintf('E %.4g kPa | nu %.5f\nCL %.2f m/s | CT %.2f m/s\nthick %.4g m | half %.4g m', ...
            m.E/1e3, m.nu, m.CL, m.CT, thickness, halfThickness);

        statusParts = {sprintf('%s | N=%d', string(lastOptions.robustness), numel(lastResults.grid.frequency))};
        if isfield(lastResults.modes,'A0')
            a0 = lastResults.modes.A0;
            statusParts{end+1} = sprintf('A0 %d/%d, R %.1e', sum(a0.valid), numel(a0.valid), maxFinite(a0.residual)); %#ok<AGROW>
        end
        if isfield(lastResults.modes,'S0')
            s0 = lastResults.modes.S0;
            statusParts{end+1} = sprintf('S0 %d/%d, R %.1e', sum(s0.valid), numel(s0.valid), maxFinite(s0.residual)); %#ok<AGROW>
        end
        statusParts = appendMRLFEStatus(statusParts, 'mRLFERealK', 'mRLFE-R');
        statusParts = appendMRLFEStatus(statusParts, 'mRLFEComplexK', 'mRLFE-C');
        if inputsAreDirty
            statusParts{end+1} = 'inputs changed'; %#ok<AGROW>
        end
        statusLabel.Text = strjoin(statusParts, newline);
    end

    function statusParts = appendMRLFEStatus(statusParts, modelName, label)
        if isfield(lastResults, 'models') && isfield(lastResults.models, modelName)
            d = lastResults.models.(modelName).diagnostics;
            statusParts{end+1} = sprintf('%s %.1fs', label, d.elapsedSeconds); %#ok<AGROW>
            if isfield(d.summary, 'A0Like')
                item = d.summary.A0Like;
                statusParts{end+1} = sprintf('%s A0L %d/%d, R %.1e', label, item.validPoints, item.totalPoints, item.maxResidual); %#ok<AGROW>
            end
            if isfield(d.summary, 'S0Like')
                item = d.summary.S0Like;
                statusParts{end+1} = sprintf('%s S0L %d/%d, R %.1e', label, item.validPoints, item.totalPoints, item.maxResidual); %#ok<AGROW>
            end
        end
    end

    function onShowDiagnostics()
        if isempty(lastResults) || isempty(lastOptions)
            uialert(fig, 'No diagnostics are available yet.', 'Diagnostics');
            return;
        end
        dfig = uifigure('Name','Solver diagnostics','Position',[180 180 620 560]);
        dg = uigridlayout(dfig, [1 1]);
        dg.Padding = [10 10 10 10];
        uitextarea(dg, 'Value', buildDiagnosticsText(), 'Editable', 'off', 'FontName', 'Consolas', 'FontSize', 11);
    end

    function txt = buildDiagnosticsText()
        lines = {};
        m = lastResults.material;
        lines{end+1} = 'Material'; %#ok<AGROW>
        lines{end+1} = sprintf('  E        = %.6g Pa', m.E); %#ok<AGROW>
        lines{end+1} = sprintf('  nu       = %.6g', m.nu); %#ok<AGROW>
        lines{end+1} = sprintf('  lambda   = %.6g Pa', m.lambda); %#ok<AGROW>
        lines{end+1} = sprintf('  mu       = %.6g Pa', m.mu); %#ok<AGROW>
        lines{end+1} = sprintf('  CL       = %.6g m/s', m.CL); %#ok<AGROW>
        lines{end+1} = sprintf('  CT       = %.6g m/s', m.CT); %#ok<AGROW>
        lines{end+1} = ''; %#ok<AGROW>
        lines{end+1} = 'Grid'; %#ok<AGROW>
        lines{end+1} = sprintf('  frequency points = %d', numel(lastResults.grid.frequency)); %#ok<AGROW>
        lines{end+1} = sprintf('  fmin/fmax        = %.6g / %.6g Hz', min(lastResults.grid.frequency), max(lastResults.grid.frequency)); %#ok<AGROW>
        lines{end+1} = ''; %#ok<AGROW>
        if isfield(lastResults.modes,'A0')
            lines = appendModeDiagnostics(lines, 'A0', lastResults.modes.A0);
        end
        if isfield(lastResults.modes,'S0')
            lines = appendModeDiagnostics(lines, 'S0', lastResults.modes.S0);
        end
        lines = appendMRLFEDiagnostics(lines, 'mRLFERealK');
        lines = appendMRLFEDiagnostics(lines, 'mRLFEComplexK');
        txt = lines(:);
    end

    function lines = appendMRLFEDiagnostics(lines, modelName)
        if isfield(lastResults, 'models') && isfield(lastResults.models, modelName)
            lines{end+1} = modelName; %#ok<AGROW>
            d = lastResults.models.(modelName).diagnostics;
            lines{end+1} = sprintf('  variant = %s', string(d.variant)); %#ok<AGROW>
            lines{end+1} = sprintf('  elapsed = %.3f s', d.elapsedSeconds); %#ok<AGROW>
            branchNames = fieldnames(d.summary);
            for i = 1:numel(branchNames)
                item = d.summary.(branchNames{i});
                lines{end+1} = sprintf('  %s: %d/%d valid, Cp %.6g..%.6g m/s, alpha %.6g..%.6g 1/m, max R %.3e', ...
                    branchNames{i}, item.validPoints, item.totalPoints, item.minCp, item.maxCp, ...
                    item.minAttenuation, item.maxAttenuation, item.maxResidual); %#ok<AGROW>
            end
            lines{end+1} = ''; %#ok<AGROW>
        end
    end

    function lines = appendModeDiagnostics(lines, name, mode)
        validCp = mode.valid & isfinite(mode.Cp);
        lines{end+1} = name; %#ok<AGROW>
        lines{end+1} = sprintf('  valid    = %d / %d', sum(mode.valid), numel(mode.valid)); %#ok<AGROW>
        if any(validCp)
            lines{end+1} = sprintf('  Cp range = %.6g .. %.6g m/s', min(mode.Cp(validCp)), max(mode.Cp(validCp))); %#ok<AGROW>
        end
        lines{end+1} = sprintf('  max R    = %.3e', maxFinite(mode.residual)); %#ok<AGROW>
        lines{end+1} = ''; %#ok<AGROW>
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
        if isfield(lastResults, 'approximations')
            ApproximationResults = lastResults.approximations; %#ok<NASGU>
            assignin('base', 'ApproximationResults', ApproximationResults);
        end
        if isfield(lastResults, 'models')
            if isfield(lastResults.models, 'mRLFERealK')
                MRLFERealKResults = lastResults.models.mRLFERealK; %#ok<NASGU>
                assignin('base', 'MRLFERealKResults', MRLFERealKResults);
            end
            if isfield(lastResults.models, 'mRLFEComplexK')
                MRLFEComplexKResults = lastResults.models.mRLFEComplexK; %#ok<NASGU>
                assignin('base', 'MRLFEComplexKResults', MRLFEComplexKResults);
            end
            if isfield(lastResults.models, 'mRLFE')
                MRLFEResults = lastResults.models.mRLFE; %#ok<NASGU>
                assignin('base', 'MRLFEResults', MRLFEResults);
            end
        end
        statusLabel.Text = 'Status: exported to workspace.';
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
        if isfield(mode, 'kReal'), x = mode.kReal; else, x = real(mode.k); end
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

function value = maxFinite(x)
mask = isfinite(x);
if any(mask)
    value = max(x(mask));
else
    value = nan;
end
end
