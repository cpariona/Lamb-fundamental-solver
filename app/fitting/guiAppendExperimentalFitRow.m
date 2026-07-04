function data = guiAppendExperimentalFitRow(data)
%GUIAPPENDEXPERIMENTALFITROW Append an editable experimental data row.

data = localNumericData(data);
if isempty(data)
    data = nan(0, 3);
end
if size(data, 2) < 3
    data(:, end+1:3) = nan;
end
data(end + 1, 1:3) = [nan, nan, 1];
end

function data = localNumericData(data)
if istable(data)
    data = table2array(data);
end
if isempty(data)
    data = nan(0, 3);
end
if ~isnumeric(data)
    error('guiAppendExperimentalFitRow:InvalidData', ...
        'Experimental data table must be numeric.');
end
end
