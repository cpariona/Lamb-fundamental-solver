function displayTable = guiBuildFitParameterDisplayTable(parameterSummaryTable)
%GUIBUILDFITPARAMETERDISPLAYTABLE Build compact visible fitted-parameter table.

if isempty(parameterSummaryTable) || ~istable(parameterSummaryTable)
    displayTable = table();
    return;
end

rows = string(parameterSummaryTable.Role) == "Fit";
displayTable = parameterSummaryTable(rows, :);
if isempty(displayTable)
    displayTable = table();
    return;
end

removeNames = ["Role"];
displayTable = removeVariables(displayTable, removeNames);
displayTable = removeEmptyVariables(displayTable);
displayTable = localFormatDisplayValues(displayTable);
displayTable.Properties.VariableNames = matlab.lang.makeValidName( ...
    readableVariableNames(displayTable.Properties.VariableNames));
end

function t = removeVariables(t, names)
for name = names(:).'
    if ismember(name, string(t.Properties.VariableNames))
        t.(name) = [];
    end
end
end

function t = removeEmptyVariables(t)
names = string(t.Properties.VariableNames);
for i = numel(names):-1:1
    values = t.(names(i));
    if isnumeric(values) || islogical(values)
        isEmpty = all(~isfinite(double(values(:))));
    elseif isstring(values)
        isEmpty = all(strlength(values(:)) == 0);
    elseif iscell(values)
        isEmpty = all(cellfun(@isempty, values(:)));
    else
        isEmpty = false;
    end
    if isEmpty
        t.(names(i)) = [];
    end
end
end

function out = localFormatDisplayValues(t)
names = string(t.Properties.VariableNames);
out = table();
for i = 1:numel(names)
    values = t.(names(i));
    if isnumeric(values) || islogical(values)
        out.(names(i)) = arrayfun(@formatNumeric, double(values(:)));
    else
        out.(names(i)) = string(values(:));
    end
end
end

function text = formatNumeric(value)
if ~isfinite(value)
    text = "";
elseif abs(value) >= 1e4 || (abs(value) > 0 && abs(value) < 1e-3)
    text = string(sprintf('%.6g', value));
else
    text = string(sprintf('%.5g', value));
end
end

function names = readableVariableNames(names)
names = string(names);
names(names == "StandardError") = "Standard error";
names(names == "ConfidenceLower") = "Confidence lower";
names(names == "ConfidenceUpper") = "Confidence upper";
end
