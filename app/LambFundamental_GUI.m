function LambFundamental_GUI
% GUI shell for fundamental Lamb modes (Cp only) using modular backend.

%% Default values
defaults = defaultParams();
defaultSolverOptions = defaultOptions("Balanced");
lastResults = [];
lastOptions = [];
inputsAreDirty = false;

colors.A0 = [0.0000, 0.4470, 0.7410];
colors.S0 = [1.0000, 0.0000, 0.0000];

%% Main layout
fig = uifigure('Name', 'Fundamental Lamb Wave Phase Velocity Calculator', ...
    'Position', [100 100 1320 760]);

mainLayout = uigridlayout(fig, [1 2]);
mainLayout.ColumnWidth = {390, '1x'};

leftPanel = uipanel(mainLayout, 'Title', 'Input parameters');
leftPanel.Layout.Column = 1;
leftLayout = uigridlayout(leftPanel, [2 1]);
leftLayout.RowHeight = {'1x', 220};
leftLayout.RowSpacing = 8;
leftLayout.Padding = [5 5 5 5];

%% Tabs
tabs = uitabgroup(leftLayout);
tabs.Layout.Row = 1;

% Material tab
tabMaterial = uitab(tabs, 'Title', 'Material');
matGrid = uigridlayout(tabMaterial, [11 2]);
matGrid.ColumnWidth = {170, '1x'};
matGrid.RowHeight = repmat({32}, 1, 11);
matGrid.Padding = [12 12 12 12];

uilabel(matGrid, 'Text', 'Input model');
modelDropDown = uidropdown(matGrid, 'Items', {'YoungPoissonFixedCL', 'LameParameters'}, ...
    'Value', char(defaults.modelType), 'ValueChangedFcn', @(~,~)onMaterialModelChanged());

uilabel(matGrid, 'Text', 'rho [kg/m^3]');
rhoField = uieditfield(matGrid, 'numeric', 'Value', defaults.rho, 'Limits', [0 Inf], ...
    'ValueChangedFcn', @(~,~)markInputsDirty());

ELabel = uilabel(matGrid, 'Text', 'E [kPa]');
EField = uieditfield(matGrid, 'numeric', 'Value', defaults.E/1e3, 'Limits', [0 Inf], ...
    'ValueChangedFcn', @(~,~)markInputsDirty());

nuLabel = uilabel(matGrid, 'Text', 'nu [-]');
nuField = uieditfield(matGrid, 'numeric', 'Value', defaults.nu, 'Limits', [0 0.5], ...
    'ValueChangedFcn', @(~,~)markInputsDirty());

CLLabel = uilabel(matGrid, 'Text', 'CL [m/s]');
CLField = uieditfield(matGrid, 'numeric', 'Value', defaults.CL, 'Limits', [0 Inf], ...
    'ValueChangedFcn', @(~,~)markInputsDirty());

lambdaLabel = uilabel(matGrid, 'Text', 'lambda [MPa]');
lambdaField = uieditfield(matGrid, 'numeric', 'Value', defaults.lambda/1e6, 'Limits', [0 Inf], ...
    'ValueChangedFcn', @(~,~)markInputsDirty());

muLabel = uilabel(matGrid, 'Text', 'mu [kPa]');
muField = uieditfield(matGrid, 'numeric', 'Value', defaults.mu/1e3, 'Limits', [0 Inf], ...
    'ValueChangedFcn', @(~,~)markInputsDirty());

uilabel(matGrid, 'Text', ''); uilabel(matGrid, 'Text', '');

% Geometry/Frequency tab
tabGeo = uitab(tabs, 'Title', 'Geometry / Frequency');
geoGrid = uigridlayout(tabGeo, [6 2]);
geoGrid.ColumnWidth = {170, '1x'};
geoGrid.RowHeight = repmat({32}, 1, 6);
geoGrid.Padding = [12 12 12 12];

uilabel(geoGrid, 'Text', 'thickness [mm]');
thicknessField = uieditfield(geoGrid, 'numeric', 'Value', defaults.thickness*1e3, 'Limits', [0 Inf], ...
    'ValueChangedFcn', @(~,~)markInputsDirty());
uilabel(geoGrid, 'Text', 'fmin [Hz]');
fminField = uieditfield(geoGrid, 'numeric', 'Value', defaults.fmin, 'Limits', [eps Inf], ...
    'ValueChangedFcn', @(~,~)markInputsDirty());
uilabel(geoGrid, 'Text', 'fmax [Hz]');
fmaxField = uieditfield(geoGrid, 'numeric', 'Value', defaults.fmax, 'Limits', [eps Inf], ...
    'ValueChangedFcn', @(~,~)markInputsDirty());
