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
colors.MRLFEElasticA0 = [0.0000 0.4470 0.7410];
colors.MRLFEElasticS0 = [1.0000 0.0000 0.0000];
colors.MRLFEHanA0 = [0.4660 0.6740 0.1880];
colors.MRLFEHanS0 = [0.8500 0.3250 0.0980];
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
callbacks.onPrimaryMaterialChanged = @(~,~)onPrimaryMaterialChanged();
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
updateDerivedMaterialFields();
updateAxisFieldState();

    function onMaterialModelChanged()
        updateMaterialInputState();
        updateDerivedMaterialFields();
        markDirty();
    end

    function onPrimaryMaterialChanged()
        updateDerivedMaterialFields();
        markDirty();
    end

    function updateMaterialInputState()
        spOn = string(setup.model.Value) == "ShearPoisson";
        setup.nulabel.Enable = onOff(spOn); setup.nu.Enable = onOff(spOn);
        setup.lambdalabel.Enable = onOff(~spOn); setup.lambda.Enable = onOff(~spOn);
        setup.E.Enable = 'off';
        setup.K.Enable = 'off';
        setup.CT.Enable = 'off';
        setup.CL.Enable = 'off';
    end

    function updateDerivedMaterialFields()
        try
            rho = setup.rho.Value;
            mu = setup.mu.Value * 1e3;
            if string(setup.model.Value) == "ShearPoisson"
                elastic = elasticFromMuNu(mu, setup.nu.Value, rho);
                setup.lambda.Value = elastic.lambda / 1e6;
            else
                elastic = elasticFromLame(setup.lambda.Value * 1e6, mu, rho);
                setup.nu.Value = elastic.nu;
            end
            setup.E.Value = elastic.E / 1e3;
            setup.K.Value = elastic.K / 1e6;
            setup.CT.Value = elastic.CT;
            setup.CL.Value = elastic.CL;
        catch
            % Validation during compute reports invalid inputs.
        end
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
            options.acoustoelasticOptions = guiBuildAcoustoelasticIOPHGOOptions(options.robustness);
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
        params.mu = setup.mu.Value * 1e3;
        params.nu = setup.nu.Value;
        params.lambda = setup.lambda.Value * 1e6;
        params.thickness = setup.thickness.Value * 1e-3;
        params.fmin = setup.fmin.Value;
        params.fmax = setup.fmax.Value;
        params.numFrequencyPoints = "auto";
        params.frequencySpacing = "hybrid";

        material = rlComputeMaterial(params);
        params.E = material.E;
        params.K = material.K;
        params.CL = material.CL;
        params.CT = material.CT;
        params.nu = material.nu;
        params.lambda = material.lambda;
    end

    function mrlfeParams = readMRLFEParamsFromGui()
        mrlfeParams = defaultMRLFEParams();
        mrlfeParams.fluidDensity = modelControls.mrlfe.fluidDensity.Value;
        mrlfeParams.fluidSoundSpeed = modelControls.mrlfe.fluidSoundSpeed.Value;
        mrlfeParams.etaS = modelControls.mrlfe.etaS.Value;
        mrlfeParams.etaL = 0;
        mrlfeParams.useComplexLambda = false;
    end

    function [results, guiResult] = runModelRequestThroughAdapter(params, options)
        if getOptionValueLocal(options, 'computeAcoustoelasticIOPHGO', false)
            guiRequest = guiBuildAcoustoelasticIOPHGORequest(params, modelControls.ae, options.robustness);
            guiResult = guiRunAcoustoelasticIOPHGOModel(guiRequest);
            results = guiResult.metadata.rawResult;
            return;
        end

        guiRequest = struct();
        guiRequest.params = params;
        guiRequest.options = options;

        if isfield(options, 'mrlfeParams')
            guiRequest.mrlfeParams = options.mrlfeParams;
        end

        if options.computeMRLFERealK || options.computeMRLFEHanViscoRealK
            guiRequest.computeElastic = options.computeMRLFERealK || options.computeMRLFEHanViscoRealK;
            guiRequest.computeHan = options.computeMRLFEHanViscoRealK;
            guiResult = guiRunMRLFEModel(guiRequest);
            results = guiResult.metadata.rawResult;
        else
            guiResult = guiRunRayleighLambModel(guiRequest);
            results = guiResult.metadata.rawResult;
        end
    end

    function updatePlotCheckboxesFromResults()
        if isempty(lastResults)
            return;
        end
        if tryUpdatePlotCheckboxesFromNormalizedResults()
            return;
        end
        if isfield(lastResults,'modes')
            if isfield(lastResults.modes,'A0')
                plotControls.showA0.Value = true;
            end
            if isfield(lastResults.modes,'S0')
                plotControls.showS0.Value = true;
            end
        end
    end

    function updated = tryUpdatePlotCheckboxesFromNormalizedResults()
        updated = false;
        if isempty(lastGuiResult) || ~isfield(lastGuiResult, 'branches')
            return;
        end
        for i = 1:numel(lastGuiResult.branches)
            branch = lastGuiResult.branches(i);
            modelName = string(branch.modelName);
            branchName = string(branch.branchName);
            switch modelName
                case "RayleighLamb"
                    if branchName == "A0"
                        plotControls.showA0.Value = true;
                    elseif branchName == "S0"
                        plotControls.showS0.Value = true;
                    end
                    updated = true;
                case {"mRLFEElasticRealK", "mRLFERealK"}
                    if branchName == "A0Like"
                        plotControls.showMRLFEElasticA0.Value = true;
                    elseif branchName == "S0Like"
                        plotControls.showMRLFEElasticS0.Value = true;
                    end
                    updated = true;
                case "mRLFEHanViscoRealK"
                    if branchName == "A0Like"
                        plotControls.showMRLFEHanA0.Value = true;
                    elseif branchName == "S0Like"
                        plotControls.showMRLFEHanS0.Value = true;
                    end
                    updated = true;
                case "AcoustoelasticIOPHGO"
                    plotControls.showA0.Value = true;
                    updated = true;
            end
        end
    end

    function refreshPlotOnly()
        if isempty(lastResults)
            return;
        end
        updatePlot();
    end

    function updatePlot()
        if isempty(lastResults)
            return;
        end
        cla(ax);
        hold(ax,'on');
        plotted = false;
        if tryPlotNormalizedResults()
            plotted = true;
        elseif isfield(lastResults,'modes')
            if plotControls.showA0.Value && isfield(lastResults.modes,'A0')
                plotBranch(lastResults.modes.A0, colors.A0, 'A0');
                plotted = true;
            end
            if plotControls.showS0.Value && isfield(lastResults.modes,'S0')
                plotBranch(lastResults.modes.S0, colors.S0, 'S0');
                plotted = true;
            end
        end
        if ~plotted
            title(ax,'No valid branch selected');
        else
            title(ax,'Phase velocity Cp');
            legend(ax,'Location','best');
        end
        xlabel(ax,'frequency [Hz]');
        ylabel(ax,'Phase velocity Cp [m/s]');
        grid(ax,'on');
        hold(ax,'off');
        applyAxisLimits();
    end

    function plotted = tryPlotNormalizedResults()
        plotted = false;
        if isempty(lastGuiResult) || ~isfield(lastGuiResult, 'branches')
            return;
        end
        for i = 1:numel(lastGuiResult.branches)
            branch = lastGuiResult.branches(i);
            if ~shouldPlotNormalizedBranch(branch)
                continue;
            end
            plotData = guiGetNormalizedBranchPlotData(branch);
            frequency = plotData.x(:);
            Cp = plotData.y(:);
            valid = plotData.validMask(:) & isfinite(frequency) & isfinite(Cp);
            if isempty(frequency) || ~any(valid)
                continue;
            end
            plot(ax, frequency(valid), Cp(valid), '-', 'Color', normalizedBranchColor(branch), ...
                'LineWidth', 2.0, 'DisplayName', normalizedBranchDisplayName(branch));
            plotted = true;
        end
    end

    function tf = shouldPlotNormalizedBranch(branch)
        modelName = string(branch.modelName);
        branchName = string(branch.branchName);
        tf = false;
        switch modelName
            case "RayleighLamb"
                tf = (branchName == "A0" && plotControls.showA0.Value) || ...
                     (branchName == "S0" && plotControls.showS0.Value);
            case {"mRLFEElasticRealK", "mRLFERealK"}
                tf = (branchName == "A0Like" && plotControls.showMRLFEElasticA0.Value) || ...
                     (branchName == "S0Like" && plotControls.showMRLFEElasticS0.Value);
            case "mRLFEHanViscoRealK"
                tf = (branchName == "A0Like" && plotControls.showMRLFEHanA0.Value) || ...
                     (branchName == "S0Like" && plotControls.showMRLFEHanS0.Value);
            case "AcoustoelasticIOPHGO"
                tf = plotControls.showA0.Value;
        end
    end

    function name = normalizedBranchDisplayName(branch)
        modelName = string(branch.modelName);
        branchName = string(branch.branchName);
        switch modelName
            case "RayleighLamb"
                name = char(branchName);
            case {"mRLFEElasticRealK", "mRLFERealK"}
                name = ['mRLFE elastic ', char(formatMRLFEBranchName(branchName))];
            case "mRLFEHanViscoRealK"
                name = ['mRLFE viscoelastic ', char(formatMRLFEBranchName(branchName))];
            case "AcoustoelasticIOPHGO"
                name = 'AE IOP/HGO A0-like';
            otherwise
                name = [char(modelName), ' ', char(branchName)];
        end
    end

    function color = normalizedBranchColor(branch)
        modelName = string(branch.modelName);
        branchName = string(branch.branchName);
        switch modelName
            case "RayleighLamb"
                if branchName == "A0"
                    color = colors.A0;
                else
                    color = colors.S0;
                end
            case {"mRLFEElasticRealK", "mRLFERealK"}
                if branchName == "A0Like"
                    color = colors.MRLFEElasticA0;
                else
                    color = colors.MRLFEElasticS0;
                end
            case "mRLFEHanViscoRealK"
                if branchName == "A0Like"
                    color = colors.MRLFEHanA0;
                else
                    color = colors.MRLFEHanS0;
                end
            case "AcoustoelasticIOPHGO"
                color = colors.AE;
            otherwise
                color = [0 0 0];
        end
    end

    function txt = formatMRLFEBranchName(branchName)
        branchName = string(branchName);
        switch branchName
            case "A0Like"
                txt = "A0-like";
            case "S0Like"
                txt = "S0-like";
            otherwise
                txt = branchName;
        end
    end

    function plotBranch(branch, color, label)
        frequency = branch.frequency(:);
        Cp = branch.Cp(:);
        valid = isfinite(frequency) & isfinite(Cp);
        if isfield(branch,'validMask')
            valid = valid & branch.validMask(:);
        end
        if any(valid)
            plot(ax, frequency(valid), Cp(valid), '-', 'Color', color, 'LineWidth', 2.0, 'DisplayName', label);
        end
    end

    function updateLabels()
        if isempty(lastResults) || isempty(lastOptions)
            return;
        end
        if getOptionValueLocal(lastOptions, 'computeAcoustoelasticIOPHGO', false)
            updateAcoustoelasticLabels();
            return;
        end
        updateRayleighLambLabels();
    end

    function updateAcoustoelasticLabels()
        if isempty(lastResults)
            return;
        end
        r = lastResults;
        materialInfo.Text = sprintf('AE IOP/HGO | mu %.2f kPa | rho %.1f kg/m^3 | h %.3f mm\nIOP %.2f mmHg | R %.2f mm | k1 %.2f kPa | k2 %.2f', ...
            lastParams.mu/1e3, lastParams.rho, lastParams.thickness*1e3, ...
            modelControls.ae.IOP.Value, modelControls.ae.R.Value, modelControls.ae.k1.Value, modelControls.ae.k2.Value);
        validCount = nnz(r.validCp);
        totalCount = numel(r.Cp);
        statusLines = {sprintf('Status: AE IOP/HGO A0-like | N=%d', totalCount), ...
            sprintf('Cp valid %d/%d', validCount, totalCount)};
        if isfield(r, 'reliability') && isfield(r.reliability, 'LastValidFrequency_kHz') && isfinite(r.reliability.LastValidFrequency_kHz)
            statusLines{end+1} = sprintf('last valid %.3f kHz', r.reliability.LastValidFrequency_kHz);
        end
        if isfield(r, 'internalAtlasTracking') && isfield(r.internalAtlasTracking, 'Used') && r.internalAtlasTracking.Used
            statusLines{end+1} = sprintf('tracking grid %d pts', numel(r.trackingFrequency));
        end
        setStatusText(statusLines);
    end

    function updateRayleighLambLabels()
        geom = getGeometryData(lastResults);
        mat = getMaterialData(lastResults);
        gridData = getGridData(lastResults);
        if isempty(geom) || isempty(mat)
            materialInfo.Text = 'Material info unavailable.';
            setStatusText({'Status: computed.'});
            return;
        end
        materialInfo.Text = sprintf('rho %.1f kg/m^3 | 2h %.3f mm | mu %.2f kPa | nu %.5f | E %.2f kPa\nlambda_Lame %.2f MPa | K %.2f MPa | CL %.2f m/s | CT %.2f m/s', ...
            mat.rho, geom.thickness*1e3, mat.mu/1e3, mat.nu, mat.E/1e3, mat.lambda/1e6, mat.K/1e6, mat.CL, mat.CT);
        if ~isempty(gridData) && isfield(gridData,'frequency')
            status = {sprintf('Status: computed %d frequency points.', numel(gridData.frequency))};
        else
            status = {'Status: computed.'};
        end
        setStatusText(status);
    end

    function onShowDiagnostics()
        if isempty(lastResults)
            uialert(fig,'Compute first.','No results');
            return;
        end
        txt = buildDiagnosticsText();
        diagFig = uifigure('Name','Diagnostics','Position',[120 120 720 520]);
        ta = uitextarea(diagFig,'Value',cellstr(splitlines(txt)),'Editable','off','FontName','Consolas');
        ta.Position = [10 10 700 500];
    end

    function txt = buildDiagnosticsText()
        if getOptionValueLocal(lastOptions, 'computeAcoustoelasticIOPHGO', false)
            txt = buildAcoustoelasticDiagnosticsText();
            return;
        end
        txt = buildRayleighLambDiagnosticsText();
    end

    function txt = buildAcoustoelasticDiagnosticsText()
        r = lastResults;
        lines = strings(0,1);
        lines(end+1) = "AE IOP/HGO diagnostics";
        lines(end+1) = sprintf("IOP %.6g Pa", r.directParams.alpha*0 + modelControls.ae.IOP.Value*133.322);
        lines(end+1) = sprintf("R %.6g m", modelControls.ae.R.Value*1e-3);
        lines(end+1) = sprintf("h %.6g m", r.directParams.thickness);
        lines(end+1) = sprintf("mu %.6g Pa", lastParams.mu);
        lines(end+1) = sprintf("k1 %.6g Pa", modelControls.ae.k1.Value*1e3);
        lines(end+1) = sprintf("k2 %.6g", modelControls.ae.k2.Value);
        lines(end+1) = sprintf("rho %.6g kg/m^3", r.directParams.rho);
        lines(end+1) = sprintf("rhoF %.6g kg/m^3", r.directParams.rhoF);
        lines(end+1) = sprintf("frequency output points %d", numel(r.frequency));
        if isfield(r, 'internalAtlasTracking') && isfield(r.internalAtlasTracking, 'Used') && r.internalAtlasTracking.Used
            lines(end+1) = sprintf("frequency tracking points %d", numel(r.trackingFrequency));
        end
        lines(end+1) = sprintf("valid Cp %d/%d", nnz(r.validCp), numel(r.validCp));
        if isfield(r, 'reliability')
            names = fieldnames(r.reliability);
            for i = 1:numel(names)
                v = r.reliability.(names{i});
                if isnumeric(v) || islogical(v) || isstring(v) || ischar(v)
                    lines(end+1) = sprintf("%s: %s", names{i}, string(v));
                end
            end
        end
        txt = strjoin(lines, newline);
    end

    function txt = buildRayleighLambDiagnosticsText()
        lines = strings(0,1);
        lines(end+1) = "Rayleigh-Lamb / mRLFE diagnostics";
        if ~isempty(lastParams)
            lines(end+1) = sprintf("modelType %s", string(lastParams.modelType));
            lines(end+1) = sprintf("rho %.6g kg/m^3", lastParams.rho);
            lines(end+1) = sprintf("mu %.6g Pa", lastParams.mu);
            lines(end+1) = sprintf("nu %.6g", lastParams.nu);
            lines(end+1) = sprintf("E %.6g Pa", lastParams.E);
            lines(end+1) = sprintf("lambda_Lame %.6g Pa", lastParams.lambda);
            lines(end+1) = sprintf("K %.6g Pa", lastParams.K);
            lines(end+1) = sprintf("CL %.6g m/s", lastParams.CL);
            lines(end+1) = sprintf("CT %.6g m/s", lastParams.CT);
            lines(end+1) = sprintf("2h %.6g m", lastParams.thickness);
        end
        if isfield(lastResults, 'models')
            names = fieldnames(lastResults.models);
            lines(end+1) = sprintf("computed models: %s", strjoin(string(names), ", "));
        end
        txt = strjoin(lines, newline);
    end

    function onExport()
        if isempty(lastResults)
            uialert(fig,'Compute first.','No results');
            return;
        end
        defaultName = ['LambResults_', datestr(now,'yyyymmdd_HHMMSS'), '.mat'];
        [file,path] = uiputfile('*.mat','Save results',defaultName);
        if isequal(file,0)
            return;
        end
        LambResults = lastResults; %#ok<NASGU>
        GuiResults = []; %#ok<NASGU>
        GuiBranchTables = []; %#ok<NASGU>
        AcoustoelasticIOPHGOResults = []; %#ok<NASGU>
        if ~isempty(lastGuiResult)
            GuiResults = lastGuiResult; %#ok<NASGU>
            GuiBranchTables = guiNormalizedBranchesToTables(lastGuiResult.branches); %#ok<NASGU>
        end
        if getOptionValueLocal(lastOptions, 'computeAcoustoelasticIOPHGO', false)
            AcoustoelasticIOPHGOResults = lastResults; %#ok<NASGU>
        end
        save(fullfile(path,file),'LambResults','GuiResults','GuiBranchTables','AcoustoelasticIOPHGOResults','lastParams','lastOptions');
        setStatusText({['Status: saved ', fullfile(path,file)]});
    end

    function setStatusText(lines)
        statusBox.Value = lines(:);
    end

    function onAutoAxesChanged()
        updateAxisFieldState();
        refreshPlotOnly();
    end

    function updateAxisFieldState()
        isAuto = logical(plotControls.autoAxes.Value);
        enable = onOff(~isAuto);
        plotControls.xmin.Enable = enable; plotControls.xmax.Enable = enable;
        plotControls.ymin.Enable = enable; plotControls.ymax.Enable = enable;
    end

    function resetAxes()
        if ~isempty(lastResults)
            updatePlot();
        else
            axis(ax,'auto');
        end
    end

    function useCurrentAxes()
        xl = xlim(ax); yl = ylim(ax);
        plotControls.xmin.Value = xl(1); plotControls.xmax.Value = xl(2);
        plotControls.ymin.Value = yl(1); plotControls.ymax.Value = yl(2);
        plotControls.autoAxes.Value = false;
        updateAxisFieldState();
    end

    function applyAxisLimits()
        if logical(plotControls.autoAxes.Value)
            axis(ax,'auto');
            return;
        end
        if plotControls.xmax.Value > plotControls.xmin.Value
            xlim(ax,[plotControls.xmin.Value plotControls.xmax.Value]);
        end
        if plotControls.ymax.Value > plotControls.ymin.Value
            ylim(ax,[plotControls.ymin.Value plotControls.ymax.Value]);
        end
    end

    function value = getOptionValueLocal(s, name, defaultValue)
        if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
            value = s.(name);
        else
            value = defaultValue;
        end
    end
end

function y = onOff(tf)
if tf
    y = 'on';
else
    y = 'off';
end
end

function geom = getGeometryData(results)
if isfield(results,'geometry')
    geom = results.geometry;
else
    geom = [];
end
end

function mat = getMaterialData(results)
if isfield(results,'material')
    mat = results.material;
else
    mat = [];
end
end

function gridData = getGridData(results)
if isfield(results,'grid')
    gridData = results.grid;
else
    gridData = [];
end
end
