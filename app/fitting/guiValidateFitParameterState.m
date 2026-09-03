function guiValidateFitParameterState(state)
%GUIVALIDATEFITPARAMETERSTATE Validate registry-driven one-parameter fit state.

if ~isstruct(state) || ~isfield(state, 'modelFamily') || ~isfield(state, 'parameters')
    error('guiValidateFitParameterState:InvalidState', ...
        'Fit parameter state must contain modelFamily and parameters.');
end

registry = guiGetFitModelConfiguration();
family = findFamily(registry, state.modelFamily);
rows = state.parameters;
if numel(rows) ~= numel(family.parameters)
    error('guiValidateFitParameterState:ParameterCountMismatch', ...
        'Fit parameter state does not contain every registered parameter.');
end

registeredIds = string({family.parameters.id});
rowIds = string({rows.id});
if ~isequal(rowIds(:), registeredIds(:))
    error('guiValidateFitParameterState:ParameterOrderMismatch', ...
        'Fit parameter state parameter IDs or order differ from the registry.');
end
if numel(unique(rowIds)) ~= numel(rowIds)
    error('guiValidateFitParameterState:DuplicateParameter', ...
        'Fit parameter state contains duplicate parameter IDs.');
end

fitMask = arrayfun(@(p) string(p.role) == "Fit", rows);
if nnz(fitMask) ~= 1
    error('guiValidateFitParameterState:OneFreeParameterRequired', ...
        'Exactly one parameter must have role Fit.');
end
fitIndex = find(fitMask, 1, 'first');
if ~logical(family.parameters(fitIndex).canFit)
    error('guiValidateFitParameterState:ParameterCannotFit', ...
        'Parameter %s is not enabled for fitting.', rows(fitIndex).id);
end
if isfield(state, 'freeParam') && string(state.freeParam) ~= string(rows(fitIndex).id)
    error('guiValidateFitParameterState:FreeParameterMismatch', ...
        'state.freeParam does not match the row marked Fit.');
end

for i = 1:numel(rows)
    row = rows(i);
    if row.displayScale <= 0 || ~isfinite(row.displayScale)
        error('guiValidateFitParameterState:InvalidDisplayScale', ...
            'Display scale for %s must be finite and positive.', row.id);
    end
    if fitMask(i)
        validateFinite(row.initialDisplay, row.id, 'initial guess');
        validateFinite(row.lowerDisplay, row.id, 'lower bound');
        validateFinite(row.upperDisplay, row.id, 'upper bound');
        if row.lowerDisplay >= row.upperDisplay
            error('guiValidateFitParameterState:InvalidBounds', ...
                'Lower bound must be smaller than upper bound for %s.', row.id);
        end
        if row.initialDisplay < row.lowerDisplay || row.initialDisplay > row.upperDisplay
            error('guiValidateFitParameterState:InitialOutsideBounds', ...
                'Initial guess for %s must lie within its bounds.', row.id);
        end
    else
        validateFinite(row.valueDisplay, row.id, 'fixed value');
    end
end
end

function family = findFamily(registry, modelFamily)
modelFamily = string(modelFamily);
for i = 1:numel(registry.modelFamilies)
    if string(registry.modelFamilies(i).id) == modelFamily
        family = registry.modelFamilies(i);
        return;
    end
end
error('guiValidateFitParameterState:UnknownModelFamily', ...
    'Unknown fitting model family: %s.', modelFamily);
end

function validateFinite(value, id, description)
if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value)
    error('guiValidateFitParameterState:InvalidNumericValue', ...
        '%s for %s must be a finite numeric scalar.', description, id);
end
end
