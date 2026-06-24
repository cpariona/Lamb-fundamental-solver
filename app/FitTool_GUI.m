function FitTool_GUI()
%FITTOOL_GUI Minimal visual interface for experimental dispersion fitting.
%
% This GUI is intentionally small. It uses the app-level fitting backend from
% app/fitting and does not implement model-specific fitting logic.

params0 = rlDefaultParams();
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
callbacks.onFitParameterChanged = @(~,~)onFitParameterChanged();
callbacks.onPopulateFitData = @(~,~)onPopulateFitData();
callbacks.onRunFit = @(~,~)onRunFit();

fitControls = createFittingTab(tabs, params0, callbacks);

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

onFitParameterChanged();

    function onFitParameterChanged()
        freeParam = string(fitControls.freeParam.Value);
        switch freeParam
            case "mu"
                fitControls.initialGuessLabel.Text = 'Initial mu [kPa]';
                fitControls.lowerBoundLabel.Text = 'Lower mu [kPa]';
                fitControls.upperBoundLabel.Text = 'Upper mu [kPa]';
                fitControls.initialGuess.Value = params0.mu / 1e3;
                fitControls.lowerBound.Value = max(1, 0.20 * params0.mu / 1e3);
                fitControls.upperBound.Value = 5.0 * params0.mu / 1e3;
                fitControls.fixedHeader.Text = sprintf('Fixed: rho %.0f kg/m^3 | nu %.5f | 2h %.3f mm', ...
                    params0.rho, params0.nu, params0.thickness * 1e3);
            case "thickness"
                fitControls.initialGuessLabel.Text = 'Initial 2h [mm]';
                fitControls.lowerBoundLabel.Text = 'Lower 2h [mm]';
                fitControls.upperBoundLabel.Text = 'Upper 2h [mm]';
                fitControls.initialGuess.Value = params0.thickness * 1e3;
                fitControls.lowerBound.Value = max(0.01, 0.20 * params0.thickness * 1e3);
                fitControls.upperBound.Value = 5.0 * params0.thickness * 1e3;
                fitControls.fixedHeader.Text = sprintf('Fixed: rho %.0f kg/m^3 | nu %.5f | mu %.3f kPa', ...
                    params0.rho, params0.nu, params0.mu / 1e3);
        end
    end

    function onPopulateFitData()
        try
            params = params0;
            freeParam = string(fitControls.freeParam.Value);
            switch freeParam
                case "mu"
                    params.mu = fitControls.initialGuess.Value * 1e3;
                case "thickness"
                    params.thickness = fitControls.initialGuess.Value * 1e-3;
            end
            frequency_Hz = linspace(1000, 8000, 12).';
            branchName = string(fitControls.branch.Value);
            options = rlDefaultOptions(string(fitControls.robustness.Value));
            Cp_mps = rlEvaluateFitModel(params, frequency_Hz, branchName, options);
            fitControls.dataTable.Data = [frequency_Hz, Cp_mps(:), ones(size(frequency_Hz))];
            fitControls.status.Text = 'Fit status: synthetic data generated from current fitting controls.';
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
        experimental = readExperimentalData();
        freeParam = string(fitControls.freeParam.Value);
        [fixedParams, initialGuess, bounds] = buildParameterConfig(freeParam);
        request = guiBuildFitRequest('rayleigh_lamb', ...
            'branchName', string(fitControls.branch.Value), ...
            'mode', "basic", ...
            'experimental', experimental, ...
            'fixedParams', fixedParams, ...
            'freeParams', freeParam, ...
            'initialGuess', initialGuess, ...
            'bounds', bounds, ...
            'controls', struct('robustness', string(fitControls.robustness.Value)), ...
            'fitOptions', struct('useStandardErrorWeights', false));
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

    function [fixedParams, initialGuess, bounds] = buildParameterConfig(freeParam)
        fixedParams = struct('rho', params0.rho, 'nu', params0.nu);
        initialGuess = struct();
        bounds = struct();
        switch freeParam
            case "mu"
                fixedParams.thickness = params0.thickness;
                initialGuess.mu = fitControls.initialGuess.Value * 1e3;
                bounds.mu = [fitControls.lowerBound.Value, fitControls.upperBound.Value] * 1e3;
            case "thickness"
                fixedParams.mu = params0.mu;
                initialGuess.thickness = fitControls.initialGuess.Value * 1e-3;
                bounds.thickness = [fitControls.lowerBound.Value, fitControls.upperBound.Value] * 1e-3;
            otherwise
                error('Unsupported free parameter: %s.', freeParam);
        end
    end

    function updateStatusFromFitOutput(fitOutput)
        normalized = fitOutput.normalized;
        statusText = sprintf('Fit status: done | %s %s | RMSE %.4g m/s | %s', ...
            normalized.modelName, normalized.branchName, normalized.metrics.RMSE, ...
            string(normalized.identifiability.classification));
        fitControls.status.Text = statusText;
    end
end
