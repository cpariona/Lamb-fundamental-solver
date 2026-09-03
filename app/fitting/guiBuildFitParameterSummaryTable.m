function parameterSummaryTable = guiBuildFitParameterSummaryTable(fitResult, request)
%GUIBUILDFITPARAMETERSUMMARYTABLE Build per-parameter fit summary rows.

registry = guiGetFitModelConfiguration();
family = localFindFamily(registry, fitResult.modelFamily);
n = numel(family.parameters);

Parameter = strings(n, 1);
Role = strings(n, 1);
Value = nan(n, 1);
Unit = strings(n, 1);
Initial = nan(n, 1);
Lower = nan(n, 1);
Upper = nan(n, 1);
StandardError = nan(n, 1);
ConfidenceLower = nan(n, 1);
ConfidenceUpper = nan(n, 1);

freeParams = string(fitResult.freeParams(:));

for i = 1:n
    meta = family.parameters(i);
    fieldName = char(meta.fieldName);
    scale = meta.displayScale;
    Parameter(i) = string(meta.label);
    Unit(i) = string(meta.displayUnit);

    if any(freeParams == string(meta.fieldName))
        Role(i) = "Fit";
        if isfield(fitResult.bestParams, fieldName)
            Value(i) = fitResult.bestParams.(fieldName) ./ scale;
        end
        if isfield(request.initialGuess, fieldName)
            Initial(i) = request.initialGuess.(fieldName) ./ scale;
        end
        if isfield(request.bounds, fieldName) && numel(request.bounds.(fieldName)) >= 2
            bounds = request.bounds.(fieldName);
            Lower(i) = bounds(1) ./ scale;
            Upper(i) = bounds(2) ./ scale;
        end
    else
        Role(i) = "Fixed";
        source = request.fixedParams;
        if string(meta.fixedDestination) == "controls"
            source = request.controls;
        end
        if isfield(source, fieldName)
            Value(i) = source.(fieldName) ./ scale;
        end
    end
end

parameterSummaryTable = table(Parameter, Role, Value, Unit, Initial, Lower, Upper, ...
    StandardError, ConfidenceLower, ConfidenceUpper);
end

function family = localFindFamily(registry, modelFamily)
modelFamily = string(modelFamily);
for i = 1:numel(registry.modelFamilies)
    if string(registry.modelFamilies(i).id) == modelFamily
        family = registry.modelFamilies(i);
        return;
    end
end
error('guiBuildFitParameterSummaryTable:UnknownModelFamily', ...
    'Unknown fitting model family: %s.', modelFamily);
end
