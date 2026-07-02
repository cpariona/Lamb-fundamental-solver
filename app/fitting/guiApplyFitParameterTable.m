function state = guiApplyFitParameterTable(state, data)
%GUIAPPLYFITPARAMETERTABLE Apply editable table values to parameter state.

if ~istable(data)
    error('guiApplyFitParameterTable:ExpectedTable', ...
        'Fit parameter editor data must be a table.');
end
required = ["ID", "Value", "Initial", "Lower", "Upper"];
if ~all(ismember(required, string(data.Properties.VariableNames)))
    error('guiApplyFitParameterTable:MissingColumns', ...
        'Fit parameter editor table is missing required columns.');
end
if height(data) ~= numel(state.parameters)
    error('guiApplyFitParameterTable:RowCountMismatch', ...
        'Fit parameter editor row count does not match the registry.');
end

for i = 1:numel(state.parameters)
    if string(data.ID(i)) ~= state.parameters(i).id
        error('guiApplyFitParameterTable:ParameterOrderMismatch', ...
            'Fit parameter editor parameter order changed unexpectedly.');
    end

    if state.parameters(i).role == "Fit"
        state.parameters(i).initialDisplay = readScalarCell(data.Initial, i, 'Initial');
        state.parameters(i).lowerDisplay = readScalarCell(data.Lower, i, 'Lower');
        state.parameters(i).upperDisplay = readScalarCell(data.Upper, i, 'Upper');
    else
        state.parameters(i).valueDisplay = readScalarCell(data.Value, i, 'Value');
    end
end
end

function value = readScalarCell(column, index, columnName)
if iscell(column)
    value = column{index};
else
    value = column(index);
end
if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value)
    error('guiApplyFitParameterTable:InvalidCellValue', ...
        '%s must contain a finite numeric scalar in each active row.', columnName);
end
end