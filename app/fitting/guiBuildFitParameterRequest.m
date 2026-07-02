function config = guiBuildFitParameterRequest(state)
%GUIBUILDFITPARAMETERREQUEST Convert editor state to fitting request fields.

guiValidateFitParameterState(state);

rows = state.parameters;
fitMask = arrayfun(@(p) string(p.role) == "Fit", rows);
fixedParams = struct();
controls = struct();
initialGuess = struct();
bounds = struct();

for i = 1:numel(rows)
    row = rows(i);
    fieldName = char(row.fieldName);
    if fitMask(i)
        initialValue = row.initialDisplay * row.displayScale;
        initialGuess.(fieldName) = initialValue;
        bounds.(fieldName) = [row.lowerDisplay, row.upperDisplay] * row.displayScale;
        if row.fixedDestination == "controls"
            controls.(fieldName) = initialValue;
        end
    else
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
