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
    state.parameters(i).valueDisplay = data.Value(i);
    state.parameters(i).initialDisplay = data.Initial(i);
    state.parameters(i).lowerDisplay = data.Lower(i);
    state.parameters(i).upperDisplay = data.Upper(i);
end
end
