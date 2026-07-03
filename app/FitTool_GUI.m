function FitTool_GUI()
%FITTOOL_GUI Visual interface for one-parameter experimental dispersion fitting.

lastFitOutput = [];
fitParameterState = struct();

fig = uifigure('Name', 'Experimental Dispersion Fitting Tool', 'Position', [120 120 1280 760]);
root = uigridlayout(fig, [1 2]);
root.ColumnWidth = {620, '1x'};
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
callbacks.onPopulateFitData = @(~,~)onPopulateFitData();
callbacks.onResetDefaults = @(~,~)onResetDefaults();
callbacks.onRunFit = @(~,~)onRunFit();
fitControls = createFittingTab(tabs, rlDefaultParams(), callbacks);

rightGrid = uigridlayout(root, [2 1]);
rightGrid.Layout.Column = 2;
rightGrid.RowHeight = {'1x', 150};
rightGrid.Padding = [0 0 0 0];
rightGrid.RowSpacing = 8;

ax = uiaxes(rightGrid);
ax.Layout.Row = 1;
grid(ax, 'on');
xlabel(ax, 'Frequency [kHz]');
ylabel(ax, 'Phase speed [m/s]');
title(ax, 'Experimental fit');

resultTable = uitable(rightGrid, 'Data', table(), 'ColumnName', {});
resultTable.Layout.Row = 2;

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
            'Free parameter: %s. All other rows are fixed and editable.', fitParameterState.freeParam);
    end

    function state = readParameterState()
        if isempty(fitParameterState) || ~isstruct(fitParameterState) || ~isfield(fitParameterState, 'parameters')
            state = guiBuildFitParameterState(getSelectedModelFamily(), string(fitControls.freeParam.Value));
            return;
        end
        state = guiApplyFitParameterTable(fitParameterState, fitControls.parameterTable.Data);
    end

    function onPopulateFitData()
        try
            requestParts = buildParameterConfig();
            modelFamily = getSelectedModelFamily();
            branchName = string(fitControls.branch.Value);
            [frequency_Hz, Cp_mps, validMask] = generateSyntheticData(modelFamily, branchName, requestParts);
            fitControls.dataTable.Data = [frequency_Hz(:), Cp_mps(:), double(validMask(:))];
            fitControls.status.Text = sprintf('Fit status: synthetic %s data generated from current setup.', modelFamily);
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
            guiPlotFitResult(lastFitOutput.normalized, ax);
            resultTable.Data = lastFitOutput.normalized.summaryTable;
            resultTable.ColumnName = lastFitOutput.normalized.summaryTable.Properties.VariableNames;
            updateStatusFromFitOutput(lastFitOutput);
            assignin('base', 'FitToolLastOutput', lastFitOutput);
        catch ME
            fitControls.status.Text = ['Fit status: error: ', ME.message];
            uialert(fig, ME.message, 'Fitting error');
        end
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
        experimental = struct();
        experimental.frequency_Hz = data(:, 1);
        experimental.Cp_mps = data(:, 2);
        if size(data, 2) >= 3
            experimental.validMask = logical(data(:, 3));
        else
            experimental.validMask = true(size(data, 1), 1);
        end
    end

    function [frequency_Hz, Cp_mps, validMask] = generateSyntheticData(modelFamily, branchName, parts)
        switch modelFamily
            case "rayleigh_lamb"
                [params, resolvedControls] = guiResolveFitModelSetup(modelFamily, rlDefaultParams(), parts);
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
        fitControls.status.Text = string(sprintf('Fit status: done | %s %s | RMSE %.4g m/s | %s%s%s', ...
            normalized.modelName, normalized.branchName, normalized.metrics.RMSE, ...
            string(normalized.identifiability.classification), pathText, curveText)) + getProfileStatusText(fitOutput);
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

    function profileText = getProfileStatusText(fitOutput)
        profileText = "";
        if ~isfield(fitOutput, 'executionProfile') || ~isstruct(fitOutput.executionProfile)
            return;
        end
        profile = fitOutput.executionProfile;
        if isfield(profile, 'profileOverrideApplied') && logical(profile.profileOverrideApplied)
            profileText = sprintf(' | profile %s->%s', ...
                string(profile.requestedExecutionProfile), string(profile.effectiveExecutionProfile));
        end
    end
end