uilabel(geoGrid, 'Text', 'N frequency points');
nfField = uieditfield(geoGrid, 'numeric', 'Value', defaults.numFrequencyPoints, ...
    'RoundFractionalValues', 'on', 'Limits', [10 50000], 'ValueChangedFcn', @(~,~)markInputsDirty());
uilabel(geoGrid, 'Text', 'frequency spacing');
spacingDropDown = uidropdown(geoGrid, 'Items', {'logspace', 'linspace'}, ...
    'Value', char(defaults.frequencySpacing), 'ValueChangedFcn', @(~,~)markInputsDirty());

% Modes tab
tabModes = uitab(tabs, 'Title', 'Modes');
modesGrid = uigridlayout(tabModes, [8 1]);
modesGrid.RowHeight = {24, 30, 30, 20, 24, 30, 30, '1x'};
modesGrid.Padding = [12 12 12 12];

uilabel(modesGrid, 'Text', 'Modes to compute', 'FontWeight', 'bold');
A0Check = uicheckbox(modesGrid, 'Text', 'A0', 'Value', defaultSolverOptions.computeA0, ...
    'ValueChangedFcn', @(~,~)markInputsDirty());
S0Check = uicheckbox(modesGrid, 'Text', 'S0 experimental', 'Value', defaultSolverOptions.computeS0, ...
    'ValueChangedFcn', @(~,~)markInputsDirty());
uilabel(modesGrid, 'Text', '');
uilabel(modesGrid, 'Text', 'Modes to display', 'FontWeight', 'bold');
A0DisplayCheck = uicheckbox(modesGrid, 'Text', 'Show A0', 'Value', true, ...
    'ValueChangedFcn', @(~,~)refreshPlotOnly());
S0DisplayCheck = uicheckbox(modesGrid, 'Text', 'Show S0 experimental', 'Value', true, ...
    'ValueChangedFcn', @(~,~)refreshPlotOnly());
uilabel(modesGrid, 'Text', 'Display controls only affect the current plot. Recompute after changing material, geometry, frequency, compute modes, or robustness.', ...
    'WordWrap', 'on', 'FontAngle', 'italic');

% Plot tab
tabPlot = uitab(tabs, 'Title', 'Plot');
plotGrid = uigridlayout(tabPlot, [9 2]);
plotGrid.ColumnWidth = {150, '1x'};
plotGrid.RowHeight = repmat({30}, 1, 9);
plotGrid.Padding = [12 12 12 12];

uilabel(plotGrid, 'Text', 'x-axis');
xAxisDropDown = uidropdown(plotGrid, 'Items', {'frequency', 'angularFrequency', 'wavenumber', 'kThickness'}, ...
    'Value', 'frequency', 'ValueChangedFcn', @(~,~)refreshPlotOnly());
uilabel(plotGrid, 'Text', 'y-axis');
uilabel(plotGrid, 'Text', 'Cp');
autoAxesCheck = uicheckbox(plotGrid, 'Text', 'auto axes', 'Value', true, ...
    'ValueChangedFcn', @(~,~)onAutoAxesChanged());
autoAxesCheck.Layout.Column = [1 2];
uilabel(plotGrid, 'Text', 'x min');
xMinField = uieditfield(plotGrid, 'numeric', 'Value', 0, 'ValueChangedFcn', @(~,~)refreshPlotOnly());
uilabel(plotGrid, 'Text', 'x max');
xMaxField = uieditfield(plotGrid, 'numeric', 'Value', 0, 'ValueChangedFcn', @(~,~)refreshPlotOnly());
uilabel(plotGrid, 'Text', 'y min');
yMinField = uieditfield(plotGrid, 'numeric', 'Value', 0, 'ValueChangedFcn', @(~,~)refreshPlotOnly());
uilabel(plotGrid, 'Text', 'y max');
yMaxField = uieditfield(plotGrid, 'numeric', 'Value', 0, 'ValueChangedFcn', @(~,~)refreshPlotOnly());
resetAxesButton = uibutton(plotGrid, 'Text', 'Reset axes to computed range', 'ButtonPushedFcn', @(~,~)resetAxes());
resetAxesButton.Layout.Column = [1 2];

% Numerical tab
tabNumerical = uitab(tabs, 'Title', 'Numerical');
numGrid = uigridlayout(tabNumerical, [5 2]);
numGrid.ColumnWidth = {150, '1x'};
numGrid.RowHeight = {30, 30, 70, 30, '1x'};
numGrid.Padding = [12 12 12 12];

uilabel(numGrid, 'Text', 'robustness');
robustnessDropDown = uidropdown(numGrid, 'Items', {'Fast', 'Balanced', 'Robust'}, ...
    'Value', 'Balanced', 'ValueChangedFcn', @(~,~)markInputsDirty());
