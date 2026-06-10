function SweepTool_GUI(baseParams, baseOptions)
%SWEEPTOOL_GUI Standalone GUI for one-parameter mRLFE parametric sweeps.
%
% Usage:
%   SweepTool_GUI
%   SweepTool_GUI(params, options)
%
% The tool reuses runParametricSweep and summarizeParametricSweepBranch, but
% keeps sweep exploration separate from the main single-case GUI.

if nargin < 1 || isempty(baseParams)
    baseParams = defaultParams();
end
if nargin < 2 || isempty(baseOptions)
    baseOptions = defaultOptions("Fast");
end
if ~isfield(baseOptions, 'mrlfeParams') || isempty(baseOptions.mrlfeParams)
    baseOptions.mrlfeParams = defaultMRLFEParams();
end

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
uilabel(cg, 'Text', 'Sweep parameter', 'FontWeight', 'bold').Layout.Row = row;
row = row + 1;
parameterDrop = uidropdown(cg, 'Items', {'etaS', 'E', 'thickness'}, 'Value', 'etaS', ...
    'ValueChangedFcn', @(~,~)onParameterChanged());
parameterDrop.Layout.Row = row; parameterDrop.Layout.Column = [1 2];

row = row + 1;
uilabel(cg, 'Text', 'Values', 'FontWeight', 'bold').Layout.Row = row;
row = row + 1;
valuesEdit = uieditfield(cg, 'text', 'Value', '0, 0.01, 0.05, 0.10, 0.20, 0.30, 0.50');
valuesEdit.Layout.Row = row; valuesEdit.Layout.Column = [1 2];

row = row + 1;
uilabel(cg, 'Text', 'Model', 'FontWeight', 'bold').Layout.Row = row;
row = row + 1;
modelDrop = uidropdown(cg, 'Items', {'Viscoelastic real-k', 'Elastic real-k'}, 'Value', 'Viscoelastic real-k');
modelDrop.Layout.Row = row; modelDrop.Layout.Column = [1 2];

row = row + 1;
uilabel(cg, 'Text', 'Branch', 'FontWeight', 'bold').Layout.Row = row;
row = row + 1;
branchDrop = uidropdown(cg, 'Items', {'A0Like', 'S0Like'}, 'Value', 'A0Like');
branchDrop.Layout.Row = row; branchDrop.Layout.Column = [1 2];

row = row + 1;
uilabel(cg, 'Text', 'Robustness', 'FontWeight', 'bold').Layout.Row = row;
row = row + 1;
robustnessDrop = uidropdown(cg, 'Items', {'Fast', 'Balanced', 'Robust'}, 'Value', 'Fast');
robustnessDrop.Layout.Row = row; robustnessDrop.Layout.Column = [1 2];

row = row + 1;
uilabel(cg, 'Text', 'Base etaS [Pa*s]').Layout.Row = row; row = row + 1;
etaSEdit = uieditfield(cg, 'numeric', 'Value', getMRLFEValue(baseOptions, 'etaS', 0.05));
etaSEdit.Layout.Row = row; etaSEdit.Layout.Column = [1 2];

row = row + 1;
uilabel(cg, 'Text', 'Fluid rho [kg/m^3]').Layout.Row = row; row = row + 1;
fluidDensityEdit = uieditfield(cg, 'numeric', 'Value', getMRLFEValue(baseOptions, 'fluidDensity', 1000));
fluidDensityEdit.Layout.Row = row; fluidDensityEdit.Layout.Column = [1 2];

row = row + 1;
uilabel(cg, 'Text', 'Fluid c [m/s]').Layout.Row = row; row = row + 1;
fluidSoundEdit = uieditfield(cg, 'numeric', 'Value', getMRLFEValue(baseOptions, 'fluidSoundSpeed', 1500));
fluidSoundEdit.Layout.Row = row; fluidSoundEdit.Layout.Column = [1 2];

