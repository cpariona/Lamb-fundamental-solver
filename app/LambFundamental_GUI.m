function LambFundamental_GUI
% GUI shell for fundamental Lamb modes (Cp only) using modular backend.

%% Default values
defaults = struct();
defaults.modelType = "YoungPoissonFixedCL";
defaults.rho = 1070;
defaults.E = 475e3;          % Pa
defaults.nu = 0.4999;
defaults.CL = 1500;
defaults.lambda = 2.40e9;    % Pa
defaults.mu = 158e3;         % Pa
defaults.thickness = 0.50e-3; % m
defaults.fmin = 10;
defaults.fmax = 8000;
defaults.numFrequencyPoints = 250;
defaults.frequencySpacing = "logspace";
defaults.gridPointsInitial = 3000;
defaults.gridPointsTracking = 600;
defaults.jumpTol = 0.35;
defaults.residualTolerance = 1e-5;

lastResults = [];

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
    'Value', char(defaults.modelType), 'ValueChangedFcn', @(~,~)updateMaterialInputState());

uilabel(matGrid, 'Text', 'rho [kg/m^3]');
rhoField = uieditfield(matGrid, 'numeric', 'Value', defaults.rho, 'Limits', [0 Inf]);

ELabel = uilabel(matGrid, 'Text', 'E [kPa]');
EField = uieditfield(matGrid, 'numeric', 'Value', defaults.E/1e3, 'Limits', [0 Inf]);

nuLabel = uilabel(matGrid, 'Text', 'nu [-]');
nuField = uieditfield(matGrid, 'numeric', 'Value', defaults.nu, 'Limits', [0 0.5]);

CLLabel = uilabel(matGrid, 'Text', 'CL [m/s]');
CLField = uieditfield(matGrid, 'numeric', 'Value', defaults.CL, 'Limits', [0 Inf]);

lambdaLabel = uilabel(matGrid, 'Text', 'lambda [MPa]');
lambdaField = uieditfield(matGrid, 'numeric', 'Value', defaults.lambda/1e6, 'Limits', [0 Inf]);

muLabel = uilabel(matGrid, 'Text', 'mu [kPa]');
muField = uieditfield(matGrid, 'numeric', 'Value', defaults.mu/1e3, 'Limits', [0 Inf]);

% fillers
uilabel(matGrid, 'Text', ''); uilabel(matGrid, 'Text', '');

% Geometry/Frequency tab
tabGeo = uitab(tabs, 'Title', 'Geometry / Frequency');
geoGrid = uigridlayout(tabGeo, [6 2]);
geoGrid.ColumnWidth = {170, '1x'};
geoGrid.RowHeight = repmat({32}, 1, 6);
geoGrid.Padding = [12 12 12 12];

uilabel(geoGrid, 'Text', 'thickness [mm]');
thicknessField = uieditfield(geoGrid, 'numeric', 'Value', defaults.thickness*1e3, 'Limits', [0 Inf]);
uilabel(geoGrid, 'Text', 'fmin [Hz]');
fminField = uieditfield(geoGrid, 'numeric', 'Value', defaults.fmin, 'Limits', [eps Inf]);
uilabel(geoGrid, 'Text', 'fmax [Hz]');
fmaxField = uieditfield(geoGrid, 'numeric', 'Value', defaults.fmax, 'Limits', [eps Inf]);
uilabel(geoGrid, 'Text', 'N frequency points');
nfField = uieditfield(geoGrid, 'numeric', 'Value', defaults.numFrequencyPoints, 'RoundFractionalValues', 'on', 'Limits', [10 50000]);
uilabel(geoGrid, 'Text', 'frequency spacing');
spacingDropDown = uidropdown(geoGrid, 'Items', {'logspace', 'linspace'}, 'Value', char(defaults.frequencySpacing));

% Modes tab
tabModes = uitab(tabs, 'Title', 'Modes');
modesGrid = uigridlayout(tabModes, [4 1]);
modesGrid.RowHeight = {30, 30, 80, '1x'};
modesGrid.Padding = [12 12 12 12];

A0Check = uicheckbox(modesGrid, 'Text', 'A0', 'Value', true);
S0Check = uicheckbox(modesGrid, 'Text', 'S0 experimental', 'Value', false);
uilabel(modesGrid, 'Text', 'S0 uses the symmetric Rayleigh-Lamb residual, but it has not been benchmarked yet.', ...
    'WordWrap', 'on', 'FontAngle', 'italic');

