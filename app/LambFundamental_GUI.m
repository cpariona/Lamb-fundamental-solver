function LambFundamental_GUI
% Compact GUI for fundamental Lamb modes using the modular backend.

params0 = rlDefaultParams();
opts0 = rlDefaultOptions("Balanced");
lastResults = [];
lastGuiResult = [];
lastOptions = [];
lastParams = [];
inputsAreDirty = false;
colors.A0 = [0.0000 0.4470 0.7410];
colors.S0 = [1.0000 0.0000 0.0000];
colors.HanA0 = [0.0000 0.4470 0.7410];
colors.HanS0 = [1.0000 0.0000 0.0000];
colors.AE = [0.4940 0.1840 0.5560];

fig = uifigure('Name','Fundamental Lamb Wave Phase Velocity Calculator','Position',[80 80 1460 860]);
root = uigridlayout(fig,[1 2]);
root.ColumnWidth = {500,'1x'};

left = uipanel(root,'Title','Controls');
left.Layout.Column = 1;
leftGrid = uigridlayout(left,[3 1]);
leftGrid.RowHeight = {'1x',285,235};
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
rg = uigridlayout(runPanel,[4 1]);
rg.RowHeight = {28,34,'1x',26};
rg.Padding = [8 5 8 5];
rg.RowSpacing = 3;
buttonGrid = uigridlayout(rg,[1 2]);
buttonGrid.Layout.Row = 1;
buttonGrid.ColumnWidth = {'1x','1x'};
buttonGrid.Padding = [0 0 0 0];
buttonGrid.ColumnSpacing = 6;
uibutton(buttonGrid,'Text','Compute selected modes','ButtonPushedFcn',@(~,~)onCompute());
uibutton(buttonGrid,'Text','Export results','ButtonPushedFcn',@(~,~)onExport());
materialInfo = uilabel(rg,'Text','Material info will appear here.','WordWrap','on','FontSize',10,'VerticalAlignment','top');
statusBox = uitextarea(rg,'Value',{'Status: ready.'},'Editable','off','FontName','Consolas','FontSize',10);
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
            setStatusText({'Status: ready. Press Compute.'});
        else
            setStatusText({'Status: inputs changed. Press Compute to update.'});
        end
    end

    function onCompute()
        try
            setStatusText({'Status: computing...'}); drawnow;
            params = readParamsFromGui();
            options = readOptionsFromGui();

            [lastResults, lastGuiResult] = runModelRequestThroughAdapter(params, options);

            lastOptions = options;
            lastParams = params;
            inputsAreDirty = false;
            updatePlotCheckboxesFromResults();
            updatePlot();
            updateLabels();
        catch ME
            setStatusText({['Status: error: ', ME.message]});
            uialert(fig, ME.message, 'Compute error');
        end
    end

    function options = readOptionsFromGui()
        options = rlDefaultOptions(string(advanced.robustness.Value));
        options.computeAcoustoelasticIOPHGO = logical(modelControls.ae.computeAtlasA0.Value);

        if options.computeAcoustoelasticIOPHGO
            options.computeA0 = false;
            options.computeS0 = false;
            options.computeMRLFERealK = false;
            options.computeMRLFEHanViscoRealK = false;
            options.computeMRLFEComplexK = false;
            options.mrlfeComputeA0Like = false;
            options.mrlfeComputeS0Like = false;
            options.acoustoelasticOptions = readAcoustoelasticOptionsFromGui();
            return;
        end

        options.computeA0 = logical(modelControls.rl.computeA0.Value);
        options.computeS0 = logical(modelControls.rl.computeS0.Value);
        options.computeMRLFERealK = logical(modelControls.mrlfe.computeRealK.Value);
        options.computeMRLFEHanViscoRealK = logical(modelControls.mrlfe.computeHanViscoRealK.Value);
        options.computeMRLFEComplexK = false;
        options.mrlfeComputeA0Like = logical(modelControls.mrlfe.computeA0Like.Value);
        options.mrlfeComputeS0Like = logical(modelControls.mrlfe.computeS0Like.Value);

        if (options.computeMRLFERealK || options.computeMRLFEHanViscoRealK)
            if ~options.mrlfeComputeA0Like && ~options.mrlfeComputeS0Like
                error('Select at least one mRLFE branch: A0-like or S0-like.');
            end
            options.computeA0 = options.computeA0 || options.mrlfeComputeA0Like;
            options.computeS0 = options.computeS0 || options.mrlfeComputeS0Like;
            modelControls.rl.computeA0.Value = options.computeA0;
            modelControls.rl.computeS0.Value = options.computeS0;
            options.mrlfeParams = readMRLFEParamsFromGui();
        end
    end

    function params = readParamsFromGui()
        params = rlDefaultParams();
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
        mrlfeParams.etaS = modelControls.mrlfe.etaS.Value;
        mrlfeParams.etaL = 0;
        mrlfeParams.useComplexLambda = false;
    end

    function aeParams = readAcoustoelasticParamsFromGui(baseParams, options)
        aeParams = struct();
        aeParams.R = modelControls.ae.R.Value * 1e-3;
        aeParams.thickness = baseParams.thickness;
        aeParams.IOP = modelControls.ae.IOP.Value * 133.322;
        aeParams.mu = baseParams.mu;
        aeParams.k1 = modelControls.ae.k1.Value * 1e3;
        aeParams.k2 = modelControls.ae.k2.Value;
        aeParams.rho = baseParams.rho;
        aeParams.rhoF = modelControls.ae.rhoF.Value;
        aeParams.fluidBulkModulus = modelControls.ae.fluidBulkModulus.Value * 1e9;
        aeParams.frequency = buildAcoustoelasticFrequencyVector(baseParams, options);
    end

    function aeOptions = readAcoustoelasticOptionsFromGui()
        aeOptions = defaultAcoustoelasticIOPHGOOptions();
        aeOptions.M54_variant = "corrected";
        aeOptions.normalizeRows = false;
        aeOptions.usePhysicalCpWindow = false;
        aeOptions.atlasBranchPolicy = "atlasA0";
        aeOptions.atlasNumYPoints = round(modelControls.ae.atlasNumYPoints.Value);
        aeOptions.atlasTopNMinima = round(modelControls.ae.atlasTopNMinima.Value);
    end

    function frequency = buildAcoustoelasticFrequencyVector(params, options)
        switch string(options.robustness)
            case "Fast"
                n = 35;
            case "Robust"
                n = 70;
            otherwise
                n = 50;
        end
        frequency = logspace(log10(params.fmin), log10(params.fmax), n);
    end

    function [results, guiResult] = runModelRequestThroughAdapter(params, options)
        guiRequest = struct();

        if getOptionValue(options, 'computeAcoustoelasticIOPHGO', false)
            aeParams = readAcoustoelasticParamsFromGui(params, options);
            guiRequest.params = aeParams;
            guiRequest.options = options.acoustoelasticOptions;
            guiResult = guiRunAcoustoelasticIOPHGOModel(guiRequest);
            results = guiResult.metadata.rawResult;
            return;
        end

        guiRequest.params = params;
        guiRequest.options = options;

        if isfield(options, 'mrlfeParams')
            guiRequest.mrlfeParams = options.mrlfeParams;
        end

        if options.computeMRLFERealK || options.computeMRLFEHanViscoRealK
            guiRequest.computeElastic = options.computeMRLFERealK || options.computeMRLFEHanViscoRealK;
            guiRequest.computeHan = options.computeMRLFEHanViscoRealK;
            guiResult = guiRunMRLFEModel(guiRequest);
        else
            guiResult = guiRunRayleighLambModel(guiRequest);
        end
        results = guiResult.metadata.rawResult;
    end

    function updatePlotCheckboxesFromResults()
        if isstruct(lastResults) && isfield(lastResults, 'modes')
            plotControls.showA0.Value = isfield(lastResults.modes,'A0');
            plotControls.showS0.Value = isfield(lastResults.modes,'S0') && any(isfinite(lastResults.modes.S0.Cp));
        end
    end

    function refreshPlotOnly()
        updateAxisFieldState();
        if isempty(lastResults)
            xlabel(ax, getXLabel(string(plotControls.xaxis.Value)));
            ylabel(ax, 'Phase velocity Cp [m/s]');
            return;
        end
        updatePlot();
        updateLabels();
    end

    function onAutoAxesChanged(), updateAxisFieldState(); refreshPlotOnly(); end
    function resetAxes(), plotControls.autoAxes.Value = true; updateAxisFieldState(); refreshPlotOnly(); end

    function useCurrentAxes()
        xl = xlim(ax); yl = ylim(ax);
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
        xSel = string(plotControls.xaxis.Value); plotCount = 0;
        if tryPlotNormalizedResults(xSel)
            return;
        end
        if isstruct(lastResults) && isfield(lastResults, 'modes')
            if plotControls.showA0.Value && isfield(lastResults.modes,'A0')
                plotCount = plotCount + plotMode(lastResults.modes.A0, '-', 'A0', colors.A0, xSel);
            end
            if plotControls.showS0.Value && isfield(lastResults.modes,'S0') && any(isfinite(lastResults.modes.S0.Cp))
                plotCount = plotCount + plotMode(lastResults.modes.S0, '-', 'S0', colors.S0, xSel);
            end
        end
        if isfield(plotControls, 'showMRLFEElasticA0') && plotControls.showMRLFEElasticA0.Value
            plotCount = plotCount + plotMRLFEBranch('mRLFEElasticRealK', 'A0Like', ':', 'mRLFE elastic A0-like', colors.HanA0, xSel);
        end
        if isfield(plotControls, 'showMRLFEElasticS0') && plotControls.showMRLFEElasticS0.Value
            plotCount = plotCount + plotMRLFEBranch('mRLFEElasticRealK', 'S0Like', ':', 'mRLFE elastic S0-like', colors.HanS0, xSel);
        end
        if isfield(plotControls, 'showMRLFEHanA0') && plotControls.showMRLFEHanA0.Value
            plotCount = plotCount + plotMRLFEBranch('mRLFEHanViscoRealK', 'A0Like', '-.', 'mRLFE Han visco A0-like', colors.HanA0, xSel);
        end
        if isfield(plotControls, 'showMRLFEHanS0') && plotControls.showMRLFEHanS0.Value
            plotCount = plotCount + plotMRLFEBranch('mRLFEHanViscoRealK', 'S0Like', '-.', 'mRLFE Han visco S0-like', colors.HanS0, xSel);
        end
        if isstruct(lastResults) && isfield(lastResults, 'approximations')
            if plotControls.showA0Thin.Value && isfield(lastResults.approximations, 'A0ThinPlate')
                plotCount = plotCount + plotMode(lastResults.approximations.A0ThinPlate, '--', 'A0 thin plate', colors.A0, xSel);
            end
            if plotControls.showS0Ext.Value && isfield(lastResults.approximations, 'S0Extensional')
                plotCount = plotCount + plotMode(lastResults.approximations.S0Extensional, '--', 'S0 extensional', colors.S0, xSel);
            end
        end
        xlabel(ax, getXLabel(xSel)); ylabel(ax, 'Phase velocity Cp [m/s]');
        title(ax, 'Fundamental Lamb modes (Cp)'); grid(ax,'on');
        if plotCount > 0, legend(ax,'Location','best'); else, legend(ax,'off'); end
        applyAxisLimits();
        hold(ax,'off');
    end

    function didPlot = tryPlotNormalizedResults(xSel)
        didPlot = false;
        if isempty(lastGuiResult) || ~isfield(lastGuiResult, 'branches') || isempty(lastGuiResult.branches)
            return;
        end

        plotCount = 0;
        branches = lastGuiResult.branches(:);
        for iBranch = 1:numel(branches)
            branch = branches(iBranch);
            if ~shouldPlotNormalizedBranch(branch)
                continue;
            end

            plotData = guiGetNormalizedBranchPlotData(branch, xSel);
            x = plotData.x;
            y = plotData.y;
            validMask = plotData.validMask;
            x(~validMask) = nan;
            y(~validMask) = nan;

            if any(isfinite(y))
                plot(ax, x, y, normalizedBranchLineStyle(branch), ...
                    'LineWidth', 2, ...
                    'Color', normalizedBranchColor(branch), ...
                    'DisplayName', normalizedBranchDisplayName(branch));
                plotCount = plotCount + 1;
            end
        end

        if isstruct(lastResults) && isfield(lastResults, 'approximations')
            if plotControls.showA0Thin.Value && isfield(lastResults.approximations, 'A0ThinPlate')
                plotCount = plotCount + plotMode(lastResults.approximations.A0ThinPlate, '--', 'A0 thin plate', colors.A0, xSel);
            end
            if plotControls.showS0Ext.Value && isfield(lastResults.approximations, 'S0Extensional')
                plotCount = plotCount + plotMode(lastResults.approximations.S0Extensional, '--', 'S0 extensional', colors.S0, xSel);
            end
        end

        if plotCount <= 0
            return;
        end

        xlabel(ax, getXLabel(xSel));
        ylabel(ax, 'Phase velocity Cp [m/s]');
        title(ax, 'Fundamental Lamb modes (Cp)');
        grid(ax, 'on');
        legend(ax, 'Location', 'best');
        applyAxisLimits();
        hold(ax, 'off');
        didPlot = true;
    end

    function tf = shouldPlotNormalizedBranch(branch)
        modelName = string(branch.modelName);
        branchName = string(branch.branchName);

        tf = false;
        if modelName == "RayleighLamb" && branchName == "A0"
            tf = plotControls.showA0.Value;
        elseif modelName == "RayleighLamb" && branchName == "S0"
            tf = plotControls.showS0.Value;
        elseif modelName == "mRLFEElasticRealK" && branchName == "A0Like"
            tf = isfield(plotControls, 'showMRLFEElasticA0') && plotControls.showMRLFEElasticA0.Value;
        elseif modelName == "mRLFEElasticRealK" && branchName == "S0Like"
            tf = isfield(plotControls, 'showMRLFEElasticS0') && plotControls.showMRLFEElasticS0.Value;
        elseif modelName == "mRLFEHanViscoRealK" && branchName == "A0Like"
            tf = isfield(plotControls, 'showMRLFEHanA0') && plotControls.showMRLFEHanA0.Value;
        elseif modelName == "mRLFEHanViscoRealK" && branchName == "S0Like"
            tf = isfield(plotControls, 'showMRLFEHanS0') && plotControls.showMRLFEHanS0.Value;
        elseif modelName == "AcoustoelasticIOPHGO"
            tf = true;
        end
    end

    function displayName = normalizedBranchDisplayName(branch)
        modelName = string(branch.modelName);
        branchName = string(branch.branchName);

        if modelName == "RayleighLamb"
            displayName = char(branchName);
        elseif modelName == "mRLFEElasticRealK" && branchName == "A0Like"
            displayName = 'mRLFE elastic A0-like';
        elseif modelName == "mRLFEElasticRealK" && branchName == "S0Like"
            displayName = 'mRLFE elastic S0-like';
        elseif modelName == "mRLFEHanViscoRealK" && branchName == "A0Like"
            displayName = 'mRLFE Han visco A0-like';
        elseif modelName == "mRLFEHanViscoRealK" && branchName == "S0Like"
            displayName = 'mRLFE Han visco S0-like';
        elseif modelName == "AcoustoelasticIOPHGO"
            displayName = 'AE IOP/HGO atlasA0';
        else
            displayName = char(strtrim(modelName + " " + branchName));
        end
    end

    function lineStyle = normalizedBranchLineStyle(branch)
        modelName = string(branch.modelName);
        if modelName == "mRLFEElasticRealK"
            lineStyle = ':';
        elseif modelName == "mRLFEHanViscoRealK"
            lineStyle = '-.';
        else
            lineStyle = '-';
        end
    end

    function colorValue = normalizedBranchColor(branch)
        modelName = string(branch.modelName);
        branchName = string(branch.branchName);
        if modelName == "AcoustoelasticIOPHGO"
            colorValue = colors.AE;
        elseif branchName == "A0" || branchName == "A0Like"
            if startsWith(modelName, "mRLFE")
                colorValue = colors.HanA0;
            else
                colorValue = colors.A0;
            end
        else
            if startsWith(modelName, "mRLFE")
                colorValue = colors.HanS0;
            else
                colorValue = colors.S0;
            end
        end
    end

    function applyAxisLimits()
        if plotControls.autoAxes.Value
            xlim(ax, 'auto');
            ylim(ax, 'auto');
        else
            if plotControls.xmax.Value > plotControls.xmin.Value
                xlim(ax, [plotControls.xmin.Value plotControls.xmax.Value]);
            end
            if plotControls.ymax.Value > plotControls.ymin.Value
                ylim(ax, [plotControls.ymin.Value plotControls.ymax.Value]);
            end
        end
    end

    function didPlot = plotMode(mode, lineStyle, displayName, colorValue, xSel)
        x = getModeX(mode,getGridData(lastResults),xSel); y = mode.Cp;
        plot(ax, x, y, lineStyle, 'LineWidth', 2, 'Color', colorValue, 'DisplayName', displayName);
        didPlot = 1;
    end

    function didPlot = plotMRLFEBranch(modelName, branchName, lineStyle, displayName, colorValue, xSel)
        didPlot = 0;
        if isfield(lastResults, 'models') && isfield(lastResults.models, modelName) && isfield(lastResults.models.(modelName).branches, branchName)
            mode = lastResults.models.(modelName).branches.(branchName);
            validMask = getModePlotMask(mode); x = getModeX(mode,getGridData(lastResults),xSel); y = mode.Cp;
            x(~validMask) = nan; y(~validMask) = nan;
            if any(isfinite(y))
                plot(ax, x, y, lineStyle, 'LineWidth', 2, 'Color', colorValue, 'DisplayName', displayName);
                didPlot = 1;
            end
        end
    end

    function updateLabels()
        if isempty(lastResults) || isempty(lastOptions), return; end
        if getOptionValue(lastOptions, 'computeAcoustoelasticIOPHGO', false)
            updateAcoustoelasticLabels();
            return;
        end

        if isfield(lastResults, 'material') && isfield(lastResults, 'geometry')
            m = lastResults.material; thickness = lastResults.geometry.thickness; halfThickness = thickness/2;
            materialInfo.Text = sprintf('E %.4g kPa | nu %.5f | CL %.2f m/s | CT %.2f m/s\nthick %.4g m | half %.4g m', m.E/1e3, m.nu, m.CL, m.CT, thickness, halfThickness);
        end
        statusLines = {sprintf('%s | N=%d', string(lastOptions.robustness), numel(getGridData(lastResults).frequency))};
        rlLine = buildRLStatusLine(); if strlength(rlLine) > 0, statusLines{end+1} = char(rlLine); end %#ok<AGROW>
        elasticLine = buildMRLFEStatusLine('mRLFEElasticRealK', 'elastic'); if strlength(elasticLine) > 0, statusLines{end+1} = char(elasticLine); end %#ok<AGROW>
        hanLine = buildMRLFEStatusLine('mRLFEHanViscoRealK', 'Han'); if strlength(hanLine) > 0, statusLines{end+1} = char(hanLine); end %#ok<AGROW>
        if inputsAreDirty, statusLines{end+1} = 'inputs changed'; end %#ok<AGROW>
        setStatusText(statusLines);
    end

    function updateAcoustoelasticLabels()
        aeParams = lastGuiResult.metadata.params;
        materialInfo.Text = sprintf('AE IOP/HGO | mu %.4g kPa | rho %.4g kg/m^3 | h %.4g mm\nIOP %.4g mmHg | R %.4g mm | k1 %.4g kPa | k2 %.4g', ...
            aeParams.mu/1e3, aeParams.rho, aeParams.thickness*1e3, aeParams.IOP/133.322, aeParams.R*1e3, aeParams.k1/1e3, aeParams.k2);
        statusLines = {sprintf('AE IOP/HGO | atlasA0 | N=%d', numel(aeParams.frequency))};
        if isfield(lastResults, 'validCp')
            statusLines{end+1} = sprintf('Cp valid %d/%d', nnz(lastResults.validCp), numel(lastResults.validCp)); %#ok<AGROW>
        end
        if isfield(lastResults, 'reliability') && isfield(lastResults.reliability, 'LastValidFrequency_kHz')
            statusLines{end+1} = sprintf('last valid %.3f kHz', lastResults.reliability.LastValidFrequency_kHz); %#ok<AGROW>
        end
        if inputsAreDirty, statusLines{end+1} = 'inputs changed'; end %#ok<AGROW>
        setStatusText(statusLines);
    end

    function line = buildRLStatusLine()
        parts = strings(0);
        if isfield(lastResults, 'modes')
            if isfield(lastResults.modes,'A0'), a0 = lastResults.modes.A0; parts(end+1) = sprintf('A0 %d/%d', sum(a0.valid), numel(a0.valid)); end %#ok<AGROW>
            if isfield(lastResults.modes,'S0'), s0 = lastResults.modes.S0; parts(end+1) = sprintf('S0 %d/%d', sum(s0.valid), numel(s0.valid)); end %#ok<AGROW>
        end
        line = strjoin(parts, ' | ');
    end

    function line = buildMRLFEStatusLine(modelName, label)
        line = "";
        if isfield(lastResults, 'models') && isfield(lastResults.models, modelName)
            d = lastResults.models.(modelName).diagnostics; parts = strings(0);
            if isfield(d.summary, 'A0Like'), item = d.summary.A0Like; parts(end+1) = sprintf('A0L %d/%d', item.validCpPoints, item.totalPoints); end %#ok<AGROW>
            if isfield(d.summary, 'S0Like'), item = d.summary.S0Like; parts(end+1) = sprintf('S0L %d/%d', item.validCpPoints, item.totalPoints); end %#ok<AGROW>
            if ~isempty(parts), line = sprintf('%s: %s | %.1fs', label, strjoin(parts, ', '), d.elapsedSeconds); end
        end
    end

    function setStatusText(lines)
        if ischar(lines) || isstring(lines), statusBox.Value = cellstr(lines); else, statusBox.Value = lines; end
    end

    function onShowDiagnostics()
        if isempty(lastResults) || isempty(lastOptions), uialert(fig, 'No diagnostics are available yet.', 'Diagnostics'); return; end
        dfig = uifigure('Name','Solver diagnostics','Position',[180 180 680 600]);
        dg = uigridlayout(dfig, [1 1]); dg.Padding = [10 10 10 10];
        uitextarea(dg, 'Value', buildDiagnosticsText(), 'Editable', 'off', 'FontName', 'Consolas', 'FontSize', 11);
    end

    function txt = buildDiagnosticsText()
        if getOptionValue(lastOptions, 'computeAcoustoelasticIOPHGO', false)
            txt = buildAcoustoelasticDiagnosticsText();
            return;
        end

        lines = {}; m = lastResults.material;
        lines{end+1} = 'Material'; %#ok<AGROW>
        lines{end+1} = sprintf('  E        = %.6g Pa', m.E); %#ok<AGROW>
        lines{end+1} = sprintf('  nu       = %.6g', m.nu); %#ok<AGROW>
        lines{end+1} = sprintf('  lambda   = %.6g Pa', m.lambda); %#ok<AGROW>
        lines{end+1} = sprintf('  mu       = %.6g Pa', m.mu); %#ok<AGROW>
        lines{end+1} = sprintf('  CL       = %.6g m/s', m.CL); %#ok<AGROW>
        lines{end+1} = sprintf('  CT       = %.6g m/s', m.CT); %#ok<AGROW>
        lines{end+1} = ''; %#ok<AGROW>
        gridData = getGridData(lastResults);
        lines{end+1} = 'Grid'; %#ok<AGROW>
        lines{end+1} = sprintf('  frequency points = %d', numel(gridData.frequency)); %#ok<AGROW>
        lines{end+1} = sprintf('  fmin/fmax        = %.6g / %.6g Hz', min(gridData.frequency), max(gridData.frequency)); %#ok<AGROW>
        lines{end+1} = ''; %#ok<AGROW>
        if isfield(lastResults, 'modes')
            if isfield(lastResults.modes,'A0'), lines = appendModeDiagnostics(lines, 'A0', lastResults.modes.A0); end
            if isfield(lastResults.modes,'S0'), lines = appendModeDiagnostics(lines, 'S0', lastResults.modes.S0); end
        end
        lines = appendMRLFEDiagnostics(lines, 'mRLFEElasticRealK');
        lines = appendMRLFEDiagnostics(lines, 'mRLFEHanViscoRealK');
        txt = lines(:);
    end

    function txt = buildAcoustoelasticDiagnosticsText()
        lines = {};
        p = lastGuiResult.metadata.params;
        lines{end+1} = 'AE IOP/HGO'; %#ok<AGROW>
        lines{end+1} = sprintf('  IOP      = %.6g Pa', p.IOP); %#ok<AGROW>
        lines{end+1} = sprintf('  R        = %.6g m', p.R); %#ok<AGROW>
        lines{end+1} = sprintf('  h        = %.6g m', p.thickness); %#ok<AGROW>
        lines{end+1} = sprintf('  mu       = %.6g Pa', p.mu); %#ok<AGROW>
        lines{end+1} = sprintf('  k1       = %.6g Pa', p.k1); %#ok<AGROW>
        lines{end+1} = sprintf('  k2       = %.6g', p.k2); %#ok<AGROW>
        lines{end+1} = sprintf('  rho      = %.6g kg/m^3', p.rho); %#ok<AGROW>
        lines{end+1} = sprintf('  rhoF     = %.6g kg/m^3', p.rhoF); %#ok<AGROW>
        lines{end+1} = ''; %#ok<AGROW>
        lines{end+1} = 'Grid'; %#ok<AGROW>
        lines{end+1} = sprintf('  frequency points = %d', numel(p.frequency)); %#ok<AGROW>
        lines{end+1} = sprintf('  fmin/fmax        = %.6g / %.6g Hz', min(p.frequency), max(p.frequency)); %#ok<AGROW>
        if isfield(lastResults, 'validCp')
            lines{end+1} = sprintf('  Cp valid         = %d / %d', nnz(lastResults.validCp), numel(lastResults.validCp)); %#ok<AGROW>
        end
        if isfield(lastResults, 'reliability')
            lines{end+1} = ''; %#ok<AGROW>
            lines{end+1} = 'Reliability'; %#ok<AGROW>
            r = lastResults.reliability;
            fields = fieldnames(r);
            for i = 1:numel(fields)
                v = r.(fields{i});
                if isnumeric(v) || islogical(v) || isstring(v) || ischar(v)
                    lines{end+1} = sprintf('  %s = %s', fields{i}, string(v)); %#ok<AGROW>
                end
            end
        end
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
                lines{end+1} = sprintf('  %s: Cp valid %d/%d, Cp %.6g..%.6g m/s, max R %.3e', branchNames{i}, item.validCpPoints, item.totalPoints, item.minCp, item.maxCp, item.maxResidual); %#ok<AGROW>
            end
            lines{end+1} = ''; %#ok<AGROW>
        end
    end

    function lines = appendModeDiagnostics(lines, name, mode)
        validCp = mode.valid & isfinite(mode.Cp);
        lines{end+1} = name; %#ok<AGROW>
        lines{end+1} = sprintf('  valid    = %d / %d', sum(mode.valid), numel(mode.valid)); %#ok<AGROW>
        if any(validCp), lines{end+1} = sprintf('  Cp range = %.6g .. %.6g m/s', min(mode.Cp(validCp)), max(mode.Cp(validCp))); end %#ok<AGROW>
        lines{end+1} = sprintf('  max R    = %.3e', maxFinite(mode.residual)); %#ok<AGROW>
        lines{end+1} = ''; %#ok<AGROW>
    end

    function onExport()
        if isempty(lastResults), uialert(fig,'No results to export.','Export error'); return; end
        LambResults = lastResults; %#ok<NASGU>
        assignin('base','LambResults',LambResults);
        if ~isempty(lastGuiResult)
            GuiResults = lastGuiResult; %#ok<NASGU>
            GuiBranchTables = guiNormalizedBranchesToTables(lastGuiResult); %#ok<NASGU>
            assignin('base','GuiResults',GuiResults);
            assignin('base','GuiBranchTables',GuiBranchTables);
        end
        if getOptionValue(lastOptions, 'computeAcoustoelasticIOPHGO', false)
            assignin('base', 'AcoustoelasticIOPHGOResults', lastResults);
        end
        if isfield(lastResults, 'modes')
            if isfield(lastResults.modes,'A0'), assignin('base','A0_table',modeToTable(lastResults.modes.A0)); end
            if isfield(lastResults.modes,'S0') && any(isfinite(lastResults.modes.S0.Cp)), assignin('base','S0_table',modeToTable(lastResults.modes.S0)); end
        end
        if isfield(lastResults, 'approximations'), assignin('base', 'ApproximationResults', lastResults.approximations); end
        if isfield(lastResults, 'models')
            if isfield(lastResults.models, 'mRLFEElasticRealK'), assignin('base', 'MRLFEElasticRealKResults', lastResults.models.mRLFEElasticRealK); end
            if isfield(lastResults.models, 'mRLFEHanViscoRealK'), assignin('base', 'MRLFEHanViscoRealKResults', lastResults.models.mRLFEHanViscoRealK); end
            if isfield(lastResults.models, 'mRLFE'), assignin('base', 'MRLFEResults', lastResults.models.mRLFE); end
        end
        setStatusText({'Status: exported to workspace.'});
    end
