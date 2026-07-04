function FitTool_GUI()
%FITTOOL_GUI Visual interface for one-parameter experimental dispersion fitting.

lastFitOutput = [];
fitParameterState = struct();
lastSyntheticDiagnostics = strings(0, 1);
lastDataMetadata = struct('sourceType', "editable_table");
selectedDataRows = [];
axisViewState = struct('xMode', "auto", 'yMode', "auto", ...
    'xLimits_kHz', [nan nan], 'yLimits_mps', [nan nan]);

fig = uifigure('Name', 'Experimental Dispersion Fitting Tool', 'Position', [120 80 1360 840]);
root = uigridlayout(fig, [1 2]);
root.ColumnWidth = {680, '1x'};
root.Padding = [8 8 8 8];
root.ColumnSpacing = 8;

leftPanel = uipanel(root, 'Title', 'Fitting controls');
leftPanel.Layout.Column = 1;
leftGrid = uigridlayout(leftPanel, [1 1]);
leftGrid.Padding = [5 5 5 5];
tabs = uitabgroup(leftGrid);

fitControls = [];
callbacks = struct();
callbacks.onFitModelChanged = @(~,~)onFitModelChanged();
callbacks.onFitParameterChanged = @(~,~)onFitParameterChanged();
callbacks.onLoadFitData = @(~,~)onLoadFitData();
callbacks.onPopulateFitData = @(~,~)onPopulateFitData();
callbacks.onResetDefaults = @(~,~)onResetDefaults();
callbacks.onRunFit = @(~,~)onRunFit();
callbacks.onAddFitDataRow = @(~,~)onAddFitDataRow();
callbacks.onDeleteFitDataRows = @(~,~)onDeleteFitDataRows();
callbacks.onFitDataCellSelected = @(~,event)onFitDataCellSelected(event);
callbacks.onFitDataCellEdited = @(~,~)onFitDataCellEdited();
callbacks.onApplyFitAxes = @(~,~)onApplyFitAxes();
callbacks.onAutoFitAxes = @(~,~)onAutoFitAxes();
callbacks.onEvaluateFittedCurve = @(~,~)onEvaluateFittedCurve();
fitControls = createFittingTab(tabs, rlDefaultParams(), callbacks);

rightGrid = uigridlayout(root, [3 1]);
rightGrid.Layout.Column = 2;
rightGrid.RowHeight = {'1x', 82, 185};
rightGrid.Padding = [0 0 0 0];
rightGrid.RowSpacing = 8;

ax = uiaxes(rightGrid);
ax.Layout.Row = 1;
grid(ax, 'on');
xlabel(ax, 'Frequency [kHz]');
ylabel(ax, 'Phase speed [m/s]');
title(ax, 'Experimental fit');

parameterPanel = uipanel(rightGrid, 'Title', 'Parameter summary');
parameterPanel.Layout.Row = 2;
parameterPanelGrid = uigridlayout(parameterPanel, [1 1]);
parameterPanelGrid.Padding = [0 0 0 0];
parameterResultTable = uitable(parameterPanelGrid, 'Data', table(), 'ColumnName', {});
parameterResultTable.ColumnWidth = {150, 70, 60, 70, 70, 70};

qualityPanel = uipanel(rightGrid, 'Title', 'Fit quality summary');
qualityPanel.Layout.Row = 3;
qualityPanelGrid = uigridlayout(qualityPanel, [1 1]);
qualityPanelGrid.Padding = [0 0 0 0];
fitQualityTable = uitable(qualityPanelGrid, 'Data', table(), 'ColumnName', {});
fitQualityTable.ColumnWidth = {240, 170};