row = row + 1;
runButton = uibutton(cg, 'Text', 'Run sweep', 'ButtonPushedFcn', @(~,~)onRunSweep());
runButton.Layout.Row = row; runButton.Layout.Column = [1 2];

row = row + 1;
exportButton = uibutton(cg, 'Text', 'Export sweep to workspace', 'ButtonPushedFcn', @(~,~)onExportSweep());
exportButton.Layout.Row = row; exportButton.Layout.Column = [1 2];

row = row + 1;
statusBox = uitextarea(cg, 'Value', {'Status: ready.'}, 'Editable', 'off', 'FontName', 'Consolas', 'FontSize', 10);
statusBox.Layout.Row = row; statusBox.Layout.Column = [1 2];

row = row + 1;
helpLabel = uilabel(cg, 'Text', 'Tip: values use displayed units: etaS [Pa*s], E [kPa], thickness [mm].', ...
    'WordWrap', 'on', 'FontSize', 10);
helpLabel.Layout.Row = row; helpLabel.Layout.Column = [1 2];

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

            params = baseParams;
            params.numFrequencyPoints = "auto";
            params.frequencySpacing = "hybrid";

            options = defaultOptions(string(robustnessDrop.Value));
            options.computeMRLFEComplexK = false;
            options.mrlfeParams = defaultMRLFEParams();
            options.mrlfeParams.fluidDensity = fluidDensityEdit.Value;
            options.mrlfeParams.fluidSoundSpeed = fluidSoundEdit.Value;
            options.mrlfeParams.etaS = etaSEdit.Value;
            options.mrlfeParams.etaL = 0;
            options.mrlfeParams.useComplexLambda = false;

            branchName = string(branchDrop.Value);
            options.computeA0 = branchName == "A0Like";
            options.computeS0 = branchName == "S0Like";
            options.mrlfeComputeA0Like = branchName == "A0Like";
            options.mrlfeComputeS0Like = branchName == "S0Like";

            [modelName, options] = configureModelOptions(options, string(modelDrop.Value), sweepParameter);
            [valuesSolver, displayScale, units] = convertDisplayedValues(sweepParameter, valuesDisplayed);

            sweepSpec = struct();
            sweepSpec.parameter = sweepParameter;
            sweepSpec.values = valuesSolver;
            sweepSpec.label = sweepParameter;
            sweepSpec.units = units;
            sweepSpec.displayScale = displayScale;

            setStatus({sprintf('Status: running %s sweep...', sweepParameter)}); drawnow;
            lastSweepResults = runParametricSweep(params, options, sweepSpec);
            lastModelName = modelName;
            lastBranchName = branchName;
            lastSweepSummary = summarizeParametricSweepBranch(lastSweepResults, modelName, branchName, 'Print', false);

            plotSweepOnAxes(lastSweepResults, modelName, branchName, ax);
            summaryTableUI.Data = lastSweepSummary;
            summaryTableUI.ColumnName = lastSweepSummary.Properties.VariableNames;

            setStatus({sprintf('Status: complete. %d sweep cases.', numel(valuesSolver)), ...
                sprintf('Model: %s | Branch: %s', modelName, branchName)});
        catch ME
            setStatus({['Status: error: ', ME.message]});
            uialert(fig, ME.message, 'Sweep error');
        end
    end

    function onExportSweep()
        if isempty(lastSweepResults)
            uialert(fig, 'No sweep results to export yet.', 'Export error');
            return;
        end
        assignin('base', 'SweepToolResults', lastSweepResults);
        assignin('base', 'SweepToolSummary', lastSweepSummary);
        assignin('base', 'SweepToolModelName', lastModelName);
        assignin('base', 'SweepToolBranchName', lastBranchName);
        setStatus({'Status: exported to workspace as SweepToolResults and SweepToolSummary.'});
    end

    function setStatus(lines)
        if ischar(lines) || isstring(lines)
            statusBox.Value = cellstr(lines);
        else
            statusBox.Value = lines;
        end
    end
