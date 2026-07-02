function SweepTool_GUI(baseParams, baseOptions)
%SWEEPTOOL_GUI Standalone GUI for one-parameter parametric sweeps.
%
% Usage:
%   SweepTool_GUI
%   SweepTool_GUI(params, options)
%
% The tool builds a normalized GUI sweep request and dispatches it through
% guiRunSweep. Model-specific solver details live in app/adapters, while
% selectable sweep metadata lives in app/sweep/guiGetSweepRegistry.

if nargin < 1 || isempty(baseParams)
    baseParams = rlDefaultParams();
end
if nargin < 2 || isempty(baseOptions)
    baseOptions = rlDefaultOptions("Fast");
end
if ~isfield(baseOptions, 'mrlfeParams') || isempty(baseOptions.mrlfeParams)
    baseOptions.mrlfeParams = defaultMRLFEParams();
end

registry = guiGetSweepRegistry();
activeModelFamily = string(registry.defaultModelFamily);
activeFamily = guiGetSweepFamilyConfig(registry, activeModelFamily);
activeParameter = guiGetSweepParameterConfig(activeFamily, activeFamily.defaultParameter);

lastSweepOutput = [];
lastSweepResults = [];
lastSweepSummary = [];
lastModelName = "";
lastBranchName = "";

fig = uifigure('Name', char(activeFamily.figureTitle), 'Position', [140 100 1320 780]);
root = uigridlayout(fig, [1 2]);
root.ColumnWidth = {390, '1x'};
root.Padding = [8 8 8 8];
root.ColumnSpacing = 10;

controlPanel = uipanel(root, 'Title', 'Sweep setup');
controlPanel.Layout.Column = 1;
cg = uigridlayout(controlPanel, [22 2]);
cg.ColumnWidth = {145, '1x'};
cg.RowHeight = [repmat({24, 30}, 1, 9), {34, 34, '1x', 28}];
cg.Padding = [10 8 10 8];
cg.RowSpacing = 4;
cg.ColumnSpacing = 8;

row = 1;
addLabel(cg, row, [1 2], 'Model family', 'FontWeight', 'bold');
row = row + 1;
familyDrop = uidropdown(cg, ...
    'Items', cellstr([registry.modelFamilies.label]), ...
    'Value', char(activeFamily.label), ...
    'ValueChangedFcn', @(~,~)onFamilyChanged());
setGridPosition(familyDrop, row, [1 2]);

row = row + 1;
addLabel(cg, row, [1 2], 'Sweep parameter', 'FontWeight', 'bold');
row = row + 1;
parameterDrop = uidropdown(cg, ...
    'Items', cellstr([activeFamily.parameters.id]), ...
    'Value', char(activeFamily.defaultParameter), ...
    'ValueChangedFcn', @(~,~)onParameterChanged());
setGridPosition(parameterDrop, row, [1 2]);

row = row + 1;
addLabel(cg, row, [1 2], 'Values', 'FontWeight', 'bold');
row = row + 1;
valuesEdit = uieditfield(cg, 'text', 'Value', guiFormatSweepValues(activeParameter.defaultValuesDisplay));
setGridPosition(valuesEdit, row, [1 2]);

row = row + 1;
addLabel(cg, row, [1 2], 'Model', 'FontWeight', 'bold');
row = row + 1;
modelDrop = uidropdown(cg, ...
    'Items', cellstr(activeFamily.modelLabels), ...
    'Value', char(activeFamily.defaultModelLabel));
setGridPosition(modelDrop, row, [1 2]);

row = row + 1;
addLabel(cg, row, [1 2], 'Branch', 'FontWeight', 'bold');
row = row + 1;
branchDrop = uidropdown(cg, ...
    'Items', cellstr(activeFamily.branchNames), ...
    'Value', char(activeFamily.defaultBranchName));
setGridPosition(branchDrop, row, [1 2]);

row = row + 1;
addLabel(cg, row, [1 2], 'Robustness', 'FontWeight', 'bold');
row = row + 1;
robustnessDrop = uidropdown(cg, ...
    'Items', cellstr(activeFamily.robustnessPresets), ...
    'Value', char(activeFamily.defaultRobustness));
setGridPosition(robustnessDrop, row, [1 2]);