end

function txt = onOff(flag)
if flag, txt = 'on'; else, txt = 'off'; end
end

function gridData = getGridData(results)
if isfield(results, 'grid')
    gridData = results.grid;
elseif isfield(results, 'frequency')
    gridData = struct();
    gridData.frequency = results.frequency(:);
    gridData.omega = 2*pi*gridData.frequency;
else
    gridData = struct('frequency', [], 'omega', []);
end
end

function x = getModeX(mode, gridData, xSel)
switch xSel
    case "frequency"
        if isfield(mode,'frequency'), x = mode.frequency; else, x = gridData.frequency; end
    case "angularFrequency"
        if isfield(mode,'omega'), x = mode.omega; else, x = gridData.omega; end
    case "wavenumber"
        if isfield(mode, 'kReal'), x = mode.kReal; elseif isfield(mode, 'k'), x = real(mode.k); else, x = nan(size(mode.Cp)); end
    case "kThickness"
        if isfield(mode, 'kThickness'), x = mode.kThickness; else, x = nan(size(mode.Cp)); end
    otherwise
        x = gridData.frequency;
end
end

function mask = getModePlotMask(mode)
if isfield(mode, 'validCp')
    mask = mode.validCp;
elseif isfield(mode, 'valid')
    mask = mode.valid;
else
    mask = isfinite(mode.Cp);
end
mask = mask & isfinite(mode.Cp);
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
vars = {mode.frequency(:), mode.omega(:), mode.Cp(:), mode.k(:), mode.kThickness(:), mode.residual(:), mode.valid(:)};
names = {'Frequency_Hz','Omega_rad_s','Cp','k','kThickness','Residual','Valid'};
if isfield(mode, 'kReal'), vars{end+1} = mode.kReal(:); names{end+1} = 'kReal'; end %#ok<AGROW>
if isfield(mode, 'validCp'), vars{end+1} = mode.validCp(:); names{end+1} = 'ValidCp'; end %#ok<AGROW>
out = table(vars{:}, 'VariableNames', names);
end

function value = maxFinite(x)
mask = isfinite(x);
if any(mask), value = max(x(mask)); else, value = nan; end
end