end

function [modelName, options] = configureModelOptions(options, modelLabel, sweepParameter)
if modelLabel == "Elastic real-k"
    if sweepParameter == "etaS"
        error('etaS only affects the viscoelastic real-k model. Select Viscoelastic real-k or sweep E/thickness.');
    end
    options.computeMRLFERealK = true;
    options.computeMRLFEHanViscoRealK = false;
    modelName = "mRLFEElasticRealK";
else
    options.computeMRLFERealK = true;
    options.computeMRLFEHanViscoRealK = true;
    modelName = "mRLFEHanViscoRealK";
end
end

function [valuesSolver, displayScale, units] = convertDisplayedValues(parameter, valuesDisplayed)
switch string(parameter)
    case "etaS"
        valuesSolver = valuesDisplayed;
        displayScale = 1;
        units = "Pa*s";
    case "E"
        valuesSolver = valuesDisplayed * 1e3;
        displayScale = 1e3;
        units = "kPa";
    case "thickness"
        valuesSolver = valuesDisplayed * 1e-3;
        displayScale = 1e-3;
        units = "mm";
    otherwise
        error('Unsupported sweep parameter: %s', string(parameter));
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

function plotSweepOnAxes(sweepResults, modelName, branchName, ax)
cla(ax); hold(ax, 'on'); grid(ax, 'on');
n = numel(sweepResults.results);
legendText = strings(1, n);

for i = 1:n
    branch = extractSweepBranch(sweepResults.results{i}, modelName, branchName);
    if isempty(branch)
        continue;
    end
    valid = getBranchValidityMask(branch);
    xRaw = branch.frequency(:);
    yRaw = branch.Cp(:);
    valid = valid & isfinite(xRaw) & isfinite(yRaw);
    x = xRaw; y = yRaw;
    x(~valid) = nan; y(~valid) = nan;
    lineHandle = plot(ax, x, y, 'LineWidth', 1.8);
    legendText(i) = makeLegendLabel(sweepResults, i);

    if any(valid)
        lastIdx = find(valid, 1, 'last');
        plot(ax, xRaw(lastIdx), yRaw(lastIdx), 'o', ...
            'MarkerSize', 7, 'LineWidth', 1.4, ...
            'Color', lineHandle.Color, 'MarkerFaceColor', lineHandle.Color, ...
            'HandleVisibility', 'off');
    end
end

xlabel(ax, 'frequency [Hz]');
ylabel(ax, 'Phase velocity Cp [m/s]');
title(ax, sprintf('%s %s sweep', modelName, branchName), 'Interpreter', 'none');
legend(ax, legendText(legendText ~= ""), 'Location', 'best', 'Interpreter', 'none');
hold(ax, 'off');
end

function branch = extractSweepBranch(result, modelName, branchName)
branch = [];
modelName = string(modelName);
branchName = string(branchName);
if isfield(result, 'models') && isfield(result.models, char(modelName)) && ...
        isfield(result.models.(char(modelName)), 'branches') && ...
        isfield(result.models.(char(modelName)).branches, char(branchName))
    branch = result.models.(char(modelName)).branches.(char(branchName));
end
end

function valid = getBranchValidityMask(branch)
if isfield(branch, 'validCp')
    valid = branch.validCp(:) & isfinite(branch.Cp(:));
elseif isfield(branch, 'valid')
    valid = branch.valid(:) & isfinite(branch.Cp(:));
else
    valid = isfinite(branch.Cp(:));
end
end

function txt = makeLegendLabel(sweepResults, idx)
spec = sweepResults.spec;
value = sweepResults.displayValues(idx);
if isfield(spec, 'units') && strlength(string(spec.units)) > 0
    txt = sprintf('%s = %.4g %s', string(spec.label), value, string(spec.units));
else
    txt = sprintf('%s = %.4g', string(spec.label), value);
end
end