row = row + 1;
addLabel(cg, row, [1 2], 'mRLFE A0 atlas policy');
row = row + 1;
a0PolicyDrop = uidropdown(cg, 'Items', {'delayedCut', 'adaptivePhysicalTail'}, 'Value', 'delayedCut');
setGridPosition(a0PolicyDrop, row, [1 2]);

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
helpLabel = uilabel(cg, 'Text', char(activeParameter.helpText), ...
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
updateFamilySpecificControls();

    function onFamilyChanged()
        activeModelFamily = getFamilyIdFromLabel(string(familyDrop.Value));
        activeFamily = guiGetSweepFamilyConfig(registry, activeModelFamily);

        fig.Name = char(activeFamily.figureTitle);
        parameterDrop.Items = cellstr([activeFamily.parameters.id]);
        parameterDrop.Value = char(activeFamily.defaultParameter);
        modelDrop.Items = cellstr(activeFamily.modelLabels);
        modelDrop.Value = char(activeFamily.defaultModelLabel);
        branchDrop.Items = cellstr(activeFamily.branchNames);
        branchDrop.Value = char(activeFamily.defaultBranchName);
        robustnessDrop.Items = cellstr(activeFamily.robustnessPresets);
        robustnessDrop.Value = char(activeFamily.defaultRobustness);

        onParameterChanged();
        updateFamilySpecificControls();
        setStatus({sprintf('Status: selected model family: %s.', activeFamily.label)});
    end

    function onParameterChanged()
        parameterConfig = guiGetSweepParameterConfig(activeFamily, string(parameterDrop.Value));
        valuesEdit.Value = guiFormatSweepValues(parameterConfig.defaultValuesDisplay);
        helpLabel.Text = char(parameterConfig.helpText);
    end

    function onRunSweep()
        try
            setStatus({'Status: preparing sweep...'}); drawnow;
            sweepParameter = string(parameterDrop.Value);
            parameterConfig = guiGetSweepParameterConfig(activeFamily, sweepParameter);
            valuesDisplayed = parseNumericList(valuesEdit.Value);
            if isempty(valuesDisplayed)
                error('Enter at least one numeric sweep value.');
            end

            controls = buildControlsForActiveFamily();

            request = guiBuildSweepRequest(activeModelFamily, ...
                'modelLabel', string(modelDrop.Value), ...
                'branchName', string(branchDrop.Value), ...
                'sweepField', sweepParameter, ...
                'sweepLabel', parameterConfig.label, ...
                'sweepValuesDisplay', valuesDisplayed, ...
                'displayUnit', parameterConfig.displayUnit, ...
                'displayScale', parameterConfig.displayScale, ...
                'baseParams', baseParams, ...
                'baseOptions', baseOptions, ...
                'controls', controls, ...
                'outputMode', "workspace", ...
                'outputTaskName', activeFamily.outputTaskName);

            setStatus({sprintf('Status: running %s / %s sweep...', activeFamily.label, sweepParameter)}); drawnow;
            lastSweepOutput = guiRunSweep(request);
            lastSweepResults = lastSweepOutput.rawResults;
            lastSweepSummary = lastSweepOutput.summaryTable;
            lastModelName = lastSweepOutput.modelName;
            lastBranchName = lastSweepOutput.branchName;

            guiPlotSweepResult(lastSweepOutput.normalized, ax);
            summaryTableUI.Data = lastSweepSummary;
            summaryTableUI.ColumnName = lastSweepSummary.Properties.VariableNames;

            setStatus({sprintf('Status: complete. %d sweep cases.', numel(lastSweepOutput.sweepSpec.values)), ...
                sprintf('Family: %s | Model: %s | Branch: %s', activeFamily.label, lastModelName, lastBranchName)});
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

    function controls = buildControlsForActiveFamily()
        controls = struct();
        controls.robustness = string(robustnessDrop.Value);
        controls.executionProfile = controls.robustness;

        switch activeModelFamily
            case "mrlfe"
                controls.etaS = etaSEdit.Value;
                controls.fluidDensity = fluidDensityEdit.Value;
                controls.fluidSoundSpeed = fluidSoundEdit.Value;
                controls.mrlfeUseUnifiedAtlasRoute = true;
                controls.mrlfeA0Policy = string(a0PolicyDrop.Value);
            otherwise
                controls.M54_variant = "corrected";
                controls.normalizeRows = false;
                controls.usePhysicalCpWindow = false;
                controls.atlasBranchPolicy = "atlasA0";
                if string(robustnessDrop.Value) == "Balanced"
                    controls.atlasNumYPoints = 600;
                    controls.atlasTopNMinima = 16;
                else
                    controls.atlasNumYPoints = 300;
                    controls.atlasTopNMinima = 12;
                end
        end
    end

    function updateFamilySpecificControls()
        isMRLFE = activeModelFamily == "mrlfe";
        etaSEdit.Enable = matlab.lang.OnOffSwitchState(isMRLFE);
        fluidDensityEdit.Enable = matlab.lang.OnOffSwitchState(isMRLFE);
        fluidSoundEdit.Enable = matlab.lang.OnOffSwitchState(isMRLFE);
        a0PolicyDrop.Enable = matlab.lang.OnOffSwitchState(isMRLFE);
    end

    function familyId = getFamilyIdFromLabel(label)
        families = registry.modelFamilies;
        for iFamily = 1:numel(families)
            if string(families(iFamily).label) == string(label)
                familyId = string(families(iFamily).id);
                return;
            end
        end
        error('Unknown sweep model family label: %s', string(label));
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
