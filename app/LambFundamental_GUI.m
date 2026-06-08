function LambFundamental_GUI
% Compact GUI for fundamental Lamb modes using the modular backend.

params0 = defaultParams();
opts0 = defaultOptions("Balanced");
lastResults = [];
lastOptions = [];
lastParams = [];
lastComputeCacheMessage = "";
inputsAreDirty = false;
colors.A0 = [0.0000 0.4470 0.7410];
colors.S0 = [1.0000 0.0000 0.0000];
colors.HanA0 = [0.0000 0.4470 0.7410];
colors.HanS0 = [1.0000 0.0000 0.0000];

fig = uifigure('Name','Fundamental Lamb Wave Phase Velocity Calculator','Position',[80 80 1460 860]);
root = uigridlayout(fig,[1 2]);
root.ColumnWidth = {500,'1x'};

left = uipanel(root,'Title','Controls');
left.Layout.Column = 1;
leftGrid = uigridlayout(left,[3 1]);
leftGrid.RowHeight = {'1x',265,255};
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
rg.RowHeight = {30,42,'1x',28};
rg.Padding = [8 6 8 6];
rg.RowSpacing = 4;
buttonGrid = uigridlayout(rg,[1 2]);
buttonGrid.Layout.Row = 1;
buttonGrid.ColumnWidth = {'1x','1x'};
buttonGrid.Padding = [0 0 0 0];
buttonGrid.ColumnSpacing = 6;
uibutton(buttonGrid,'Text','Compute selected modes','ButtonPushedFcn',@(~,~)onCompute());
uibutton(buttonGrid,'Text','Export results','ButtonPushedFcn',@(~,~)onExport());
materialInfo = uilabel(rg,'Text','Material info will appear here.','WordWrap','on','FontSize',9,'VerticalAlignment','top');
statusBox = uitextarea(rg,'Value',{'Status: ready.'},'Editable','off','FontName','Consolas','FontSize',9);
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

            lastComputeCacheMessage = "";
            if canReuseCompleteResults(params, options)
                lastComputeCacheMessage = "cache: reused previous results";
            elseif canReuseElasticForHan(params, options)
                lastResults = computeHanWithCachedElastic(lastResults, options);
                lastComputeCacheMessage = "cache: reused selected elastic mRLFE branch(es)";
            elseif canReuseBaseForMRLFE(params, options)
                lastResults = computeMRLFEWithCachedBase(lastResults, options);
                lastComputeCacheMessage = "cache: reused selected Rayleigh-Lamb seed(s)";
            else
                lastResults = computeFundamentalLambModes(params, options);
            end

            lastOptions = options;
            lastParams = params;
            inputsAreDirty = false;
            plotControls.showA0.Value = isfield(lastResults.modes,'A0');
            plotControls.showS0.Value = isfield(lastResults.modes,'S0') && any(isfinite(lastResults.modes.S0.Cp));
            updatePlot();
            updateLabels();
        catch ME
            setStatusText({['Status: error: ', ME.message]});
            uialert(fig, ME.message, 'Compute error');
        end
    end

    function options = readOptionsFromGui()
        options = defaultOptions(string(advanced.robustness.Value));
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
        mrlfeParams.etaS = modelControls.mrlfe.etaS.Value;
        mrlfeParams.etaL = 0;
        mrlfeParams.useComplexLambda = false;
    end

    function tf = canReuseCompleteResults(params, options)
        tf = false;
        if isempty(lastResults) || isempty(lastOptions) || isempty(lastParams)
            return;
        end
        if ~sameBaseInputs(params, lastParams, options, lastOptions)
            return;
        end
        if ~sameRequestedModels(options, lastOptions)
            return;
        end
        if ~sameFullMRLFEInputs(options, lastOptions)
            return;
        end
        tf = hasRequestedResults(lastResults, options);
    end

    function tf = canReuseElasticForHan(params, options)
        tf = false;
        if isempty(lastResults) || isempty(lastOptions) || isempty(lastParams)
            return;
        end
        if ~options.computeMRLFEHanViscoRealK
            return;
        end
        if ~isfield(lastResults, 'models') || ~isfield(lastResults.models, 'mRLFEElasticRealK')
            return;
        end
        if ~sameBaseInputs(params, lastParams, options, lastOptions)
            return;
        end
        if ~sameElasticMRLFEInputs(options, lastOptions)
            return;
        end
        tf = hasRequestedMRLFEBranches(lastResults.models.mRLFEElasticRealK, options);
    end

    function tf = canReuseBaseForMRLFE(params, options)
        tf = false;
        if isempty(lastResults) || isempty(lastOptions) || isempty(lastParams)
            return;
        end
        if ~(options.computeMRLFERealK || options.computeMRLFEHanViscoRealK)
            return;
        end
        if ~sameBaseInputs(params, lastParams, options, lastOptions)
            return;
        end
        tf = true;
        if options.mrlfeComputeA0Like
            tf = tf && isfield(lastResults.modes, 'A0');
        end
        if options.mrlfeComputeS0Like
            tf = tf && isfield(lastResults.modes, 'S0');
        end
    end

    function results = computeMRLFEWithCachedBase(cachedResults, options)
        results = cachedResults;
        results.models = struct();
        mrlfeParams = readMRLFEParamsFromGui();

        elasticParams = mrlfeParams;
        elasticParams.solveComplexK = false;
        elasticParams.etaS = 0;
        elasticParams.etaL = 0;
        elasticParams.useComplexLambda = false;
        elasticOptions = makeElasticRealKOptionsForGUI(options);
        elasticResult = computeMRLFE(results.grid.frequency, results.material, results.geometry, ...
            results.modes, elasticParams, elasticOptions);

        if options.computeMRLFERealK
            results.models.mRLFEElasticRealK = elasticResult;
            results.models.mRLFERealK = results.models.mRLFEElasticRealK;
        end

        if options.computeMRLFEHanViscoRealK
            hanParams = mrlfeParams;
            hanParams.solveComplexK = false;
            hanParams.etaL = 0;
            hanParams.useComplexLambda = false;
            hanOptions = makeHanRealKOptionsForGUI(options);
            results.models.mRLFEHanViscoRealK = computeMRLFE(results.grid.frequency, results.material, ...
                results.geometry, elasticResult.branches, hanParams, hanOptions);
        end
        results = updateModelAliases(results);
    end

    function results = computeHanWithCachedElastic(cachedResults, options)
        results = cachedResults;
        elasticSeed = cachedResults.models.mRLFEElasticRealK;
        mrlfeParams = readMRLFEParamsFromGui();
        mrlfeParams.solveComplexK = false;
        mrlfeParams.etaL = 0;
        mrlfeParams.useComplexLambda = false;
        hanOptions = makeHanRealKOptionsForGUI(options);
        results.models.mRLFEHanViscoRealK = computeMRLFE(results.grid.frequency, results.material, ...
            results.geometry, elasticSeed.branches, mrlfeParams, hanOptions);
        if ~options.computeMRLFERealK && isfield(results.models, 'mRLFEElasticRealK')
            results.models = rmfield(results.models, 'mRLFEElasticRealK');
        end
        if isfield(results.models, 'mRLFERealK')
            results.models = rmfield(results.models, 'mRLFERealK');
        end
        results = updateModelAliases(results);
    end

    function results = updateModelAliases(results)
        if isfield(results.models, 'mRLFE')
            results.models = rmfield(results.models, 'mRLFE');
        end
        if isfield(results.models, 'mRLFEElasticRealK')
            results.models.mRLFE = results.models.mRLFEElasticRealK;
        elseif isfield(results.models, 'mRLFEHanViscoRealK')
            results.models.mRLFE = results.models.mRLFEHanViscoRealK;
        end
    end

    function elasticOptions = makeElasticRealKOptionsForGUI(options)
        elasticOptions = options;
        elasticOptions.mrlfeA0UseDPTracker = true;
        elasticOptions.mrlfeRealKAnchorToSeed = true;
        elasticOptions.mrlfeRealKHardReferenceWindow = true;
        elasticOptions.mrlfeRealKScoreMode = "modal";
        elasticOptions.mrlfeRealKRequireLocalMinimum = true;
        elasticOptions.mrlfeRealKReferenceWeight = 80.0;
        elasticOptions.mrlfeRealKPredictionWeight = 4.0;
        elasticOptions.mrlfeRealKMaxRelativeKDrift = 0.30;
        elasticOptions.mrlfeRealKValidationMaxRelativeKDrift = 0.35;
        elasticOptions.mrlfeRealKValidationMaxRelativeCpDrift = 0.35;
        elasticOptions.mrlfeResidualTolerance = max(getOptionValue(options, 'mrlfeResidualTolerance', 1e-4), 1e-3);
    end

    function hanOptions = makeHanRealKOptionsForGUI(options)
        hanOptions = options;
        hanOptions.mrlfeA0UseDPTracker = false;
        hanOptions.mrlfeRealKAnchorToSeed = true;
        hanOptions.mrlfeRealKHardReferenceWindow = false;
        hanOptions.mrlfeRealKScoreMode = "modal";
        hanOptions.mrlfeRealKRequireLocalMinimum = true;
        hanOptions.mrlfeRealKUseModalCpWindow = getOptionValue(options, 'mrlfeHanUseModalLocalTracker', true);
        hanOptions.mrlfeRealKStopAtFirstMissingModalMinimum = getOptionValue(options, 'mrlfeRealKStopAtFirstMissingModalMinimum', true);
        hanOptions.mrlfeRealKReferenceWeight = 120.0;
        hanOptions.mrlfeRealKPredictionWeight = 6.0;
        hanOptions.mrlfeRealKPreviousCpWeight = getOptionValue(options, 'mrlfeHanPreviousCpWeight', 80.0);
        hanOptions.mrlfeRealKPreviousKWeight = getOptionValue(options, 'mrlfeHanPreviousKWeight', 0.0);
        hanOptions.mrlfeRealKPreviousCpMaxRelativeJump = getOptionValue(options, 'mrlfeHanPreviousCpMaxRelativeJump', inf);
        hanOptions.mrlfeRealKMaxRelativeKDrift = inf;
        hanOptions.mrlfeRealKValidationMaxRelativeKDrift = inf;
        hanOptions.mrlfeRealKValidationMaxRelativeCpDrift = inf;
        hanOptions.mrlfeResidualTolerance = max(getOptionValue(options, 'mrlfeResidualTolerance', 1e-4), 1e-3);
    end

    function tf = sameBaseInputs(paramsA, paramsB, optionsA, optionsB)
        tf = string(paramsA.modelType) == string(paramsB.modelType) && ...
            sameNumber(paramsA.rho, paramsB.rho) && sameNumber(paramsA.E, paramsB.E) && ...
            sameNumber(paramsA.nu, paramsB.nu) && sameNumber(paramsA.CL, paramsB.CL) && ...
            sameNumber(paramsA.lambda, paramsB.lambda) && sameNumber(paramsA.mu, paramsB.mu) && ...
            sameNumber(paramsA.thickness, paramsB.thickness) && sameNumber(paramsA.fmin, paramsB.fmin) && ...
            sameNumber(paramsA.fmax, paramsB.fmax) && string(paramsA.frequencySpacing) == string(paramsB.frequencySpacing) && ...
            string(paramsA.numFrequencyPoints) == string(paramsB.numFrequencyPoints) && string(optionsA.robustness) == string(optionsB.robustness);
    end

    function tf = sameRequestedModels(optionsA, optionsB)
        tf = logical(optionsA.computeA0) == logical(optionsB.computeA0) && ...
            logical(optionsA.computeS0) == logical(optionsB.computeS0) && ...
            logical(optionsA.computeMRLFERealK) == logical(optionsB.computeMRLFERealK) && ...
            logical(optionsA.computeMRLFEHanViscoRealK) == logical(optionsB.computeMRLFEHanViscoRealK) && ...
            logical(optionsA.mrlfeComputeA0Like) == logical(getOptionValue(optionsB, 'mrlfeComputeA0Like', true)) && ...
            logical(optionsA.mrlfeComputeS0Like) == logical(getOptionValue(optionsB, 'mrlfeComputeS0Like', true));
    end

    function tf = sameElasticMRLFEInputs(optionsA, optionsB)
        if ~isfield(optionsA, 'mrlfeParams') || ~isfield(optionsB, 'mrlfeParams')
            tf = false;
            return;
        end
        a = optionsA.mrlfeParams;
        b = optionsB.mrlfeParams;
        tf = sameNumber(a.fluidDensity, b.fluidDensity) && sameNumber(a.fluidSoundSpeed, b.fluidSoundSpeed);
    end

    function tf = sameFullMRLFEInputs(optionsA, optionsB)
        if ~(optionsA.computeMRLFERealK || optionsA.computeMRLFEHanViscoRealK || optionsB.computeMRLFERealK || optionsB.computeMRLFEHanViscoRealK)
            tf = true;
            return;
        end
        if ~sameElasticMRLFEInputs(optionsA, optionsB)
            tf = false;
            return;
        end
        tf = sameNumber(optionsA.mrlfeParams.etaS, optionsB.mrlfeParams.etaS);
    end

    function tf = hasRequestedResults(results, options)
        tf = true;
        if options.computeA0, tf = tf && isfield(results.modes, 'A0'); end
        if options.computeS0, tf = tf && isfield(results.modes, 'S0'); end
        if options.computeMRLFERealK
            tf = tf && isfield(results.models, 'mRLFEElasticRealK') && hasRequestedMRLFEBranches(results.models.mRLFEElasticRealK, options);
        end
        if options.computeMRLFEHanViscoRealK
            tf = tf && isfield(results.models, 'mRLFEHanViscoRealK') && hasRequestedMRLFEBranches(results.models.mRLFEHanViscoRealK, options);
        end
    end

    function tf = hasRequestedMRLFEBranches(modelResult, options)
        tf = isfield(modelResult, 'branches');
        if options.mrlfeComputeA0Like
            tf = tf && isfield(modelResult.branches, 'A0Like');
        end
        if options.mrlfeComputeS0Like
            tf = tf && isfield(modelResult.branches, 'S0Like');
        end
    end

    function tf = sameNumber(a, b)
        scale = max([1, abs(double(a)), abs(double(b))]);
        tf = isfinite(double(a)) && isfinite(double(b)) && abs(double(a) - double(b)) <= 1e-12 * scale;
    end

    function value = getOptionValue(optionsStruct, fieldName, defaultValue)
        if isfield(optionsStruct, fieldName)
            value = optionsStruct.(fieldName);
        else
            value = defaultValue;
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
        if plotControls.showA0.Value && isfield(lastResults.modes,'A0')
            plotCount = plotCount + plotMode(lastResults.modes.A0, '-', 'A0', colors.A0, xSel);
        end
        if plotControls.showS0.Value && isfield(lastResults.modes,'S0') && any(isfinite(lastResults.modes.S0.Cp))
            plotCount = plotCount + plotMode(lastResults.modes.S0, '-', 'S0', colors.S0, xSel);
        end
        if plotControls.showMRLFEA0.Value
            plotCount = plotCount + plotMRLFEBranch('mRLFEElasticRealK', 'A0Like', ':', 'mRLFE elastic A0-like', colors.HanA0, xSel);
            plotCount = plotCount + plotMRLFEBranch('mRLFEHanViscoRealK', 'A0Like', '-.', 'mRLFE Han visco A0-like', colors.HanA0, xSel);
        end
        if plotControls.showMRLFES0.Value
            plotCount = plotCount + plotMRLFEBranch('mRLFEElasticRealK', 'S0Like', ':', 'mRLFE elastic S0-like', colors.HanS0, xSel);
            plotCount = plotCount + plotMRLFEBranch('mRLFEHanViscoRealK', 'S0Like', '-.', 'mRLFE Han visco S0-like', colors.HanS0, xSel);
        end
        if plotControls.showA0Thin.Value && isfield(lastResults, 'approximations') && isfield(lastResults.approximations, 'A0ThinPlate')
            plotCount = plotCount + plotMode(lastResults.approximations.A0ThinPlate, '--', 'A0 thin plate', colors.A0, xSel);
        end
        if plotControls.showS0Ext.Value && isfield(lastResults, 'approximations') && isfield(lastResults.approximations, 'S0Extensional')
            plotCount = plotCount + plotMode(lastResults.approximations.S0Extensional, '--', 'S0 extensional', colors.S0, xSel);
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

    function didPlot = plotMode(mode, lineStyle, displayName, colorValue, xSel)
        x = getModeX(mode,lastResults.grid,xSel); y = mode.Cp;
        plot(ax, x, y, lineStyle, 'LineWidth', 2, 'Color', colorValue, 'DisplayName', displayName);
        didPlot = 1;
    end

    function didPlot = plotMRLFEBranch(modelName, branchName, lineStyle, displayName, colorValue, xSel)
        didPlot = 0;
        if isfield(lastResults, 'models') && isfield(lastResults.models, modelName) && isfield(lastResults.models.(modelName).branches, branchName)
            mode = lastResults.models.(modelName).branches.(branchName);
            validMask = getModePlotMask(mode); x = getModeX(mode,lastResults.grid,xSel); y = mode.Cp;
            x(~validMask) = nan; y(~validMask) = nan;
            if any(isfinite(y))
                plot(ax, x, y, lineStyle, 'LineWidth', 2, 'Color', colorValue, 'DisplayName', displayName);
                didPlot = 1;
            end
        end
    end

    function updateLabels()
        if isempty(lastResults) || isempty(lastOptions), return; end
        m = lastResults.material; thickness = lastResults.geometry.thickness; halfThickness = thickness/2;
        materialInfo.Text = sprintf('E %.4g kPa | nu %.5f | CL %.2f m/s | CT %.2f m/s\nthick %.4g m | half %.4g m', m.E/1e3, m.nu, m.CL, m.CT, thickness, halfThickness);
        statusLines = {sprintf('%s | N=%d', string(lastOptions.robustness), numel(lastResults.grid.frequency))};
        if strlength(lastComputeCacheMessage) > 0, statusLines{end+1} = char(lastComputeCacheMessage); end %#ok<AGROW>
        rlLine = buildRLStatusLine(); if strlength(rlLine) > 0, statusLines{end+1} = char(rlLine); end %#ok<AGROW>
        elasticLine = buildMRLFEStatusLine('mRLFEElasticRealK', 'elastic'); if strlength(elasticLine) > 0, statusLines{end+1} = char(elasticLine); end %#ok<AGROW>
        hanLine = buildMRLFEStatusLine('mRLFEHanViscoRealK', 'Han'); if strlength(hanLine) > 0, statusLines{end+1} = char(hanLine); end %#ok<AGROW>
        if inputsAreDirty, statusLines{end+1} = 'inputs changed'; end %#ok<AGROW>
        setStatusText(statusLines);
    end

    function line = buildRLStatusLine()
        parts = strings(0);
        if isfield(lastResults.modes,'A0'), a0 = lastResults.modes.A0; parts(end+1) = sprintf('A0 %d/%d', sum(a0.valid), numel(a0.valid)); end %#ok<AGROW>
        if isfield(lastResults.modes,'S0'), s0 = lastResults.modes.S0; parts(end+1) = sprintf('S0 %d/%d', sum(s0.valid), numel(s0.valid)); end %#ok<AGROW>
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
        lines = {}; m = lastResults.material;
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
        if isfield(lastResults.modes,'A0'), lines = appendModeDiagnostics(lines, 'A0', lastResults.modes.A0); end
        if isfield(lastResults.modes,'S0'), lines = appendModeDiagnostics(lines, 'S0', lastResults.modes.S0); end
        lines = appendMRLFEDiagnostics(lines, 'mRLFEElasticRealK');
        lines = appendMRLFEDiagnostics(lines, 'mRLFEHanViscoRealK');
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
        if isfield(lastResults.modes,'A0'), assignin('base','A0_table',modeToTable(lastResults.modes.A0)); end
        if isfield(lastResults.modes,'S0') && any(isfinite(lastResults.modes.S0.Cp)), assignin('base','S0_table',modeToTable(lastResults.modes.S0)); end
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
