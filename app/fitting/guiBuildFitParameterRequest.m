function config = guiBuildFitParameterRequest(state)
%GUIBUILDFITPARAMETERREQUEST Convert editor state to fitting request fields.

rows = state.parameters;
fitMask = arrayfun(@(p) string(p.role) == "Fit", rows);
if nnz(fitMask) ~= 1
    error('guiBuildFitParameterRequest:OneFreeParameterRequired', ...
        'Exactly one parameter must have role Fit.');
end

fixedParams = struct();
controls = struct();
initialGuess = struct();
bounds = struct();

for i = 1:numel(rows)
    row = rows(i);
    fieldName = char(row.fieldName);
    if fitMask(i)
        validateFinite(row.initialDisplay, row.id, 'initial guess');
        validateFinite(row.lowerDisplay, row.id, 'lower bound');
        validateFinite(row.upperDisplay, row.id, 'upper bound');
        if row.lowerDisplay >= row.upperDisplay
            error('guiBuildFitParameterRequest:InvalidBounds', ...
                'Lower bound must be smaller than upper bound for %s.', row.id);
        end
        initialValue = row.initialDisplay * row.displayScale;
        initialGuess.(fieldName) = initialValue;
        bounds.(fieldName) = [row.lowerDisplay, row.upperDisplay] * row.displayScale;
        if row.fixedDestination == "controls"
            controls.(fieldName) = initialValue;
        end
    else
        validateFinite(row.valueDisplay, row.id, 'fixed value');
        value = row.valueDisplay * row.displayScale;
        if row.fixedDestination == "controls"
            controls.(fieldName) = value;
        else
            fixedParams.(fieldName) = value;
        end
    end
end

config = struct();
config.fixedParams = fixedParams;
config.freeParams = string(rows(fitMask).fieldName);
config.initialGuess = initialGuess;
config.bounds = bounds;
config.controls = controls;
end

function validateFinite(value, id, description)
if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value)
    error('guiBuildFitParameterRequest:InvalidNumericValue', ...
        '%s for %s must be a finite numeric scalar.', description, id);
end
end