uilabel(numGrid, 'Text', 'preset effect');
uilabel(numGrid, 'Text', 'Fast uses fewer scan points. Robust uses more points and wider search windows.', ...
    'WordWrap', 'on');
uilabel(numGrid, 'Text', 'advanced settings');
uilabel(numGrid, 'Text', 'Hidden for now; edit defaultOptions.m for detailed numerical tuning.', ...
    'WordWrap', 'on', 'FontAngle', 'italic');

%% Run / Export fixed section
actionPanel = uipanel(leftLayout, 'Title', 'Run / Export');
actionPanel.Layout.Row = 2;
actionGrid = uigridlayout(actionPanel, [5 1]);
actionGrid.RowHeight = {34, 34, 90, '1x', 44};
actionGrid.Padding = [10 10 10 10];

uibutton(actionGrid, 'Text', 'Compute selected modes', 'ButtonPushedFcn', @(~,~)onCompute());
uibutton(actionGrid, 'Text', 'Export results', 'ButtonPushedFcn', @(~,~)onExport());
materialInfoLabel = uilabel(actionGrid, 'Text', 'Material info will appear here.', 'WordWrap', 'on');
statusLabel = uilabel(actionGrid, 'Text', 'Ready.', 'WordWrap', 'on');

%% Right plot
axCp = uiaxes(mainLayout);
axCp.Layout.Column = 2;
grid(axCp, 'on');
xlabel(axCp, 'frequency [Hz]');
ylabel(axCp, 'Phase velocity Cp [m/s]');
title(axCp, 'Fundamental Lamb modes (Cp)');

