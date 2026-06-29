function FitTool_GUI()
%FITTOOL_GUI Minimal visual interface for experimental dispersion fitting.
%
% This GUI uses the app-level fitting backend from app/fitting and does not
% implement model-specific fitting algorithms.

lastFitOutput = [];

fig = uifigure('Name', 'Experimental Dispersion Fitting Tool', 'Position', [120 120 1180 720]);
root = uigridlayout(fig, [1 2]);
root.ColumnWidth = {520, '1x'};
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
        freeParams = getValidatedVisibleFreeParams(modelFamily);
        fitControls.freeParam.Items = cellstr(freeParams);
        fitControls.freeParam.Value = char(freeParams(1));
        onFitParameterChanged();
        fitControls.status.Text = sprintf('Fit status: selected model %s.', string(family.label));
    end

    function onFitParameterChanged()
        modelFamily = getSelectedModelFamily();
        freeParam = string(fitControls.freeParam.Value);
        config = getParameterDisplayConfig(modelFamily, freeParam);
        fitControls.initialGuessLabel.Text = sprintf('Initial %s [%s]', config.label, config.displayUnit);
        fitControls.lowerBoundLabel.Text = sprintf('Lower %s [%s]', config.label, config.displayUnit);
        fitControls.upperBoundLabel.Text = sprintf('Upper %s [%s]', config.label, config.displayUnit);
        fitControls.initialGuess.Value = config.initialDisplay;
        fitControls.lowerBound.Value = config.lowerDisplay;
        fitControls.upperBound.Value = config.upperDisplay;
        updateFixedExtraControls(modelFamily, freeParam);
        fitControls.fixedHeader.Text = getFixedSummary(modelFamily, freeParam);
    end

    function onPopulateFitData()
        try
            modelFamily = getSelectedModelFamily();
            freeParam = string(fitControls.freeParam.Value);
            branchName = string(fitControls.branch.Value);
            [frequency_Hz, Cp_mps, validMask] = generateSyntheticData(modelFamily, branchName, freeParam);
            fitControls.dataTable.Data = [frequency_Hz(:), Cp_mps(:), double(validMask(:))];
            fitControls.status.Text = sprintf('Fit status: synthetic %s data generated.', modelFamily);
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
        freeParam = string(fitControls.freeParam.Value);
        [fixedParams, initialGuess, bounds, controls, fitOptions] = buildParameterConfig(modelFamily, freeParam);
        request = guiBuildFitRequest(modelFamily, ...
            'branchName', string(fitControls.branch.Value), ...
            'mode', "basic", ...
            'experimental', experimental, ...
            'fixedParams', fixedParams, ...
            'freeParams', freeParam, ...
            'initialGuess', initialGuess, ...
            'bounds', bounds, ...
            'controls', controls, ...
            'fitOptions', fitOptions);
    end

    function experimental = readExperimentalData()
        data = fitControls.dataTable.Data;
        if istable(data)
            data = table2array(data);
        end
        if ~isnumeric(data) || size(data, 2) < 2
            error('Experimental table must contain numeric frequency_Hz and Cp_mps columns.');
        end
        frequency_Hz = data(:, 1);
        Cp_mps = data(:, 2);
        if size(data, 2) >= 3
            validMask = logical(data(:, 3));
        else
            validMask = true(size(frequency_Hz));
        end
        experimental = struct();
        experimental.frequency_Hz = frequency_Hz;
        experimental.Cp_mps = Cp_mps;
        experimental.validMask = validMask;
    end

    function [fixedParams, initialGuess, bounds, controls, fitOptions] = buildParameterConfig(modelFamily, freeParam)
        initialValue = convertDisplayToSolver(modelFamily, freeParam, fitControls.initialGuess.Value);
        lowerValue = convertDisplayToSolver(modelFamily, freeParam, fitControls.lowerBound.Value);
        upperValue = convertDisplayToSolver(modelFamily, freeParam, fitControls.upperBound.Value);
        if lowerValue >= upperValue
            error('Lower bound must be smaller than upper bound.');
        end

        initialGuess = struct();
        initialGuess.(char(freeParam)) = initialValue;
        bounds = struct();
        bounds.(char(freeParam)) = [lowerValue, upperValue];
        controls = struct('robustness', string(fitControls.robustness.Value));
        fitOptions = struct('useStandardErrorWeights', false);

        switch modelFamily
            case "rayleigh_lamb"
                params = rlDefaultParams();
                fixedParams = struct('rho', params.rho, 'nu', params.nu);
                if freeParam == "mu"
                    fixedParams.thickness = params.thickness;
                elseif freeParam == "thickness"
                    fixedParams.mu = params.mu;
                else
                    error('Unsupported Rayleigh-Lamb visible free parameter: %s.', freeParam);
                end
            case "mrlfe"
                params = mrlfeDefaultSweepParams();
                fixedParams = struct('rho', params.rho, 'nu', params.nu);
                if freeParam ~= "mu"
                    fixedParams.mu = params.mu;
                end
                if freeParam ~= "thickness"
                    fixedParams.thickness = params.thickness;
                end
                if freeParam == "etaS"
                    controls.etaS = initialValue;
                else
                    controls.etaS = getFixedEtaSValue();
                end
                controls.fluidDensity = 1000;
                controls.fluidSoundSpeed = 1500;
                controls.mrlfeUseUnifiedAtlasRoute = true;
                controls.mrlfeA0Policy = string(fitControls.a0Policy.Value);
                fitOptions.optimizerOptions = optimset('Display', 'off', 'MaxIter', 35, 'MaxFunEvals', 80, 'TolX', 1e-5);
            case "acoustoelastic_iop_hgo"
                params = defaultAEParams();
                fixedParams = rmfield(params, {'frequency', char(freeParam)});
                controls.atlasNumYPoints = 300;
                controls.atlasTopNMinima = 12;
                controls.atlasInitializationNumFrequencyPoints = 50;
                fitOptions.optimizerOptions = optimset('Display', 'off', 'MaxIter', 10, 'MaxFunEvals', 24, 'TolX', 1e-3);
                if freeParam == "thickness"
                    fitOptions.optimizerOptions = optimset('Display', 'off', 'MaxIter', 10, 'MaxFunEvals', 24, 'TolX', 1e-8);
                end
            otherwise
                error('Unsupported fitting model family: %s.', modelFamily);
        end
    end

    function [frequency_Hz, Cp_mps, validMask] = generateSyntheticData(modelFamily, branchName, freeParam)
        value = convertDisplayToSolver(modelFamily, freeParam, fitControls.initialGuess.Value);
        switch modelFamily
            case "rayleigh_lamb"
                params = rlDefaultParams();
                params.(char(freeParam)) = value;
                frequency_Hz = linspace(1000, 8000, 12).';
                options = rlDefaultOptions(string(fitControls.robustness.Value));
                Cp_mps = rlEvaluateFitModel(params, frequency_Hz, branchName, options);
                validMask = isfinite(Cp_mps(:));
            case "mrlfe"
                params = mrlfeDefaultSweepParams();
                params.(char(freeParam)) = value;
                frequency_Hz = linspace(1000, 8000, 10).';
                if freeParam == "etaS"
                    etaSForSynthetic = value;
                else
                    etaSForSynthetic = getFixedEtaSValue();
                    params.etaS = etaSForSynthetic;
                end
                options = mrlfeDefaultSweepOptions(branchName, 'EtaS', etaSForSynthetic, ...
                    'UseUnifiedAtlasRoute', true, 'A0Policy', string(fitControls.a0Policy.Value));
                Cp_mps = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, options);
                validMask = isfinite(Cp_mps(:));
            case "acoustoelastic_iop_hgo"
                params = defaultAEParams();
                params.(char(freeParam)) = value;
                frequency_Hz = params.frequency(:);
                options = defaultAEOptions();
                [Cp_mps, rawResult] = aeEvaluateFitModel(params, frequency_Hz, "atlasA0", options);
                validMask = rawResult.validMask(:);
                if ~any(validMask)
                    error('AE atlasA0 produced zero valid points for the current synthetic setup.');
                end
            otherwise
                error('Unsupported fitting model family: %s.', modelFamily);
        end
    end

    function updateFixedExtraControls(modelFamily, freeParam)
        showFixedEtaS = modelFamily == "mrlfe" && freeParam ~= "etaS";
        if showFixedEtaS
            fitControls.fixedEtaSLabel.Visible = 'on';
            fitControls.fixedEtaS.Visible = 'on';
            fitControls.fixedEtaS.Enable = 'on';
        else
            fitControls.fixedEtaSLabel.Visible = 'off';
            fitControls.fixedEtaS.Visible = 'off';
            fitControls.fixedEtaS.Enable = 'off';
        end
        showA0Policy = modelFamily == "mrlfe";
        if showA0Policy
            fitControls.a0PolicyLabel.Visible = 'on';
            fitControls.a0Policy.Visible = 'on';
            fitControls.a0Policy.Enable = 'on';
        else
            fitControls.a0PolicyLabel.Visible = 'off';
            fitControls.a0Policy.Visible = 'off';
            fitControls.a0Policy.Enable = 'off';
        end
    end

    function etaS = getFixedEtaSValue()
        etaS = fitControls.fixedEtaS.Value;
        if isempty(etaS) || ~isfinite(etaS) || etaS < 0
            error('Fixed etaS must be a finite nonnegative value.');
        end
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
            if families(i).id == modelFamily
                family = families(i);
                return;
            end
        end
        error('Selected fitting family is not registered: %s.', modelFamily);
    end

    function freeParams = getValidatedVisibleFreeParams(modelFamily)
        switch modelFamily
            case "rayleigh_lamb"
                freeParams = ["mu", "thickness"];
            case "mrlfe"
                freeParams = ["mu", "thickness", "etaS"];
            case "acoustoelastic_iop_hgo"
                freeParams = ["mu", "thickness", "IOP"];
            otherwise
                error('Unsupported fitting model family: %s.', modelFamily);
        end
    end

    function config = getParameterDisplayConfig(modelFamily, freeParam)
        switch modelFamily
            case "rayleigh_lamb"
                params = rlDefaultParams();
                switch freeParam
                    case "mu"
                        config = makeDisplayConfig('mu', 'kPa', 1e3, params.mu, [0.20 * params.mu, 5.0 * params.mu]);
                    case "thickness"
                        config = makeDisplayConfig('2h', 'mm', 1e-3, params.thickness, [0.20 * params.thickness, 5.0 * params.thickness]);
                    otherwise
                        error('Unsupported Rayleigh-Lamb free parameter: %s.', freeParam);
                end
            case "mrlfe"
                params = mrlfeDefaultSweepParams();
                switch freeParam
                    case "mu"
                        config = makeDisplayConfig('mu', 'kPa', 1e3, params.mu, [20e3, 160e3]);
                    case "thickness"
                        config = makeDisplayConfig('2h', 'mm', 1e-3, params.thickness, [0.25e-3, 1.00e-3]);
                    case "etaS"
                        config = makeDisplayConfig('etaS', 'Pa*s', 1, 0.12, [0.0, 0.30]);
                    otherwise
                        error('Unsupported mRLFE free parameter: %s.', freeParam);
                end
            case "acoustoelastic_iop_hgo"
                params = defaultAEParams();
                switch freeParam
                    case "mu"
                        config = makeDisplayConfig('mu', 'kPa', 1e3, params.mu, [45e3, 55e3]);
                    case "thickness"
                        config = makeDisplayConfig('2h', 'um', 1e-6, params.thickness, [480e-6, 620e-6]);
                    case "IOP"
                        config = makeDisplayConfig('IOP', 'mmHg', 133.322, params.IOP, [10, 20] * 133.322);
                    otherwise
                        error('Unsupported AE IOP/HGO free parameter: %s.', freeParam);
                end
            otherwise
                error('Unsupported fitting model family: %s.', modelFamily);
        end
    end

    function config = makeDisplayConfig(label, displayUnit, displayScale, initialValue, solverBounds)
        config = struct();
        config.label = label;
        config.displayUnit = displayUnit;
        config.displayScale = displayScale;
        config.initialDisplay = initialValue ./ displayScale;
        config.lowerDisplay = solverBounds(1) ./ displayScale;
        config.upperDisplay = solverBounds(2) ./ displayScale;
    end

    function value = convertDisplayToSolver(modelFamily, freeParam, displayValue)
        config = getParameterDisplayConfig(modelFamily, freeParam);
        value = displayValue .* config.displayScale;
    end

    function text = getFixedSummary(modelFamily, freeParam)
        switch modelFamily
            case "rayleigh_lamb"
                params = rlDefaultParams();
                if freeParam == "mu"
                    text = sprintf('Fixed: rho %.0f kg/m^3 | nu %.5f | 2h %.3f mm', params.rho, params.nu, params.thickness * 1e3);
                else
                    text = sprintf('Fixed: rho %.0f kg/m^3 | nu %.5f | mu %.3f kPa', params.rho, params.nu, params.mu / 1e3);
                end
            case "mrlfe"
                params = mrlfeDefaultSweepParams();
                switch freeParam
                    case "mu"
                        text = sprintf('Fixed: etaS %.4g Pa*s | rho %.0f kg/m^3 | nu %.5f | 2h %.3f mm', getFixedEtaSValue(), params.rho, params.nu, params.thickness * 1e3);
                    case "thickness"
                        text = sprintf('Fixed: etaS %.4g Pa*s | rho %.0f kg/m^3 | nu %.5f | mu %.3f kPa', getFixedEtaSValue(), params.rho, params.nu, params.mu / 1e3);
                    case "etaS"
                        text = sprintf('Fixed: rho %.0f kg/m^3 | nu %.5f | mu %.3f kPa | 2h %.3f mm', params.rho, params.nu, params.mu / 1e3, params.thickness * 1e3);
                    otherwise
                        text = 'Fixed: mRLFE defaults.';
                end
            case "acoustoelastic_iop_hgo"
                params = defaultAEParams();
                switch freeParam
                    case "mu"
                        text = sprintf('Fixed: IOP %.1f mmHg | 2h %.0f um | R %.2f mm | atlasA0', params.IOP / 133.322, params.thickness * 1e6, params.R * 1e3);
                    case "thickness"
                        text = sprintf('Fixed: IOP %.1f mmHg | mu %.1f kPa | R %.2f mm | atlasA0', params.IOP / 133.322, params.mu / 1e3, params.R * 1e3);
                    case "IOP"
                        text = sprintf('Fixed: mu %.1f kPa | 2h %.0f um | R %.2f mm | atlasA0', params.mu / 1e3, params.thickness * 1e6, params.R * 1e3);
                    otherwise
                        text = 'Fixed: AE IOP/HGO atlasA0 defaults.';
                end
            otherwise
                text = 'Fixed: unavailable.';
        end
    end

    function params = defaultAEParams()
        params = struct();
        params.R = 7.8e-3;
        params.thickness = 550e-6;
        params.mu = 50e3;
        params.k1 = 25e3;
        params.k2 = 100;
        params.rho = 1060;
        params.rhoF = 1000;
        params.fluidBulkModulus = 2.2e9;
        params.IOP = 15 * 133.322;
        params.frequency = logspace(log10(300), log10(15e3), 35);
    end

    function options = defaultAEOptions()
        options = defaultAcoustoelasticIOPHGOOptions();
        options.M54_variant = "corrected";
        options.normalizeRows = false;
        options.usePhysicalCpWindow = false;
        options.atlasNumYPoints = 300;
        options.atlasTopNMinima = 12;
        options.atlasBranchPolicy = "atlasA0";
        options.atlasInitializationNumFrequencyPoints = 50;
    end

    function updateStatusFromFitOutput(fitOutput)
        normalized = fitOutput.normalized;
        pathText = getEvaluationPathText(fitOutput);
        curveText = getFullCurveStatusText(normalized);
        statusText = sprintf('Fit status: done | %s %s | RMSE %.4g m/s | %s%s%s', ...
            normalized.modelName, normalized.branchName, normalized.metrics.RMSE, ...
            string(normalized.identifiability.classification), pathText, curveText);
        fitControls.status.Text = statusText;
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

        if isfield(normalized.fullCurve, 'extension') && isstruct(normalized.fullCurve.extension) && ...
                isfield(normalized.fullCurve.extension, 'errorMessage')
            extensionMessage = string(normalized.fullCurve.extension.errorMessage);
            if strlength(extensionMessage) > 0 && contains(extensionMessage, "skipped", 'IgnoreCase', true)
                curveText = curveText + " | extension skipped";
            end
        end
    end
end