onFitModelChanged();

    function onFitModelChanged()
        modelFamily = getSelectedModelFamily();
        family = getSelectedFamily();
        fitControls.branch.Items = cellstr(family.branchNames);
        fitControls.branch.Value = char(family.defaultBranchName);
        fitControls.robustness.Items = cellstr(family.robustnessPresets);
        fitControls.robustness.Value = char(family.defaultRobustness);
        fitIds = string({family.parameters([family.parameters.canFit]).id});
        fitControls.freeParam.Items = cellstr(fitIds);
        fitControls.freeParam.Value = char(fitIds(1));
        fitParameterState = guiBuildFitParameterState(modelFamily, fitIds(1));
        updateParameterTable();
        updateModelSpecificControls(modelFamily);
        fitControls.status.Text = sprintf('Fit status: selected model %s.', string(family.label));
    end

    function onFitParameterChanged()
        fitParameterState = readParameterState();
        modelFamily = getSelectedModelFamily();
        freeParam = string(fitControls.freeParam.Value);
        fitParameterState = guiBuildFitParameterState(modelFamily, freeParam, fitParameterState);
        updateParameterTable();
    end

    function onResetDefaults()
        modelFamily = getSelectedModelFamily();
        family = getSelectedFamily();
        freeParam = string(fitControls.freeParam.Value);
        fitParameterState = guiBuildFitParameterState(modelFamily, freeParam);
        fitControls.robustness.Value = char(family.defaultRobustness);
        if modelFamily == "mrlfe"
            fitControls.a0Policy.Value = 'adaptivePhysicalTail';
        end
        updateParameterTable();
        fitControls.status.Text = sprintf('Fit status: restored %s defaults.', string(family.label));
    end

    function updateParameterTable()
        fitControls.parameterTable.Data = guiFitParameterStateToTable(fitParameterState);
        fitControls.fixedHeader.Text = sprintf( ...
            'Fitted parameter: %s. All other rows are fixed and editable.', fitParameterState.freeParam);
    end

    function state = readParameterState()
        if isempty(fitParameterState) || ~isstruct(fitParameterState) || ~isfield(fitParameterState, 'parameters')
            state = guiBuildFitParameterState(getSelectedModelFamily(), string(fitControls.freeParam.Value));
            return;
        end
        state = guiApplyFitParameterTable(fitParameterState, fitControls.parameterTable.Data);
    end

    function onLoadFitData()
        [fileName, folder] = uigetfile({'*.csv;*.txt;*.dat;*.mat', ...
            'Experimental dispersion data (*.csv, *.txt, *.dat, *.mat)'}, ...
            'Load experimental dispersion data');
        if isequal(fileName, 0)
            return;
        end

        try
            imported = guiReadExperimentalFitFile(string(fullfile(folder, fileName)));
            columnNames = cellstr(imported.columnNames);
            frequencyColumn = chooseColumn('Select frequency column', columnNames, localSuggestedColumn(imported.columnNames, ["frequency", "freq", "f"]));
            phaseSpeedColumn = chooseColumn('Select phase-speed column', columnNames, localSuggestedColumn(imported.columnNames, ["cp", "phase", "velocity", "speed"]));
            if frequencyColumn == phaseSpeedColumn
                error('Frequency and phase-speed columns must be different.');
            end

            unitChoice = questdlg('Frequency unit in the selected file:', 'Frequency unit', 'Hz', 'kHz', 'Hz');
            if isempty(unitChoice)
                return;
            end

            useColumn = localSuggestedColumn(imported.columnNames, ["use", "valid", "mask"]);
            prepared = guiPrepareExperimentalFitData(imported, ...
                'FrequencyColumn', frequencyColumn, ...
                'PhaseSpeedColumn', phaseSpeedColumn, ...
                'UseColumn', useColumn, ...
                'FrequencyUnit', string(unitChoice), ...
                'PhaseSpeedUnit', "m/s", ...
                'DuplicatePolicy', "mean");

            fitControls.dataTable.Data = prepared.tableData;
            selectedDataRows = [];
            lastDataMetadata = prepared.metadata;
            lastDataMetadata.wasManuallyEdited = false;
            fitControls.dataSource.Text = sprintf('Data source: %s | %d rows | frequency %s -> Hz', ...
                prepared.metadata.fileName, prepared.metadata.outputRows, prepared.metadata.inputFrequencyUnit);
            plotExperimentalInput(prepared.frequency_Hz, prepared.Cp_mps, prepared.validMask);
            updateCurveRangeControls(prepared.frequency_Hz);
            fitControls.status.Text = sprintf(['Fit status: loaded experimental data from %s. ', ...
                'Removed %d invalid rows; collapsed %d duplicate rows.'], ...
                prepared.metadata.fileName, prepared.metadata.removedInvalidRows, ...
                prepared.metadata.duplicateRowsCollapsed);
        catch ME
            fitControls.status.Text = ['Fit status: data import error: ', ME.message];
            uialert(fig, ME.message, 'Experimental data import error');
        end
    end

    function index = chooseColumn(prompt, columnNames, suggestedIndex)
        initialValue = max(1, min(numel(columnNames), suggestedIndex));
        [selection, ok] = listdlg('PromptString', prompt, 'SelectionMode', 'single', ...
            'ListString', columnNames, 'InitialValue', initialValue, 'ListSize', [360 220]);
        if ~ok
            error('FitDataImport:Cancelled', 'Experimental data import was cancelled.');
        end
        index = selection;
    end

    function index = localSuggestedColumn(names, tokens)
        index = 0;
        normalizedNames = lower(string(names));
        for token = string(tokens)
            match = find(contains(normalizedNames, lower(token)), 1, 'first');
            if ~isempty(match)
                index = match;
                return;
            end
        end
        if index == 0
            index = 1;
        end
    end

    function plotExperimentalInput(frequency_Hz, Cp_mps, validMask)
        cla(ax);
        valid = logical(validMask(:)) & isfinite(frequency_Hz(:)) & isfinite(Cp_mps(:));
        plot(ax, frequency_Hz(valid) / 1e3, Cp_mps(valid), 'o', ...
            'LineStyle', 'none', 'DisplayName', 'Experimental data');
        grid(ax, 'on');
        xlabel(ax, 'Frequency [kHz]');
        ylabel(ax, 'Phase speed [m/s]');
        title(ax, 'Imported experimental data');
        legend(ax, 'Location', 'best');
        guiApplyFitAxisView(ax, axisViewState);
    end

    function onAddFitDataRow()
        try
            fitControls.dataTable.Data = guiAppendExperimentalFitRow(fitControls.dataTable.Data);
            selectedDataRows = size(fitControls.dataTable.Data, 1);
            markDataManuallyEdited();
            updateDataPreviewFromTable();
            fitControls.status.Text = 'Fit status: added editable experimental data row.';
        catch ME
            fitControls.status.Text = ['Fit status: add-row error: ', ME.message];
        end
    end

    function onDeleteFitDataRows()
        try
            beforeRows = size(fitControls.dataTable.Data, 1);
            fitControls.dataTable.Data = guiDeleteExperimentalFitRows(fitControls.dataTable.Data, selectedDataRows);
            afterRows = size(fitControls.dataTable.Data, 1);
            selectedDataRows = [];
            if afterRows ~= beforeRows
                markDataManuallyEdited();
                updateDataPreviewFromTable();
                fitControls.status.Text = sprintf('Fit status: deleted %d selected experimental row(s).', beforeRows - afterRows);
            end
        catch ME
            fitControls.status.Text = ['Fit status: delete-row error: ', ME.message];
        end
    end

    function onFitDataCellSelected(event)
        selectedDataRows = [];
        if isprop(event, 'Indices') && ~isempty(event.Indices)
            selectedDataRows = unique(event.Indices(:, 1));
        end
    end

    function onFitDataCellEdited()
        markDataManuallyEdited();
        updateDataPreviewFromTable();
    end

    function markDataManuallyEdited()
        lastDataMetadata = guiMarkExperimentalFitDataEdited(lastDataMetadata);
        lastDataMetadata.inputRows = size(fitControls.dataTable.Data, 1);
        lastDataMetadata.outputRows = size(fitControls.dataTable.Data, 1);
        fitControls.dataSource.Text = "Data source: " + string(lastDataMetadata.sourceType) + " | manually edited";
    end

    function updateDataPreviewFromTable()
        data = fitControls.dataTable.Data;
        if istable(data)
            data = table2array(data);
        end
        if ~isnumeric(data) || size(data, 2) < 2
            return;
        end
        frequency_Hz = data(:, 1);
        Cp_mps = data(:, 2);
        if size(data, 2) >= 3
            validMask = logical(data(:, 3));
        else
            validMask = true(size(frequency_Hz));
        end
        plotExperimentalInput(frequency_Hz, Cp_mps, validMask);
        finiteFrequency = frequency_Hz(isfinite(frequency_Hz) & frequency_Hz > 0);
        if ~isempty(finiteFrequency)
            updateCurveRangeControls(finiteFrequency);
        end
    end

    function onPopulateFitData()
        try
            requestParts = buildParameterConfig();
            modelFamily = getSelectedModelFamily();
            branchName = string(fitControls.branch.Value);
            tSynthetic = tic;
            [frequency_Hz, Cp_mps, validMask] = generateSyntheticData(modelFamily, branchName, requestParts);
            syntheticElapsed = toc(tSynthetic);
            fitControls.dataTable.Data = [frequency_Hz(:), Cp_mps(:), double(validMask(:))];
            selectedDataRows = [];
            lastDataMetadata = struct('sourceType', "synthetic", ...
                'modelFamily', modelFamily, 'branchName', branchName, ...
                'outputRows', numel(frequency_Hz), 'wasManuallyEdited', false);
            fitControls.dataSource.Text = sprintf('Data source: synthetic %s %s | %d rows', ...
                modelFamily, branchName, numel(frequency_Hz));
            plotExperimentalInput(frequency_Hz, Cp_mps, validMask);
            updateCurveRangeControls(frequency_Hz);
            lastSyntheticDiagnostics = buildSyntheticDiagnosticsStatusLines(modelFamily, branchName, requestParts, ...
                syntheticElapsed, nnz(validMask), numel(validMask));
            fitControls.status.Text = strjoin(lastSyntheticDiagnostics, newline);
        catch ME
            fitControls.status.Text = ['Fit status: error generating data: ', ME.message];
            uialert(fig, ME.message, 'Synthetic data error');
        end
    end

    function onRunFit()
        try
            request = buildRequestFromControls();
            fitControls.status.Text = 'Fit status: running...';
            drawnow;
            lastFitOutput = guiRunFit(request);
            lastFitOutput.experimentalDataMetadata = lastDataMetadata;
            guiPlotFitResult(lastFitOutput.normalized, ax);
            guiApplyFitAxisView(ax, axisViewState);
            updateResultTables(lastFitOutput.normalized);
            updateStatusFromFitOutput(lastFitOutput);
            assignin('base', 'FitToolLastOutput', lastFitOutput);
        catch ME
            fitControls.status.Text = ['Fit status: error: ', ME.message];
            uialert(fig, ME.message, 'Fitting error');
        end
    end

    function onApplyFitAxes()
        try
            axisViewState = guiValidateFitAxisLimits( ...
                [str2double(fitControls.axisXMinKHz.Value), str2double(fitControls.axisXMaxKHz.Value)], ...
                [str2double(fitControls.axisYMinMps.Value), str2double(fitControls.axisYMaxMps.Value)]);
            guiApplyFitAxisView(ax, axisViewState);
            fitControls.axisHeader.Text = 'Axis view (Manual)';
            fitControls.status.Text = 'Fit status: manual axis limits applied.';
        catch ME
            fitControls.status.Text = ['Fit status: axis limit error: ', ME.message];
            uialert(fig, ME.message, 'Axis limit error');
        end
    end

    function onAutoFitAxes()
        axisViewState = struct('xMode', "auto", 'yMode', "auto", ...
            'xLimits_kHz', [nan nan], 'yLimits_mps', [nan nan]);
        fitControls.axisXMinKHz.Value = '';
        fitControls.axisXMaxKHz.Value = '';
        fitControls.axisYMinMps.Value = '';
        fitControls.axisYMaxMps.Value = '';
        fitControls.axisHeader.Text = 'Axis view (Auto)';
        guiApplyFitAxisView(ax, axisViewState);
        fitControls.status.Text = 'Fit status: automatic axes restored.';
    end

    function onEvaluateFittedCurve()
        try
            if isempty(lastFitOutput) || ~isstruct(lastFitOutput)
                error('Run a fit before evaluating the fitted curve.');
            end
            [frequency_Hz, nPoints] = requestedCurveFrequencyVector();
            requestedCurve = guiEvaluateRequestedFitCurve(lastFitOutput, frequency_Hz);
            requestedCurve.requestedNumPoints = nPoints;
            lastFitOutput.requestedCurve = requestedCurve;
            lastFitOutput.normalized.requestedCurve = requestedCurve;
            guiPlotFitResult(lastFitOutput.normalized, ax);
            guiApplyFitAxisView(ax, axisViewState);
            updateResultTables(lastFitOutput.normalized);
            updateStatusFromRequestedCurve(requestedCurve);
            assignin('base', 'FitToolLastOutput', lastFitOutput);
        catch ME
            fitControls.status.Text = ['Fit status: requested-curve error: ', ME.message];
            uialert(fig, ME.message, 'Requested curve error');
        end
    end

    function [frequency_Hz, nPoints] = requestedCurveFrequencyVector()
        fmin_kHz = fitControls.curveMinKHz.Value;
        fmax_kHz = fitControls.curveMaxKHz.Value;
        nPoints = round(fitControls.curvePoints.Value);
        if ~isfinite(fmin_kHz) || ~isfinite(fmax_kHz) || fmin_kHz <= 0 || fmax_kHz <= fmin_kHz
            error('Curve frequency min/max must be finite, positive, and increasing.');
        end
        if ~isfinite(nPoints) || nPoints < 2
            error('Curve point count must be at least 2.');
        end
        frequency_Hz = linspace(fmin_kHz * 1e3, fmax_kHz * 1e3, nPoints).';
    end

    function updateCurveRangeControls(frequency_Hz)
        frequency_Hz = frequency_Hz(:);
        frequency_Hz = frequency_Hz(isfinite(frequency_Hz) & frequency_Hz > 0);
        if isempty(frequency_Hz)
            return;
        end
        fitControls.curveMinKHz.Value = min(frequency_Hz) / 1e3;
        fitControls.curveMaxKHz.Value = max(frequency_Hz) / 1e3;
    end

    function updateResultTables(normalized)
        if isfield(normalized, 'parameterSummaryTable')
            parameterDisplay = guiBuildFitParameterDisplayTable(normalized.parameterSummaryTable);
        else
            parameterDisplay = guiBuildFitParameterDisplayTable(normalized.summaryTable);
        end
        parameterResultTable.Data = parameterDisplay;
        parameterResultTable.ColumnName = readableColumnNames(parameterDisplay.Properties.VariableNames);
        if isfield(normalized, 'fitQualitySummaryTable')
            qualityDisplay = guiBuildFitQualityDisplayTable(normalized.fitQualitySummaryTable);
            fitQualityTable.Data = qualityDisplay;
            fitQualityTable.ColumnName = qualityDisplay.Properties.VariableNames;
        else
            fitQualityTable.Data = table();
            fitQualityTable.ColumnName = {};
        end
    end

    function names = readableColumnNames(names)
        names = string(names);
        names(names == "StandardError") = "Standard error";
        names(names == "ConfidenceLower") = "Confidence lower";
        names(names == "ConfidenceUpper") = "Confidence upper";
        names = replace(names, "_", " ");
        names(names == "Standard error") = "Standard error";
        names(names == "Confidence lower") = "Confidence lower";
        names(names == "Confidence upper") = "Confidence upper";
        names = cellstr(names);
    end

    function request = buildRequestFromControls()
        modelFamily = getSelectedModelFamily();
        experimental = readExperimentalData();
        parts = buildParameterConfig();
        request = guiBuildFitRequest(modelFamily, ...
            'branchName', string(fitControls.branch.Value), ...
            'mode', "basic", ...
            'experimental', experimental, ...
            'fixedParams', parts.fixedParams, ...
            'freeParams', parts.freeParams, ...
            'initialGuess', parts.initialGuess, ...
            'bounds', parts.bounds, ...
            'controls', parts.controls, ...
            'fitOptions', parts.fitOptions);
    end

    function parts = buildParameterConfig()
        fitParameterState = readParameterState();
        parts = guiBuildFitParameterRequest(fitParameterState);
        parts.controls.robustness = string(fitControls.robustness.Value);
        parts.controls.executionProfile = parts.controls.robustness;
        parts.fitOptions = struct('useStandardErrorWeights', false);

        switch getSelectedModelFamily()
            case "mrlfe"
                parts.controls.mrlfeUseUnifiedAtlasRoute = true;
                parts.controls.mrlfeUseAtlasFitRoute = true;
                parts.controls.mrlfeA0Policy = string(fitControls.a0Policy.Value);
                parts.fitOptions.optimizerOptions = optimset( ...
                    'Display', 'off', 'MaxIter', 35, 'MaxFunEvals', 80, 'TolX', 1e-5);
            case "acoustoelastic_iop_hgo"
                parts.controls.atlasInitializationNumFrequencyPoints = 50;
                parts.fitOptions.optimizerOptions = optimset( ...
                    'Display', 'off', 'MaxIter', 10, 'MaxFunEvals', 24, 'TolX', 1e-3);
                if parts.freeParams == "thickness"
                    parts.fitOptions.optimizerOptions = optimset( ...
                        'Display', 'off', 'MaxIter', 10, 'MaxFunEvals', 24, 'TolX', 1e-8);
                end
        end
    end

    function experimental = readExperimentalData()
        data = fitControls.dataTable.Data;
        if istable(data)
            data = table2array(data);
        end
        if ~isnumeric(data) || size(data, 2) < 2
            error('Experimental table must contain numeric frequency_Hz and Cp_mps columns.');
        end
        imported = struct('numericData', data, 'columnNames', ["frequency_Hz", "Cp_mps", "Use"]);
        prepared = guiPrepareExperimentalFitData(imported, ...
            'FrequencyColumn', 1, 'PhaseSpeedColumn', 2, ...
            'UseColumn', min(3, size(data,2)), ...
            'FrequencyUnit', "Hz", 'PhaseSpeedUnit', "m/s", ...
            'DuplicatePolicy', "mean");
        experimental = struct();
        experimental.frequency_Hz = prepared.frequency_Hz;
        experimental.Cp_mps = prepared.Cp_mps;
        experimental.validMask = prepared.validMask;
        experimental.metadata = lastDataMetadata;
    end

    function [frequency_Hz, Cp_mps, validMask] = generateSyntheticData(modelFamily, branchName, parts)
        switch modelFamily
            case "rayleigh_lamb"
                [params, ~] = guiResolveFitModelSetup(modelFamily, rlDefaultParams(), parts);
                frequency_Hz = linspace(1000, 8000, 12).';
                options = rlDefaultOptions(string(fitControls.robustness.Value));
                Cp_mps = rlEvaluateFitModel(params, frequency_Hz, branchName, options);
                validMask = isfinite(Cp_mps(:));
            case "mrlfe"
                [params, resolvedControls] = guiResolveFitModelSetup(modelFamily, mrlfeDefaultSweepParams(), parts);
                frequency_Hz = linspace(1000, 8000, 10).';
                options = mrlfeDefaultSweepOptions(branchName, ...
                    'EtaS', resolvedControls.etaS, ...
                    'UseUnifiedAtlasRoute', true, ...
                    'A0Policy', string(fitControls.a0Policy.Value));
                options.mrlfeParams.fluidDensity = resolvedControls.fluidDensity;
                options.mrlfeParams.fluidSoundSpeed = resolvedControls.fluidSoundSpeed;
                Cp_mps = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, options);
                validMask = isfinite(Cp_mps(:));
            case "acoustoelastic_iop_hgo"
                [params, ~] = guiResolveFitModelSetup(modelFamily, defaultAEParams(), parts);
                frequency_Hz = params.frequency(:);
                options = defaultAEOptions(parts.controls.executionProfile);
                [Cp_mps, rawResult] = aeEvaluateFitModel(params, frequency_Hz, "atlasA0", options);
                validMask = rawResult.validMask(:);
                if ~any(validMask)
                    error('AE atlasA0 produced zero valid points for the current synthetic setup.');
                end
            otherwise
                error('Unsupported fitting model family: %s.', modelFamily);
        end
    end

    function updateModelSpecificControls(modelFamily)
        if modelFamily == "mrlfe"
            visibility = 'on';
        else
            visibility = 'off';
        end
        fitControls.a0PolicyLabel.Visible = visibility;
        fitControls.a0Policy.Visible = visibility;
        fitControls.a0Policy.Enable = visibility;
    end

    function modelFamily = getSelectedModelFamily()
        selectedLabel = string(fitControls.model.Value);
        idx = find(fitControls.modelLabels == selectedLabel, 1, 'first');
        if isempty(idx)
            error('Selected model is not registered: %s.', selectedLabel);
        end
        modelFamily = string(fitControls.modelFamilyIds(idx));
    end

    function family = getSelectedFamily()
        modelFamily = getSelectedModelFamily();
        families = fitControls.registry.modelFamilies;
        for i = 1:numel(families)
            if string(families(i).id) == modelFamily
                family = families(i);
                return;
            end
        end
        error('Selected fitting family is not registered: %s.', modelFamily);
    end

    function params = defaultAEParams()
        params = struct();
        params.R = 7.8e-3;
        params.thickness = 550e-6;
        params.mu = 64e3;
        params.k1 = 50e3;
        params.k2 = 200;
        params.rho = 1060;
        params.rhoF = 1000;
        params.fluidBulkModulus = 2.2e9;
        params.IOP = 15 * 133.322;
        params.frequency = logspace(log10(300), log10(15e3), 35);
    end

    function options = defaultAEOptions(executionProfile)
        [options, ~] = aeResolveExecutionProfile(executionProfile, ...
            'DefaultProfile', "Fast", ...
            'DefaultSource', "FitTool synthetic default");
        options.M54_variant = "corrected";
        options.normalizeRows = false;
        options.usePhysicalCpWindow = false;
        options.atlasBranchPolicy = "atlasA0";
        options.atlasInitializationNumFrequencyPoints = 50;
    end

    function updateStatusFromFitOutput(fitOutput)
        normalized = fitOutput.normalized;
        pathText = getEvaluationPathText(fitOutput);
        curveText = getFullCurveStatusText(normalized);
        header = string(sprintf('Fit status: done | %s %s | RMSE %.4g m/s | %s%s%s', ...
            normalized.modelName, normalized.branchName, normalized.metrics.RMSE, ...
            string(normalized.identifiability.classification), pathText, curveText));
        elapsedLines = [
            "fit elapsed: " + formatSeconds(getFitElapsedSeconds(fitOutput))
            "fitted-curve elapsed: " + formatSeconds(getFullCurveElapsedSeconds(normalized))
            ];
        validCount = nnz(normalized.validMask(:));
        totalCount = numel(normalized.validMask);
        fitLines = fitExtraLines(fitOutput);
        dataLines = dataSourceExtraLines();
        profileLines = guiFormatExecutionProfileDiagnostics(fitOutput.executionProfile, ...
            'Surface', "FitTool", ...
            'Model', normalized.modelName, ...
            'ControlProfile', string(fitOutput.request.controls.executionProfile), ...
            'VisibleBranch', normalized.branchName, ...
            'ValidCount', validCount, ...
            'TotalCount', totalCount, ...
            'ElapsedSeconds', getFitElapsedSeconds(fitOutput), ...
            'ExtraLines', [fitLines(:); dataLines(:)]);
        fitControls.status.Text = strjoin([header; elapsedLines; profileLines(:)], newline);
    end

    function updateStatusFromRequestedCurve(requestedCurve)
        validCount = nnz(requestedCurve.validMask(:));
        totalCount = numel(requestedCurve.validMask);
        extra = [
            "requested curve elapsed: " + formatSeconds(requestedCurve.elapsedSeconds)
            "requested curve points: " + string(totalCount)
            "requested curve valid points: " + string(validCount)
            "requested curve note: " + string(requestedCurve.note)
            ];
        profileMetadata = requestedCurve.executionProfile;
        if isempty(profileMetadata) || ~isstruct(profileMetadata)
            profileMetadata = struct();
        end
        lines = ["Fit status: requested solver curve evaluated with fitted parameters.";
            guiFormatExecutionProfileDiagnostics(profileMetadata, ...
                'Surface', "FitTool requested curve", ...
                'Model', string(requestedCurve.modelFamily), ...
                'ControlProfile', string(lastFitOutput.request.controls.executionProfile), ...
                'VisibleBranch', string(requestedCurve.branchName), ...
                'ValidCount', validCount, ...
                'TotalCount', totalCount, ...
                'ElapsedSeconds', requestedCurve.elapsedSeconds, ...
                'ExtraLines', extra)];
        fitControls.status.Text = strjoin(lines, newline);
    end

    function extra = dataSourceExtraLines()
        extra = strings(0,1);
        if isstruct(lastDataMetadata) && isfield(lastDataMetadata, 'sourceType')
            extra(end+1) = "data source: " + string(lastDataMetadata.sourceType);
        end
        if isstruct(lastDataMetadata) && isfield(lastDataMetadata, 'fileName')
            extra(end+1) = "data file: " + string(lastDataMetadata.fileName);
        end
        extra = extra(:);
    end

    function pathText = getEvaluationPathText(fitOutput)
        pathText = "";
        if isfield(fitOutput, 'fitResult') && isfield(fitOutput.fitResult, 'rawSolverResult') && ...
                isfield(fitOutput.fitResult.rawSolverResult, 'evaluationPath') && ...
                isfield(fitOutput.fitResult.rawSolverResult.evaluationPath, 'path')
            pathText = " | path " + string(fitOutput.fitResult.rawSolverResult.evaluationPath.path);
        end
    end

    function curveText = getFullCurveStatusText(normalized)
        curveText = "";
        if ~isfield(normalized, 'fullCurve') || ~isstruct(normalized.fullCurve)
            return;
        end
        if isfield(normalized.fullCurve, 'note')
            note = string(normalized.fullCurve.note);
            if contains(note, "in-band curve interpolates", 'IgnoreCase', true)
                curveText = curveText + " | curve in-band interpolation";
            elseif contains(note, "dense", 'IgnoreCase', true)
                curveText = curveText + " | curve dense solver";
            end
        end
        if isfield(normalized.fullCurve, 'denseSolver') && isstruct(normalized.fullCurve.denseSolver) && ...
                isfield(normalized.fullCurve.denseSolver, 'hasGridMismatch') && ...
                logical(normalized.fullCurve.denseSolver.hasGridMismatch)
            mismatch = normalized.fullCurve.denseSolver.maxAbsDenseMinusFit_mps;
            curveText = curveText + sprintf(' | dense/grid mismatch %.3g m/s', mismatch);
        end
    end

    function lines = buildSyntheticDiagnosticsStatusLines(modelFamily, branchName, parts, elapsedSeconds, validCount, totalCount)
        metadata = syntheticExecutionProfileMetadata(modelFamily, branchName, parts);
        lines = ["Fit status: synthetic " + string(modelFamily) + " data generated from current setup.";
            guiFormatExecutionProfileDiagnostics(metadata, ...
                'Surface', "FitTool synthetic", ...
                'Model', string(modelFamily), ...
                'ControlProfile', string(parts.controls.executionProfile), ...
                'VisibleBranch', string(branchName), ...
                'ValidCount', validCount, ...
                'TotalCount', totalCount, ...
                'ElapsedSeconds', elapsedSeconds, ...
                'ExtraLines', syntheticExtraLines(modelFamily, parts))];
    end

    function metadata = syntheticExecutionProfileMetadata(modelFamily, branchName, parts)
        switch string(modelFamily)
            case "rayleigh_lamb"
                [~, metadata] = rlResolveExecutionProfile(parts.controls, ...
                    'DefaultProfile', "Fast", 'DefaultSource', "FitTool synthetic default");
            case "mrlfe"
                etaS = getControlField(parts.controls, 'etaS', 0.05);
                [~, metadata] = mrlfeResolveExecutionProfile(branchName, parts.controls, ...
                    'Surface', "fit", ...
                    'DefaultProfile', "Fast", ...
                    'DefaultSource', "FitTool synthetic default", ...
                    'EtaS', etaS, ...
                    'UseUnifiedAtlasRoute', true, ...
                    'A0Policy', string(getControlField(parts.controls, 'mrlfeA0Policy', "adaptivePhysicalTail")));
            case "acoustoelastic_iop_hgo"
                [~, metadata] = aeResolveExecutionProfile(parts.controls, ...
                    'DefaultProfile', "Fast", 'DefaultSource', "FitTool synthetic default");
                metadata.atlasInitializationNumFrequencyPoints = getControlField(parts.controls, ...
                    'atlasInitializationNumFrequencyPoints', 50);
            otherwise
                metadata = struct();
        end
    end

    function extra = syntheticExtraLines(modelFamily, parts)
        extra = strings(0, 1);
        if string(modelFamily) == "mrlfe"
            extra(end+1) = "A0 policy: " + string(getControlField(parts.controls, 'mrlfeA0Policy', "adaptivePhysicalTail"));
        end
        extra = extra(:);
    end

    function extra = fitExtraLines(fitOutput)
        extra = strings(0, 1);
        if isfield(fitOutput, 'routePolicy')
            if isfield(fitOutput.routePolicy, 'actualPath')
                extra(end+1) = "actual route: " + string(fitOutput.routePolicy.actualPath);
            end
            if isfield(fitOutput.routePolicy, 'mrlfeA0Policy')
                extra(end+1) = "A0 policy: " + string(fitOutput.routePolicy.mrlfeA0Policy);
            end
        end
        if isfield(fitOutput, 'fitResult') && isfield(fitOutput.fitResult, 'rawSolverResult') && ...
                isfield(fitOutput.fitResult.rawSolverResult, 'evaluationPath') && ...
                isfield(fitOutput.fitResult.rawSolverResult.evaluationPath, 'fitAtlasPreset')
            extra(end+1) = "fit atlas preset: " + string(fitOutput.fitResult.rawSolverResult.evaluationPath.fitAtlasPreset);
        end
        extra = extra(:);
    end

    function elapsed = getFitElapsedSeconds(fitOutput)
        elapsed = nan;
        if isfield(fitOutput, 'fitElapsedSeconds') && ~isempty(fitOutput.fitElapsedSeconds)
            elapsed = fitOutput.fitElapsedSeconds;
        end
    end

    function elapsed = getFullCurveElapsedSeconds(normalized)
        elapsed = nan;
        if isfield(normalized, 'fullCurve') && isfield(normalized.fullCurve, 'elapsedSeconds')
            elapsed = normalized.fullCurve.elapsedSeconds;
        end
    end

    function text = formatSeconds(elapsed)
        if isfinite(elapsed)
            text = sprintf('%.6g s', elapsed);
        else
            text = 'not available';
        end
    end

    function value = getControlField(controls, fieldName, defaultValue)
        if isstruct(controls) && isfield(controls, fieldName) && ~isempty(controls.(fieldName))
            value = controls.(fieldName);
        else
            value = defaultValue;
        end
    end
end
