function SweepTool_GUI(baseParams, baseOptions)
%SWEEPTOOL_GUI Standalone GUI for one-parameter mRLFE parametric sweeps.
%
% Usage:
%   SweepTool_GUI
%   SweepTool_GUI(params, options)
%
% The tool builds a normalized GUI sweep request and dispatches it through
% guiRunSweep. Model-specific solver details live in app/adapters.

if nargin < 1 || isempty(baseParams)
    baseParams = rlDefaultParams();
end
if nargin < 2 || isempty(baseOptions)
    baseOptions = rlDefaultOptions("Fast");
end
if ~isfield(baseOptions, 'mrlfeParams') || isempty(baseOptions.mrlfeParams)
    baseOptions.mrlfeParams = defaultMRLFEParams();
end

lastSweepOutput = [];
lastSweepResults = [];
lastSweepSummary = [];
lastModelName = "";
lastBranchName = "";

fig = uifigure('Name', 'mRLFE Parametric Sweep Tool', 'Position', [140 100 1320 780]);
root = uigridlayout(fig, [1 2]);
root.ColumnWidth = {390, '1x'};
root.Padding = [8 8 8 8];
root.ColumnSpacing = 10;

controlPanel = uipanel(root, 'Title', 'Sweep setup');
controlPanel.Layout.Column = 1;
cg = uigridlayout(controlPanel, [19 2]);
cg.ColumnWidth = {145, '1x'};
cg.RowHeight = {24, 30, 24, 30, 24, 30, 24, 30, 24, 30, 24, 30, 24, 30, 24, 34, 34, '1x', 28};
cg.Padding = [10 8 10 8];
cg.RowSpacing = 4;
cg.ColumnSpacing = 8;

row = 1;
addLabel(cg, row, [1 2], 'Sweep parameter', 'FontWeight', 'bold');
row = row + 1;
parameterDrop = uidropdown(cg, 'Items', {'etaS', 'E', 'thickness'}, 'Value', 'etaS', ...
    'ValueChangedFcn', @(~,~)onParameterChanged());
setGridPosition(parameterDrop, row, [1 2]);

row = row + 1;
addLabel(cg, row, [1 2], 'Values', 'FontWeight', 'bold');
row = row + 1;
valuesEdit = uieditfield(cg, 'text', 'Value', '0, 0.01, 0.05, 0.10, 0.20, 0.30, 0.50');
setGridPosition(valuesEdit, row, [1 2]);

row = row + 1;
addLabel(cg, row, [1 2], 'Model', 'FontWeight', 'bold');
row = row + 1;
modelDrop = uidropdown(cg, 'Items', {'Viscoelastic real-k', 'Elastic real-k'}, 'Value', 'Viscoelastic real-k');
setGridPosition(modelDrop, row, [1 2]);

row = row + 1;
addLabel(cg, row, [1 2], 'Branch', 'FontWeight', 'bold');
row = row + 1;
branchDrop = uidropdown(cg, 'Items', {'A0Like', 'S0Like'}, 'Value', 'A0Like');
setGridPosition(branchDrop, row, [1 2]);

row = row + 1;
addLabel(cg, row, [1 2], 'Robustness', 'FontWeight', 'bold');
row = row + 1;
robustnessDrop = uidropdown(cg, 'Items', {'Fast', 'Balanced', 'Robust'}, 'Value', 'Fast');
setGridPosition(robustnessDrop, row, [1 2]);

row = row + 1;
addLabel(cg, row, [1 2], 'Base etaS [Pa*s]');
row = row + 1;
etaSEdit = uieditfield(cg, 'numeric', 'Value', getMRLFEValue(baseOptions, 'etaS', 0.05));
setGridPosition(etaSEdit, row, [1 2]);

row = row + 1;
addLabel(cg, row, [1 2], 'Fluid rho [kg/m^3]');
row = row + 1;
fluidDensityEdit = uieditfield(cg, 'numeric', 'Value', getMRLFEValue(baseOptions, 'fluidDensity', 1000));
setGridPosition(fluidDensityEdit, row, [1 2]);

row = row + 1;
addLabel(cg, row, [1 2], 'Fluid c [m/s]');
row = row + 1;
fluidSoundEdit = uieditfield(cg, 'numeric', 'Value', getMRLFEValue(baseOptions, 'fluidSoundSpeed', 1500));
setGridPosition(fluidSoundEdit, row, [1 2]);

row = row + 1;
runButton = uibutton(cg, 'Text', 'Run sweep', 'ButtonPushedFcn', @(~,~)onRunSweep());
setGridPosition(runButton, row, [1 2]);

row = row + 1;
exportButton = uibutton(cg, 'Text', 'Export sweep to workspace', 'ButtonPushedFcn', @(~,~)onExportSweep());
setGridPosition(exportButton, row, [1 2]);

row = row + 1;
statusBox = uitextarea(cg, 'Value', {'Status: ready.'}, 'Editable', 'off', 'FontName', 'Consolas', 'FontSize', 10);
setGridPosition(statusBox, row, [1 2]);

row = row + 1;
helpLabel = uilabel(cg, 'Text', 'Tip: values use displayed units: etaS [Pa*s], E [kPa], thickness [mm].', ...
    'WordWrap', 'on', 'FontSize', 10);
setGridPosition(helpLabel, row, [1 2]);