updateMaterialInputState();
updateAxisFieldState();

    function onMaterialModelChanged()
        updateMaterialInputState();
        markInputsDirty();
    end

    function updateMaterialInputState()
        modelType = string(modelDropDown.Value);
        ypOn = modelType == "YoungPoissonFixedCL";

        ELabel.Enable = onOff(ypOn); EField.Enable = onOff(ypOn);
        nuLabel.Enable = onOff(ypOn); nuField.Enable = onOff(ypOn);
        CLLabel.Enable = onOff(ypOn); CLField.Enable = onOff(ypOn);

        lambdaLabel.Enable = onOff(~ypOn); lambdaField.Enable = onOff(~ypOn);
        muLabel.Enable = onOff(~ypOn); muField.Enable = onOff(~ypOn);
    end

    function markInputsDirty()
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
            options = defaultOptions(string(robustnessDropDown.Value));
            options.computeA0 = logical(A0Check.Value);
            options.computeS0 = logical(S0Check.Value);

            lastResults = computeFundamentalLambModes(params, options);
            lastOptions = options;
            inputsAreDirty = false;

            A0DisplayCheck.Value = isfield(lastResults.modes, 'A0');
            S0DisplayCheck.Value = isfield(lastResults.modes, 'S0') && any(isfinite(lastResults.modes.S0.Cp));

            updatePlot(lastResults);
            updateLabels(lastResults, options);

        catch ME
            statusLabel.Text = ['Error: ', ME.message];
            uialert(fig, ME.message, 'Compute error');
        end
    end

    function params = readParamsFromGui()
        params = defaultParams();
        params.modelType = string(modelDropDown.Value);
        params.rho = rhoField.Value;
        params.E = EField.Value * 1e3;
        params.nu = nuField.Value;
        params.CL = CLField.Value;
        params.lambda = lambdaField.Value * 1e6;
        params.mu = muField.Value * 1e3;
        params.thickness = thicknessField.Value * 1e-3;
        params.fmin = fminField.Value;
        params.fmax = fmaxField.Value;
        params.numFrequencyPoints = round(nfField.Value);
        params.frequencySpacing = string(spacingDropDown.Value);
    end

    function refreshPlotOnly()
        updateAxisFieldState();
        if isempty(lastResults)
            xlabel(axCp, getXLabel(string(xAxisDropDown.Value)));
            return;
        end
        updatePlot(lastResults);
    end

    function onAutoAxesChanged()
        updateAxisFieldState();
        refreshPlotOnly();
    end

    function resetAxes()
        autoAxesCheck.Value = true;
        updateAxisFieldState();
        refreshPlotOnly();
    end

    function updateAxisFieldState()
        manualOn = ~autoAxesCheck.Value;
        xMinField.Enable = onOff(manualOn);
        xMaxField.Enable = onOff(manualOn);
        yMinField.Enable = onOff(manualOn);
        yMaxField.Enable = onOff(manualOn);
    end

    function updatePlot(results)
        cla(axCp); hold(axCp, 'on');
        xSel = string(xAxisDropDown.Value);
        plotCount = 0;

        if A0DisplayCheck.Value && isfield(results.modes, 'A0')
            mode = results.modes.A0;
            xA0 = getModeX(mode, results.grid, xSel);
            plot(axCp, xA0, mode.Cp, '-', 'LineWidth', 2, 'Color', colors.A0, 'DisplayName', 'A0');
            plotCount = plotCount + 1;
        end

        if S0DisplayCheck.Value && isfield(results.modes, 'S0')
            mode = results.modes.S0;
            if any(isfinite(mode.Cp))
                xS0 = getModeX(mode, results.grid, xSel);
                plot(axCp, xS0, mode.Cp, '-', 'LineWidth', 2, 'Color', colors.S0, 'DisplayName', 'S0 experimental');
                plotCount = plotCount + 1;
            end
        end

        xlabel(axCp, getXLabel(xSel));
        ylabel(axCp, 'Phase velocity Cp [m/s]');
        title(axCp, 'Fundamental Lamb modes (Cp)');
        grid(axCp, 'on');

        if plotCount > 0
            legend(axCp, 'Location', 'best');
        else
            legend(axCp, 'off');
        end

        if autoAxesCheck.Value
            xlim(axCp, 'auto');
            ylim(axCp, 'auto');
        else
            if xMaxField.Value > xMinField.Value
                xlim(axCp, [xMinField.Value, xMaxField.Value]);
            end
            if yMaxField.Value > yMinField.Value
                ylim(axCp, [yMinField.Value, yMaxField.Value]);
            end
        end
        hold(axCp, 'off');
    end

    function updateLabels(results, options)
        m = results.material;
        thickness = results.geometry.thickness;
        halfThickness = thickness / 2;

        materialInfoLabel.Text = sprintf(['E = %.4g kPa, nu = %.6f\n', ...
            'lambda = %.4g MPa, mu = %.4g kPa\n', ...
            'CL = %.4f m/s, CT = %.4f m/s\n', ...
            'thickness = %.6g m, halfThickness = %.6g m'], ...
            m.E / 1e3, m.nu, m.lambda / 1e6, m.mu / 1e3, m.CL, m.CT, thickness, halfThickness);

        txt = {sprintf('Robustness: %s', string(options.robustness))};
        if inputsAreDirty
            txt{end+1} = 'Inputs changed after this solution.'; %#ok<AGROW>
        end
        if isfield(results.modes, 'A0')
            a0 = results.modes.A0;
            txt{end+1} = sprintf('A0 valid points: %d/%d', sum(a0.valid), numel(a0.valid)); %#ok<AGROW>
            if any(isfinite(a0.residual))
                txt{end+1} = sprintf('A0 max residual: %.3e', max(a0.residual(isfinite(a0.residual)))); %#ok<AGROW>
            end
        end
        if isfield(results.modes, 'S0')
            s0 = results.modes.S0;
            txt{end+1} = sprintf('S0 experimental valid points: %d/%d', sum(s0.valid), numel(s0.valid)); %#ok<AGROW>
            if any(isfinite(s0.residual))
                txt{end+1} = sprintf('S0 experimental max residual: %.3e', max(s0.residual(isfinite(s0.residual)))); %#ok<AGROW>
            end
        end
        if isempty(txt)
            statusLabel.Text = 'No modes selected.';
        else
            statusLabel.Text = strjoin(txt, newline);
        end
    end

    function onExport()
        if isempty(lastResults)
            uialert(fig, 'No results to export.', 'Export error');
            return;
        end

        LambResults = lastResults; %#ok<NASGU>
        assignin('base', 'LambResults', LambResults);

        if isfield(lastResults.modes, 'A0')
            A0_table = modeToTable(lastResults.modes.A0); %#ok<NASGU>
            assignin('base', 'A0_table', A0_table);
        end

        if isfield(lastResults.modes, 'S0') && any(isfinite(lastResults.modes.S0.Cp))
            S0_table = modeToTable(lastResults.modes.S0); %#ok<NASGU>
            assignin('base', 'S0_table', S0_table);
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
        if isfield(mode, 'frequency'), x = mode.frequency; else, x = gridData.frequency; end
    case "angularFrequency"
        if isfield(mode, 'omega'), x = mode.omega; else, x = gridData.omega; end
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
        lbl = 'kThickness = k · thickness [-]';
    otherwise
        lbl = 'frequency [Hz]';
end
end

function out = modeToTable(mode)
out = table(mode.frequency(:), mode.omega(:), mode.Cp(:), mode.k(:), ...
    mode.kThickness(:), mode.residual(:), mode.valid(:), ...
    'VariableNames', {'Frequency_Hz', 'Omega_rad_s', 'Cp', 'k', 'kThickness', 'Residual', 'Valid'});
end
