function data = guiDeleteExperimentalFitRows(data, selectedRows)
%GUIDELETEEXPERIMENTALFITROWS Delete selected experimental data rows.

if istable(data)
    data = table2array(data);
end
if isempty(data) || isempty(selectedRows)
    return;
end
if ~isnumeric(data)
    error('guiDeleteExperimentalFitRows:InvalidData', ...
        'Experimental data table must be numeric.');
end
selectedRows = unique(selectedRows(:));
selectedRows = selectedRows(isfinite(selectedRows) & selectedRows >= 1 & selectedRows <= size(data, 1));
if isempty(selectedRows)
    return;
end
data(selectedRows, :) = [];
end
