function data = guiFitParameterStateToTable(state)
%GUIFITPARAMETERSTATETOTABLE Convert parameter state to editable GUI table data.

rows = state.parameters;
n = numel(rows);
ID = strings(n, 1);
Parameter = strings(n, 1);
Role = strings(n, 1);
Value = nan(n, 1);
Unit = strings(n, 1);
Initial = nan(n, 1);
Lower = nan(n, 1);
Upper = nan(n, 1);

for i = 1:n
    ID(i) = rows(i).id;
    Parameter(i) = rows(i).label;
    Role(i) = rows(i).role;
    Value(i) = rows(i).valueDisplay;
    Unit(i) = rows(i).displayUnit;
    Initial(i) = rows(i).initialDisplay;
    Lower(i) = rows(i).lowerDisplay;
    Upper(i) = rows(i).upperDisplay;
end

data = table(ID, Parameter, Role, Value, Unit, Initial, Lower, Upper);
end
