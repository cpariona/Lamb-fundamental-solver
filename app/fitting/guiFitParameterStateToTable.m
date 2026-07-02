function data = guiFitParameterStateToTable(state)
%GUIFITPARAMETERSTATETOTABLE Convert parameter state to editable GUI table data.

rows = state.parameters;
n = numel(rows);
ID = strings(n, 1);
Parameter = strings(n, 1);
Role = strings(n, 1);
Value = cell(n, 1);
Unit = strings(n, 1);
Initial = cell(n, 1);
Lower = cell(n, 1);
Upper = cell(n, 1);

for i = 1:n
    ID(i) = rows(i).id;
    Parameter(i) = rows(i).label;
    Role(i) = rows(i).role;
    Unit(i) = rows(i).displayUnit;

    if rows(i).role == "Fit"
        Value{i} = [];
        Initial{i} = rows(i).initialDisplay;
        Lower{i} = rows(i).lowerDisplay;
        Upper{i} = rows(i).upperDisplay;
    else
        Value{i} = rows(i).valueDisplay;
        Initial{i} = [];
        Lower{i} = [];
        Upper{i} = [];
    end
end

data = table(ID, Parameter, Role, Value, Unit, Initial, Lower, Upper);
end