% Plot tab
tabPlot = uitab(tabs, 'Title', 'Plot');
plotGrid = uigridlayout(tabPlot, [8 2]);
plotGrid.ColumnWidth = {150, '1x'};
plotGrid.RowHeight = repmat({30}, 1, 8);
plotGrid.Padding = [12 12 12 12];

uilabel(plotGrid, 'Text', 'x-axis');
xAxisDropDown = uidropdown(plotGrid, 'Items', {'frequency', 'angularFrequency', 'wavenumber', 'kThickness'}, 'Value', 'frequency');
uilabel(plotGrid, 'Text', 'y-axis');
uilabel(plotGrid, 'Text', 'Cp');
autoAxesCheck = uicheckbox(plotGrid, 'Text', 'auto axes', 'Value', true);
autoAxesCheck.Layout.Column = [1 2];
uilabel(plotGrid, 'Text', 'x min'); xMinField = uieditfield(plotGrid, 'numeric', 'Value', 0);
uilabel(plotGrid, 'Text', 'x max'); xMaxField = uieditfield(plotGrid, 'numeric', 'Value', 0);
uilabel(plotGrid, 'Text', 'y min'); yMinField = uieditfield(plotGrid, 'numeric', 'Value', 0);
uilabel(plotGrid, 'Text', 'y max'); yMaxField = uieditfield(plotGrid, 'numeric', 'Value', 0);

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

    function updateMaterialInputState()
        modelType = string(modelDropDown.Value);
        ypOn = modelType == "YoungPoissonFixedCL";

        ELabel.Enable = onOff(ypOn); EField.Enable = onOff(ypOn);
        nuLabel.Enable = onOff(ypOn); nuField.Enable = onOff(ypOn);
        CLLabel.Enable = onOff(ypOn); CLField.Enable = onOff(ypOn);

        lambdaLabel.Enable = onOff(~ypOn); lambdaField.Enable = onOff(~ypOn);
        muLabel.Enable = onOff(~ypOn); muField.Enable = onOff(~ypOn);
    end

    function onCompute()
        try
            statusLabel.Text = 'Computing...'; drawnow;

            params = struct();
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

            options = struct();
            options.computeA0 = logical(A0Check.Value);
            options.computeS0 = logical(S0Check.Value);
            options.gridPointsInitial = defaults.gridPointsInitial;
            options.gridPointsTracking = defaults.gridPointsTracking;
            options.jumpTol = defaults.jumpTol;
            options.residualTolerance = defaults.residualTolerance;

            lastResults = computeFundamentalLambModes(params, options);
            updatePlot(lastResults);
            updateLabels(lastResults);

        catch ME
            statusLabel.Text = ['Error: ', ME.message];
            uialert(fig, ME.message, 'Compute error');
        end
    end

    function updatePlot(results)
        cla(axCp); hold(axCp, 'on');
        xSel = string(xAxisDropDown.Value);

        if isfield(results.modes, 'A0')
            mode = results.modes.A0;
            xA0 = getModeX(mode, results.grid, xSel);
            plot(axCp, xA0, mode.Cp, 'LineWidth', 2, 'DisplayName', 'A0');
        end

        if isfield(results.modes, 'S0')
            mode = results.modes.S0;
            if any(isfinite(mode.Cp))
                xS0 = getModeX(mode, results.grid, xSel);
                plot(axCp, xS0, mode.Cp, '--', 'LineWidth', 1.5, 'DisplayName', 'S0 experimental');
            end
        end

        xlabel(axCp, getXLabel(xSel));
        ylabel(axCp, 'Phase velocity Cp [m/s]');
        legend(axCp, 'Location', 'best');
        grid(axCp, 'on');

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

    function updateLabels(results)
        m = results.material;
        thickness = results.geometry.thickness;
        halfThickness = thickness / 2;

        materialInfoLabel.Text = sprintf(['E = %.4g kPa, nu = %.6f\n', ...
            'lambda = %.4g MPa, mu = %.4g kPa\n', ...
            'CL = %.4f m/s, CT = %.4f m/s\n', ...
            'thickness = %.6g m, halfThickness = %.6g m'], ...
            m.E / 1e3, m.nu, m.lambda / 1e6, m.mu / 1e3, m.CL, m.CT, thickness, halfThickness);

        txt = {};
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
