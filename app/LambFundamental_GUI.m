function LambFundamental_GUI
% Compact GUI for fundamental Lamb modes using the modular backend.

params0 = rlDefaultParams();
opts0 = rlDefaultOptions("Balanced");
lastResults = [];
lastGuiResult = [];
lastOptions = [];
lastParams = [];
lastPhysicalParameters = [];
inputsAreDirty = false;

colors.A0 = [0.0000 0.4470 0.7410];
colors.S0 = [1.0000 0.0000 0.0000];
colors.MRLFEA0 = [0.4660 0.6740 0.1880];
colors.MRLFES0 = [0.8500 0.3250 0.0980];
colors.AE = [0.4940 0.1840 0.5560];
colors.Approx = [0.2500 0.2500 0.2500];

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
        setup.nulabel.Enable = onOff(spOn);
        setup.nu.Enable = onOff(spOn);
        setup.lambdalabel.Enable = onOff(~spOn);
        setup.lambda.Enable = onOff(~spOn);
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
            % Compute-time validation reports invalid entries.
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
            options = readOptionsFromGui(params);
            [lastResults, lastGuiResult] = runModelRequestThroughAdapter(params, options);
            lastParams = params;
            lastOptions = options;
            lastPhysicalParameters = readPhysicalParametersFromGui(params, options);
            inputsAreDirty = false;
            updatePlotCheckboxesFromResults();
            updatePlot();
            updateLabels();
        catch ME
            setStatusText({['Status: error: ', ME.message]});
            uialert(fig, ME.message, 'Compute error');
        end
    end

    function options = readOptionsFromGui(params)
        [options, profileMetadata] = rlResolveExecutionProfile(string(advanced.robustness.Value), ...
            'DefaultProfile', "Balanced", ...
            'DefaultSource', "Main GUI default");
        options.executionProfileMetadata = profileMetadata;
        options.computeAcoustoelasticIOPHGO = logical(modelControls.ae.computeAtlasA0.Value);

        if options.computeAcoustoelasticIOPHGO
            options.computeA0 = false;
            options.computeS0 = false;
            options.runMRLFE = false;
            options.acoustoelasticOptions = guiBuildAcoustoelasticIOPHGOOptions(options.executionProfile);
            return;
        end

        options.computeA0 = logical(modelControls.rl.computeA0.Value);
        options.computeS0 = logical(modelControls.rl.computeS0.Value);
        options.runMRLFE = logical(modelControls.mrlfe.computeRealK.Value);
        requestedA0Like = logical(modelControls.mrlfe.computeA0Like.Value);
        requestedS0Like = logical(modelControls.mrlfe.computeS0Like.Value);
        options.mrlfeA0Policy = "physicalTail";

        if options.runMRLFE
            if ~requestedA0Like && ~requestedS0Like
                error('Select at least one mRLFE branch: A0-like or S0-like.');
            end
            branchName = "S0Like";
            if requestedA0Like
                branchName = "A0Like";
            end
            [mrlfeOptions, mrlfeMetadata] = mrlfeResolveExecutionProfile(branchName, ...
                advanced.robustness.Value, 'Surface', "main", ...
                'DefaultProfile', "Balanced", 'DefaultSource', "Main GUI default", ...
                'EtaS', modelControls.mrlfe.etaS.Value);
            mrlfeOptions.runMRLFE = true;
            mrlfeOptions.branchNames = [repmat("A0Like", 1, double(requestedA0Like)), ...
                repmat("S0Like", 1, double(requestedS0Like))];
            options = mrlfeOptions;
            options.executionProfileMetadata = mrlfeMetadata;
            options.mrlfeParams = readMRLFEParamsFromGui();
            if isfield(modelControls.mrlfe, 'a0Policy')
                options.mrlfeA0Policy = normalizeMrlfeA0Policy(string(modelControls.mrlfe.a0Policy.Value));
            end
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

    function policy = normalizeMrlfeA0Policy(policyIn)
        policy = string(policyIn);
        if policy ~= "physicalTail"
            policy = "physicalTail";
        end
    end

    function mrlfeParams = readMRLFEParamsFromGui()
        mrlfeParams = mrlfeDefaultInternalParameters();
        mrlfeParams.fluidDensity = modelControls.mrlfe.fluidDensity.Value;
        mrlfeParams.fluidSoundSpeed = modelControls.mrlfe.fluidSoundSpeed.Value;
        mrlfeParams.etaS = modelControls.mrlfe.etaS.Value;
        mrlfeParams.etaL = 0;
        mrlfeParams.useComplexLambda = false;
    end

    function physicalParameters = readPhysicalParametersFromGui(params, options)
        physicalParameters = struct();
        physicalParameters.modelType = string(params.modelType);
        physicalParameters.rho_kg_m3 = params.rho;
        physicalParameters.mu_Pa = params.mu;
        if string(params.modelType) == "ShearPoisson"
            physicalParameters.nu = params.nu;
        else
            physicalParameters.lambda_Lame_Pa = params.lambda;
        end
        physicalParameters.thickness_m = params.thickness;

        if getOptionValueLocal(options, 'computeAcoustoelasticIOPHGO', false)
            physicalParameters.IOP_mmHg = modelControls.ae.IOP.Value;
            physicalParameters.radius_mm = modelControls.ae.R.Value;
            physicalParameters.k1_Pa = modelControls.ae.k1.Value * 1e3;
            physicalParameters.k2 = modelControls.ae.k2.Value;
            physicalParameters.fluidDensity_kg_m3 = modelControls.ae.rhoF.Value;
            physicalParameters.fluidBulkModulus_Pa = modelControls.ae.fluidBulkModulus.Value * 1e9;
        elseif getOptionValueLocal(options, 'runMRLFE', false)
            physicalParameters.fluidDensity_kg_m3 = options.mrlfeParams.fluidDensity;
            physicalParameters.fluidSoundSpeed_m_s = options.mrlfeParams.fluidSoundSpeed;
            physicalParameters.etaS_Pa_s = options.mrlfeParams.etaS;
        end
    end

    function [results, guiResult] = runModelRequestThroughAdapter(params, options)
        if getOptionValueLocal(options, 'computeAcoustoelasticIOPHGO', false)
            guiRequest = guiBuildAcoustoelasticIOPHGORequest(params, modelControls.ae, options.robustness);
            guiResult = guiRunAcoustoelasticIOPHGOModel(guiRequest);
            results = guiResult.metadata.modelResult;
            return;
        end

        guiRequest = struct('params', params, 'options', options);
        if isfield(options, 'mrlfeParams')
            guiRequest.mrlfeParams = options.mrlfeParams;
        end

        if getOptionValueLocal(options, 'runMRLFE', false)
            guiRequest.computeElastic = true;
            guiRequest.computeVisco = isfield(options, 'mrlfeParams') && options.mrlfeParams.etaS > 0;
            guiResult = guiRunMRLFEModel(guiRequest);
        else
            guiResult = guiRunRayleighLambModel(guiRequest);
        end
        results = guiResult.metadata.modelResult;
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
                case {"mRLFERealK", "mRLFEElasticRealK", "mRLFEViscoRealK"}
                    if branchName == "A0Like"
                        plotControls.showMRLFEA0.Value = true;
                    elseif branchName == "S0Like"
                        plotControls.showMRLFES0.Value = true;
                    end
                    updated = true;
                case "AcoustoelasticIOPHGO"
                    plotControls.showAE.Value = true;
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
        plotted = tryPlotNormalizedResults();
        plotted = tryPlotApproximations() || plotted;
        if ~plotted && isfield(lastResults,'modes')
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
        xlabel(ax, currentXLabel());
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
            plotData = guiGetNormalizedBranchPlotData(branch, string(plotControls.xaxis.Value));
            x = plotData.x(:);
            Cp = plotData.y(:);
            valid = plotData.validMask(:) & isfinite(x) & isfinite(Cp);
            if isempty(x) || ~any(valid)
                continue;
            end
            plot(ax, x(valid), Cp(valid), '-', 'Color', normalizedBranchColor(branch), ...
                'LineWidth', 2.0, 'DisplayName', normalizedBranchDisplayName(branch));
            plotted = true;
        end
    end

    function plotted = tryPlotApproximations()
        plotted = false;
        if ~isfield(lastResults, 'approximations') || ~isstruct(lastResults.approximations)
            return;
        end
        if plotControls.showA0Thin.Value && isfield(lastResults.approximations, 'A0ThinPlate')
            plotted = plotApproximation(lastResults.approximations.A0ThinPlate, '--', 'A0 thin-plate') || plotted;
        end
        if plotControls.showS0Ext.Value && isfield(lastResults.approximations, 'S0Extensional')
            plotted = plotApproximation(lastResults.approximations.S0Extensional, ':', 'S0 extensional') || plotted;
        end
    end

    function plotted = plotApproximation(approx, lineStyle, label)
        plotted = false;
        [x, Cp] = branchXY(approx);
        valid = isfinite(x(:)) & isfinite(Cp(:));
        if isfield(approx, 'valid') && ~isempty(approx.valid)
            valid = valid & logical(approx.valid(:));
        end
        if any(valid)
            plot(ax, x(valid), Cp(valid), lineStyle, 'Color', colors.Approx, 'LineWidth', 1.5, 'DisplayName', label);
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
            case {"mRLFERealK", "mRLFEElasticRealK", "mRLFEViscoRealK"}
                tf = (branchName == "A0Like" && plotControls.showMRLFEA0.Value) || ...
                     (branchName == "S0Like" && plotControls.showMRLFES0.Value);
            case "AcoustoelasticIOPHGO"
                tf = plotControls.showAE.Value;
        end
    end

    function name = normalizedBranchDisplayName(branch)
        modelName = string(branch.modelName);
        branchName = string(branch.branchName);
        switch modelName
            case "RayleighLamb"
                name = char(branchName);
            case {"mRLFERealK", "mRLFEElasticRealK", "mRLFEViscoRealK"}
                name = ['mRLFE real-k ', char(formatMRLFEBranchName(branchName))];
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
                color = branchColor(branchName, colors.A0, colors.S0);
            case {"mRLFERealK", "mRLFEElasticRealK", "mRLFEViscoRealK"}
                color = branchColor(branchName, colors.MRLFEA0, colors.MRLFES0);
            case "AcoustoelasticIOPHGO"
                color = colors.AE;
            otherwise
                color = [0 0 0];
        end
    end

    function color = branchColor(branchName, colorA0, colorS0)
        if string(branchName) == "A0" || string(branchName) == "A0Like"
            color = colorA0;
        else
            color = colorS0;
        end
    end

    function txt = formatMRLFEBranchName(branchName)
        switch string(branchName)
            case "A0Like"
                txt = "A0-like";
            case "S0Like"
                txt = "S0-like";
            otherwise
                txt = string(branchName);
        end
    end

    function plotBranch(branch, color, label)
        [x, Cp] = branchXY(branch);
        valid = isfinite(x(:)) & isfinite(Cp(:));
        if isfield(branch,'validMask')
            valid = valid & branch.validMask(:);
        elseif isfield(branch,'valid')
            valid = valid & branch.valid(:);
        end
        if any(valid)
            plot(ax, x(valid), Cp(valid), '-', 'Color', color, 'LineWidth', 2.0, 'DisplayName', label);
        end
    end

    function [x, Cp] = branchXY(branch)
        frequency = branch.frequency_Hz(:);
        Cp = branch.phaseVelocity_mps(:);
        switch string(plotControls.xaxis.Value)
            case "angularFrequency"
                x = 2*pi*frequency;
            case "wavenumber"
                if isfield(branch, 'wavenumber_radpm') && ~isempty(branch.wavenumber_radpm)
                    x = real(branch.wavenumber_radpm(:));
                else
                    x = frequency;
                end
            case "kThickness"
                if isfield(branch, 'wavenumberThickness') && ~isempty(branch.wavenumberThickness)
                    x = real(branch.wavenumberThickness(:));
                else
                    x = frequency;
                end
            otherwise
                x = frequency;
        end
    end

    function label = currentXLabel()
        switch string(plotControls.xaxis.Value)
            case "angularFrequency"
                label = 'angular frequency [rad/s]';
            case "wavenumber"
                label = 'wavenumber k [1/m]';
            case "kThickness"
                label = 'kThickness = k * thickness [-]';
            otherwise
                label = 'frequency [Hz]';
        end
    end

    function updateLabels()
        if isempty(lastResults) || isempty(lastOptions)
            return;
        end
        if getOptionValueLocal(lastOptions, 'computeAcoustoelasticIOPHGO', false)
            updateAcoustoelasticLabels();
        else
            updateRayleighLambLabels();
        end
    end

    function updateAcoustoelasticLabels()
        r = lastResults;
        materialInfo.Text = sprintf('AE IOP/HGO | mu %.2f kPa | rho %.1f kg/m^3 | h %.3f mm\nIOP %.2f mmHg | R %.2f mm | k1 %.2f kPa | k2 %.2f', ...
            lastParams.mu/1e3, lastParams.rho, lastParams.thickness*1e3, ...
            modelControls.ae.IOP.Value, modelControls.ae.R.Value, modelControls.ae.k1.Value, modelControls.ae.k2.Value);
        elapsedText = formatElapsedText(getGuiElapsedSeconds());
        statusLines = {sprintf('Status: AE IOP/HGO A0-like | N=%d%s', numel(r.phaseVelocity_mps), elapsedText), ...
            sprintf('Cp valid %d/%d', nnz(r.validMask), numel(r.phaseVelocity_mps))};
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
        materialInfo.Text = sprintf('rho %.1f kg/m^3 | 2h %.3f mm | mu %.2f kPa | nu %.5f | E %.2f kPa\nlambda_L %.2f MPa | K %.2f MPa | CL %.2f m/s | CT %.2f m/s', ...
            mat.rho, geom.thickness*1e3, mat.mu/1e3, mat.nu, mat.E/1e3, mat.lambda/1e6, mat.K/1e6, mat.CL, mat.CT);
        elapsedText = formatElapsedText(getGuiElapsedSeconds());
        if ~isempty(gridData) && isfield(gridData,'frequency')
            setStatusText({sprintf('Status: computed %d frequency points%s.', numel(gridData.frequency), elapsedText)});
        else
            setStatusText({sprintf('Status: computed%s.', elapsedText)});
        end
    end

    function onShowDiagnostics()
        if isempty(lastResults)
            uialert(fig,'Compute first.','No results');
            return;
        end
        diagFig = uifigure('Name','Diagnostics','Position',[120 120 760 560]);
        ta = uitextarea(diagFig,'Value',cellstr(splitlines(buildDiagnosticsText())),'Editable','off','FontName','Consolas');
        ta.Position = [10 10 740 540];
    end

    function txt = buildDiagnosticsText()
        lines = strings(0,1);
        if getOptionValueLocal(lastOptions, 'computeAcoustoelasticIOPHGO', false)
            lines(end+1) = "AE IOP/HGO diagnostics";
        else
            lines(end+1) = "Rayleigh-Lamb / mRLFE diagnostics";
        end
        lines(end+1) = "";
        lines = appendGuiVisibleDiagnostics(lines);
        lines = appendRawModelDiagnostics(lines);
        lines = appendOptionDiagnostics(lines);
        lines = appendParameterDiagnostics(lines);
        txt = strjoin(lines, newline);
    end

    function lines = appendGuiVisibleDiagnostics(lines)
        lines(end+1) = "GUI-visible branches:";
        if isempty(lastGuiResult) || ~isfield(lastGuiResult, 'branches') || isempty(lastGuiResult.branches)
            lines(end+1) = "  none";
        else
            for i = 1:numel(lastGuiResult.branches)
                branch = lastGuiResult.branches(i);
                n = numel(branch.phaseVelocity);
                valid = getBranchValidCount(branch);
                lines(end+1) = sprintf("  %s %s | valid %d/%d", string(branch.modelName), string(branch.branchName), valid, n); %#ok<AGROW>
            end
        end
        elapsed = getGuiElapsedSeconds();
        if isfinite(elapsed)
            lines(end+1) = sprintf("adapter elapsed %.6g s", elapsed);
        end
        if ~isempty(lastGuiResult) && isfield(lastGuiResult, 'metadata') && ...
                isfield(lastGuiResult.metadata, 'seedBranchesHiddenFromPlotSurface')
            lines(end+1) = sprintf("seed branches hidden from plotting surface: %d", logical(lastGuiResult.metadata.seedBranchesHiddenFromPlotSurface));
        end
        lines(end+1) = "";
    end

    function lines = appendRawModelDiagnostics(lines)
        lines(end+1) = "Raw/internal result content:";
        if isfield(lastResults, 'modes')
            lines(end+1) = sprintf("  RL seed/result modes: %s", strjoin(string(fieldnames(lastResults.modes)), ", "));
        end
        lines(end+1) = "";
    end

    function lines = appendOptionDiagnostics(lines)
        lines(end+1) = "GUI route / policy:";
        if isempty(lastGuiResult) || ~isfield(lastGuiResult, 'metadata')
            lines(end+1) = "  unavailable";
        else
            md = lastGuiResult.metadata;
            if isfield(md, 'executionProfile')
                profileExtra = strings(0, 1);
                if isfield(md, 'status')
                    profileExtra(end+1) = "status: " + string(md.status);
                end
                if isfield(md, 'execution') && isstruct(md.execution)
                    profileExtra = appendExecutionSummary(profileExtra, md.execution);
                end
                if isfield(md, 'termination') && isstruct(md.termination)
                    profileExtra = appendPolicySummary(profileExtra, "termination", md.termination, "policy");
                end
                if isfield(md, 'fallback') && isstruct(md.fallback)
                    profileExtra = appendPolicySummary(profileExtra, "fallback", md.fallback, "policy");
                end
                if isfield(md, 'quality') && isstruct(md.quality)
                    profileExtra = appendQualitySummary(profileExtra, md.quality);
                end
                if isfield(md, 'mrlfeA0Policy')
                    profileExtra(end+1) = "A0 policy: " + string(md.mrlfeA0Policy);
                end
                [visibleBranch, validCount, totalCount] = firstVisibleBranchSummary();
                formatted = guiFormatExecutionProfileDiagnostics(md.executionProfile, ...
                    'Surface', "Main GUI", ...
                    'Model', mainDiagnosticModelName(), ...
                    'ControlProfile', getControlExecutionProfileText(), ...
                    'VisibleBranch', visibleBranch, ...
                    'ValidCount', validCount, ...
                    'TotalCount', totalCount, ...
                    'ElapsedSeconds', getGuiElapsedSeconds(), ...
                    'Fallback', getMainFallbackText(md), ...
                    'ExtraLines', profileExtra);
                lines = [lines; "  " + formatted(:)];
            end
            if isfield(md, 'mrlfeA0Policy')
                lines(end+1) = sprintf("  A0 policy: %s", string(md.mrlfeA0Policy));
            end
            if isfield(md, 'mrlfeZeroViscosityAdaptiveQuality')
                q = md.mrlfeZeroViscosityAdaptiveQuality;
                if isfield(q, 'validFraction')
                    lines(end+1) = sprintf("  zero-eta valid fraction: %.3f", q.validFraction);
                end
                if isfield(q, 'validCount') && isfield(q, 'totalCount')
                    lines(end+1) = sprintf("  zero-eta valid points: %d/%d", q.validCount, q.totalCount);
                end
                if isfield(q, 'maxJumpRelative')
                    lines(end+1) = sprintf("  zero-eta max jump relative: %.3g", q.maxJumpRelative);
                end
            end
        end
        lines(end+1) = "";

        lines(end+1) = "Requested GUI options:";
        if isempty(lastOptions)
            lines(end+1) = "  unavailable";
        else
            if isfield(lastOptions, 'executionProfileMetadata')
                mdProfile = lastOptions.executionProfileMetadata;
                lines(end+1) = sprintf("  control execution profile: %s", getControlExecutionProfileText());
                lines(end+1) = sprintf("  normalized requested profile: %s", ...
                    string(mdProfile.requestedExecutionProfile));
                lines(end+1) = sprintf("  control profile source: %s", string(mdProfile.executionProfileSource));
            end
            optionNames = ["computeA0", "computeS0", "runMRLFE", "computeAcoustoelasticIOPHGO"];
            optionLabels = ["Rayleigh-Lamb seed A0", "Rayleigh-Lamb seed S0", ...
                "mRLFE real-k", "AE IOP/HGO"];
            for i = 1:numel(optionNames)
                name = optionNames(i);
                if isfield(lastOptions, char(name))
                    lines(end+1) = sprintf("  %s = %d", optionLabels(i), logical(lastOptions.(char(name)))); %#ok<AGROW>
                end
            end
            if isfield(lastOptions, 'branchNames')
                lines(end+1) = sprintf("  mRLFE branches = %s", strjoin(string(lastOptions.branchNames), ", "));
            end
            if isfield(lastOptions, 'mrlfeParams') && isfield(lastOptions.mrlfeParams, 'etaS')
                lines(end+1) = sprintf("  etaS = %.6g Pa*s", lastOptions.mrlfeParams.etaS);
            end
        end
        lines(end+1) = "";
    end

    function lines = appendParameterDiagnostics(lines)
        lines(end+1) = "Material / geometry:";
        if isempty(lastParams)
            lines(end+1) = "  unavailable";
        else
            lines(end+1) = sprintf("  modelType %s", string(lastParams.modelType));
            lines(end+1) = sprintf("  rho %.6g kg/m^3", lastParams.rho);
            lines(end+1) = sprintf("  mu %.6g Pa", lastParams.mu);
            lines(end+1) = sprintf("  nu %.6g", lastParams.nu);
            lines(end+1) = sprintf("  E %.6g Pa", lastParams.E);
            lines(end+1) = sprintf("  lambda_Lame %.6g Pa", lastParams.lambda);
            lines(end+1) = sprintf("  K %.6g Pa", lastParams.K);
            lines(end+1) = sprintf("  CL %.6g m/s", lastParams.CL);
            lines(end+1) = sprintf("  CT %.6g m/s", lastParams.CT);
            lines(end+1) = sprintf("  2h %.6g m", lastParams.thickness);
        end
    end

    function text = getControlExecutionProfileText()
        if ~isempty(lastOptions) && isfield(lastOptions, 'executionProfile')
            text = string(lastOptions.executionProfile);
        elseif ~isempty(advanced) && isfield(advanced, 'robustness')
            text = string(advanced.robustness.Value);
        else
            text = "";
        end
    end

    function modelName = mainDiagnosticModelName()
        modelName = "Rayleigh-Lamb";
        if ~isempty(lastOptions) && getOptionValueLocal(lastOptions, 'computeAcoustoelasticIOPHGO', false)
            modelName = "AE IOP/HGO";
        elseif ~isempty(lastOptions) && getOptionValueLocal(lastOptions, 'runMRLFE', false)
            modelName = "mRLFE";
        end
    end

    function fallback = getMainFallbackText(md)
        fallback = "";
        if isfield(md, 'executionProfile') && isfield(md.executionProfile, 'anyFallbackApplied')
            fallback = string(logical(md.executionProfile.anyFallbackApplied));
            return;
        end
    end

    function linesOut = appendExecutionSummary(linesIn, execution)
        linesOut = linesIn;
        names = fieldnames(execution);
        for iExec = 1:numel(names)
            name = string(names{iExec});
            value = execution.(char(name));
            if isstruct(value) && isfield(value, 'internalEngine')
                linesOut(end+1) = name + " engine: " + string(value.internalEngine); %#ok<AGROW>
            end
            if isstruct(value) && isfield(value, 'effectivePreset')
                linesOut(end+1) = name + " preset: " + string(value.effectivePreset); %#ok<AGROW>
            end
        end
    end

    function linesOut = appendPolicySummary(linesIn, label, policies, fieldName)
        linesOut = linesIn;
        names = fieldnames(policies);
        for iPolicy = 1:numel(names)
            name = string(names{iPolicy});
            value = policies.(char(name));
            if isstruct(value) && isfield(value, fieldName)
                linesOut(end+1) = name + " " + label + ": " + string(value.(fieldName)); %#ok<AGROW>
            end
            if label == "fallback" && isstruct(value) && isfield(value, 'applied')
                linesOut(end+1) = name + " fallback applied: " + string(logical(value.applied)); %#ok<AGROW>
            end
        end
    end

    function linesOut = appendQualitySummary(linesIn, quality)
        linesOut = linesIn;
        names = fieldnames(quality);
        for iQuality = 1:numel(names)
            name = string(names{iQuality});
            value = quality.(char(name));
            if isstruct(value) && isfield(value, 'accepted')
                linesOut(end+1) = name + " quality accepted: " + string(logical(value.accepted)); %#ok<AGROW>
            end
            if isstruct(value) && isfield(value, 'reason')
                linesOut(end+1) = name + " quality reason: " + string(value.reason); %#ok<AGROW>
            end
        end
    end

    function [visibleBranch, validCount, totalCount] = firstVisibleBranchSummary()
        visibleBranch = "";
        validCount = nan;
        totalCount = nan;
        if isempty(lastGuiResult) || ~isfield(lastGuiResult, 'branches') || isempty(lastGuiResult.branches)
            return;
        end
        branch = lastGuiResult.branches(1);
        visibleBranch = string(branch.modelName) + " " + string(branch.branchName);
        totalCount = numel(branch.phaseVelocity);
        validCount = getBranchValidCount(branch);
    end

    function nValid = getBranchValidCount(branch)
        values = branch.phaseVelocity(:);
        valid = isfinite(values);
        if isfield(branch, 'diagnostics') && isfield(branch.diagnostics, 'valid') && ~isempty(branch.diagnostics.valid)
            valid = valid & logical(branch.diagnostics.valid(:));
        end
        nValid = nnz(valid);
    end

    function elapsed = getGuiElapsedSeconds()
        elapsed = nan;
        if ~isempty(lastGuiResult) && isfield(lastGuiResult, 'metadata') && ...
                isfield(lastGuiResult.metadata, 'elapsedSeconds')
            elapsed = lastGuiResult.metadata.elapsedSeconds;
        elseif ~isempty(lastGuiResult) && isfield(lastGuiResult, 'diagnostics') && ...
                isfield(lastGuiResult.diagnostics, 'elapsedSeconds')
            elapsed = lastGuiResult.diagnostics.elapsedSeconds;
        end
    end

    function text = formatElapsedText(elapsed)
        if isfinite(elapsed)
            text = sprintf(' | %.3g s', elapsed);
        else
            text = '';
        end
    end

    function onExport()
        if isempty(lastGuiResult) || isempty(lastPhysicalParameters)
            uialert(fig, 'Compute first.', 'No results');
            return;
        end

        if inputsAreDirty
            choice = uiconfirm(fig, ...
                'The controls have changed since the last computation. Export the last computed result?', ...
                'Inputs changed', ...
                'Options', {'Export last computed result', 'Cancel'}, ...
                'DefaultOption', 2, ...
                'CancelOption', 2);
            if string(choice) ~= "Export last computed result"
                return;
            end
        end

        defaultName = ['LambExport_', datestr(now, 'yyyymmdd_HHMMSS'), '.mat']; %#ok<DATST,TNOW1>
        [file, path] = uiputfile('*.mat', 'Save results', defaultName);
        if isequal(file, 0)
            return;
        end

        try
            exportData = guiBuildMainResultExport(lastGuiResult, lastPhysicalParameters);
            savedPath = guiSaveMainResultExport(fullfile(path, file), exportData);
            setStatusText({['Status: saved ', savedPath]});
        catch ME
            setStatusText({['Status: export error: ', ME.message]});
            uialert(fig, ME.message, 'Export error');
        end
    end

    function setStatusText(lines)
        statusBox.Value = lines(:);
    end

    function onAutoAxesChanged()
        updateAxisFieldState();
        refreshPlotOnly();
    end

    function updateAxisFieldState()
        enable = onOff(~logical(plotControls.autoAxes.Value));
        plotControls.xmin.Enable = enable;
        plotControls.xmax.Enable = enable;
        plotControls.ymin.Enable = enable;
        plotControls.ymax.Enable = enable;
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
        plotControls.xmin.Value = xl(1);
        plotControls.xmax.Value = xl(2);
        plotControls.ymin.Value = yl(1);
        plotControls.ymax.Value = yl(2);
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
if isfield(results, 'modes') && isfield(results.modes, 'A0')
    gridData = struct('frequency', results.modes.A0.frequency_Hz);
elseif isfield(results, 'modes') && isfield(results.modes, 'S0')
    gridData = struct('frequency', results.modes.S0.frequency_Hz);
else
    gridData = [];
end
end
