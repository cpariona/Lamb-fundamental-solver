function state = guiBuildFitParameterState(modelFamily, freeParam, previousState)
%GUIBUILDFITPARAMETERSTATE Build editable one-parameter fitting state.

if nargin < 2
    freeParam = "";
end
if nargin < 3
    previousState = struct();
end

family = findFamily(modelFamily);
fitMask = [family.parameters.canFit];
fitIds = string({family.parameters(fitMask).id});
if strlength(string(freeParam)) == 0
    freeParam = fitIds(1);
end
freeParam = string(freeParam);
if ~any(fitIds == freeParam)
    error('guiBuildFitParameterState:UnsupportedFreeParameter', ...
        'Parameter %s cannot be fitted for model %s.', freeParam, modelFamily);
end

rows = repmat(emptyRow(), 1, numel(family.parameters));
for i = 1:numel(family.parameters)
    meta = family.parameters(i);
    row = emptyRow();
    row.id = string(meta.id);
    row.fieldName = string(meta.fieldName);
    row.label = string(meta.label);
    row.displayUnit = string(meta.displayUnit);
    row.displayScale = meta.displayScale;
    row.canFit = logical(meta.canFit);
    row.fixedDestination = string(meta.fixedDestination);
    row.role = "Fixed";
    if row.id == freeParam
        row.role = "Fit";
    end
    row.valueDisplay = meta.defaultDisplayValue;
    row.initialDisplay = meta.defaultDisplayValue;
    row.lowerDisplay = meta.boundsDisplay(1);
    row.upperDisplay = meta.boundsDisplay(2);
    row.helpText = string(meta.helpText);
    row = preservePreviousValues(row, previousState);
    rows(i) = row;
end

state = struct();
state.modelFamily = string(family.id);
state.familyLabel = string(family.label);
state.freeParam = freeParam;
state.parameters = rows;
end

function family = findFamily(modelFamily)
registry = guiGetFitModelConfiguration();
modelFamily = string(modelFamily);
families = registry.modelFamilies;
for i = 1:numel(families)
    if string(families(i).id) == modelFamily
        family = families(i);
        return;
    end
end
error('guiBuildFitParameterState:UnknownModelFamily', ...
    'Unknown fitting model family: %s.', modelFamily);
end

function row = preservePreviousValues(row, previousState)
if ~isstruct(previousState) || ~isfield(previousState, 'parameters')
    return;
end
previousRows = previousState.parameters;
for i = 1:numel(previousRows)
    if string(previousRows(i).id) == row.id
        row.valueDisplay = previousRows(i).valueDisplay;
        row.initialDisplay = previousRows(i).initialDisplay;
        row.lowerDisplay = previousRows(i).lowerDisplay;
        row.upperDisplay = previousRows(i).upperDisplay;
        return;
    end
end
end

function row = emptyRow()
row = struct();
row.id = "";
row.fieldName = "";
row.label = "";
row.displayUnit = "";
row.displayScale = 1;
row.canFit = false;
row.fixedDestination = "fixedParams";
row.role = "Fixed";
row.valueDisplay = NaN;
row.initialDisplay = NaN;
row.lowerDisplay = NaN;
row.upperDisplay = NaN;
row.helpText = "";
end