rightPanel = uipanel(root, 'Title', 'Sweep results');
rightPanel.Layout.Column = 2;
rg = uigridlayout(rightPanel, [2 1]);
rg.RowHeight = {'2x', '1x'};
rg.Padding = [8 8 8 8];
rg.RowSpacing = 8;

ax = uiaxes(rg);
ax.Layout.Row = 1;
grid(ax, 'on');
xlabel(ax, 'frequency [Hz]');
ylabel(ax, 'Phase velocity Cp [m/s]');
title(ax, 'Sweep Cp curves');

summaryTableUI = uitable(rg);
summaryTableUI.Layout.Row = 2;

onParameterChanged();

    function onParameterChanged()
        switch string(parameterDrop.Value)
            case "etaS"
                valuesEdit.Value = '0, 0.01, 0.05, 0.10, 0.20, 0.30, 0.50';
                helpLabel.Text = 'Values use etaS units [Pa*s]. etaS sweeps require the viscoelastic real-k model.';
            case "E"
                valuesEdit.Value = '50, 100, 300, 500, 1000, 1500';
                helpLabel.Text = 'Values use Young''s modulus units [kPa]. Base etaS remains fixed.';
            case "thickness"
                valuesEdit.Value = '0.3, 0.5, 0.7, 1.0';
                helpLabel.Text = 'Values use thickness units [mm]. Base etaS remains fixed.';
        end
    end

    function onRunSweep()
        try
            setStatus({'Status: preparing sweep...'}); drawnow;
            sweepParameter = string(parameterDrop.Value);
            valuesDisplayed = parseNumericList(valuesEdit.Value);
            if isempty(valuesDisplayed)
                error('Enter at least one numeric sweep value.');
            end

            controls = struct();
            controls.robustness = string(robustnessDrop.Value);
            controls.etaS = etaSEdit.Value;
            controls.fluidDensity = fluidDensityEdit.Value;
            controls.fluidSoundSpeed = fluidSoundEdit.Value;

            request = guiBuildSweepRequest("mrlfe", ...
                'modelLabel', string(modelDrop.Value), ...
                'branchName', string(branchDrop.Value), ...
                'sweepField', sweepParameter, ...
                'sweepLabel', sweepParameter, ...
                'sweepValuesDisplay', valuesDisplayed, ...
                'baseParams', baseParams, ...
                'baseOptions', baseOptions, ...
                'controls', controls, ...
                'outputMode', "workspace", ...
                'outputTaskName', "mrlfe_sweep");

            setStatus({sprintf('Status: running %s sweep...', sweepParameter)}); drawnow;
            lastSweepOutput = guiRunSweep(request);
            lastSweepResults = lastSweepOutput.rawResults;
            lastSweepSummary = lastSweepOutput.summaryTable;
            lastModelName = lastSweepOutput.modelName;
            lastBranchName = lastSweepOutput.branchName;

            guiPlotSweepResult(lastSweepOutput.normalized, ax);
            summaryTableUI.Data = lastSweepSummary;
            summaryTableUI.ColumnName = lastSweepSummary.Properties.VariableNames;

            setStatus({sprintf('Status: complete. %d sweep cases.', numel(lastSweepOutput.sweepSpec.values)), ...
                sprintf('Model: %s | Branch: %s', lastModelName, lastBranchName)});
        catch ME
            setStatus({['Status: error: ', ME.message]});
            uialert(fig, ME.message, 'Sweep error');
        end
    end

    function onExportSweep()
        if isempty(lastSweepOutput)
            uialert(fig, 'No sweep results to export yet.', 'Export error');
            return;
        end
        assignin('base', 'SweepToolOutput', lastSweepOutput);
        assignin('base', 'SweepToolRequest', lastSweepOutput.request);
        assignin('base', 'SweepToolNormalized', lastSweepOutput.normalized);
        assignin('base', 'SweepToolResults', lastSweepResults);
        assignin('base', 'SweepToolSummary', lastSweepSummary);
        assignin('base', 'SweepToolModelName', lastModelName);
        assignin('base', 'SweepToolBranchName', lastBranchName);
        setStatus({'Status: exported to workspace as SweepToolOutput, SweepToolResults, and SweepToolSummary.'});
    end

    function setStatus(lines)
        if ischar(lines) || isstring(lines)
            statusBox.Value = cellstr(lines);
        else
            statusBox.Value = lines;
        end
    end
end

function values = parseNumericList(txt)
cleanTxt = regexprep(char(txt), '[;\n\t]', ',');
parts = regexp(cleanTxt, ',', 'split');
values = [];
for i = 1:numel(parts)
    token = strtrim(parts{i});
    if isempty(token)
        continue;
    end
    value = str2double(token);
    if ~isfinite(value)
        error('Invalid numeric value: %s', token);
    end
    values(end+1) = value; %#ok<AGROW>
end
end

function value = getMRLFEValue(options, fieldName, defaultValue)
if isfield(options, 'mrlfeParams') && isfield(options.mrlfeParams, fieldName)
    value = options.mrlfeParams.(fieldName);
else
    value = defaultValue;
end
end

function h = addLabel(parent, row, col, txt, varargin)
h = uilabel(parent, 'Text', txt, varargin{:});
setGridPosition(h, row, col);
end

function setGridPosition(component, row, col)
component.Layout.Row = row;
component.Layout.Column = col;
end
