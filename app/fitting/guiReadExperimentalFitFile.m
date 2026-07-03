function imported = guiReadExperimentalFitFile(filePath)
%GUIREADEXPERIMENTALFITFILE Read candidate experimental fitting data.
%
% Supports delimited text (.txt, .csv) and MAT files. The function only
% discovers numeric tabular content; column-role assignment and unit
% conversion are handled separately by guiPrepareExperimentalFitData.

arguments
    filePath (1,1) string
end

if strlength(filePath) == 0 || ~isfile(filePath)
    error('FitDataImport:FileNotFound', 'Experimental data file was not found: %s', filePath);
end

[~, fileName, extension] = fileparts(filePath);
extension = lower(string(extension));

switch extension
    case {".csv", ".txt", ".dat"}
        raw = readtable(filePath, 'VariableNamingRule', 'preserve');
        [numericData, columnNames] = localNumericTable(raw);
        sourceVariable = "";
    case ".mat"
        loaded = load(filePath);
        [numericData, columnNames, sourceVariable] = localNumericMatContent(loaded);
    otherwise
        error('FitDataImport:UnsupportedExtension', ...
            'Unsupported experimental data format "%s". Use .txt, .csv, .dat, or .mat.', extension);
end

if isempty(numericData) || size(numericData, 2) < 2
    error('FitDataImport:InsufficientColumns', ...
        'The selected file must contain at least two numeric columns.');
end

imported = struct();
imported.filePath = filePath;
imported.fileName = string(fileName) + extension;
imported.extension = extension;
imported.sourceVariable = sourceVariable;
imported.columnNames = string(columnNames(:)).';
imported.numericData = double(numericData);
imported.numRows = size(numericData, 1);
imported.numColumns = size(numericData, 2);
end

function [numericData, columnNames] = localNumericTable(raw)
if isempty(raw)
    numericData = [];
    columnNames = strings(1,0);
    return;
end

keep = false(1, width(raw));
columns = cell(1, width(raw));
for i = 1:width(raw)
    value = raw{:, i};
    if isnumeric(value) || islogical(value)
        keep(i) = true;
        columns{i} = double(value(:));
    end
end

if ~any(keep)
    numericData = [];
    columnNames = strings(1,0);
    return;
end

numericData = horzcat(columns{keep});
columnNames = string(raw.Properties.VariableNames(keep));
end

function [numericData, columnNames, sourceVariable] = localNumericMatContent(loaded)
fieldNames = string(fieldnames(loaded));
sourceVariable = "";

preferred = ["experimental", "data", "fitData", "dispersionData"];
ordered = [preferred(ismember(preferred, fieldNames)), fieldNames(~ismember(fieldNames, preferred))'];

for name = ordered
    value = loaded.(char(name));
    if istable(value)
        [candidate, names] = localNumericTable(value);
    elseif isnumeric(value) || islogical(value)
        candidate = double(value);
        if isvector(candidate)
            candidate = [];
            names = strings(1,0);
        else
            names = "Column" + string(1:size(candidate,2));
        end
    elseif isstruct(value) && isscalar(value)
        [candidate, names] = localNumericStruct(value);
    else
        candidate = [];
        names = strings(1,0);
    end

    if ~isempty(candidate) && size(candidate,2) >= 2
        numericData = candidate;
        columnNames = names;
        sourceVariable = name;
        return;
    end
end

error('FitDataImport:NoNumericDataset', ...
    'No table, numeric matrix, or compatible scalar struct with at least two numeric vectors was found in the MAT file.');
end

function [numericData, columnNames] = localNumericStruct(value)
names = string(fieldnames(value));
columns = {};
columnNames = strings(1,0);
rowCount = [];
for name = names'
    candidate = value.(char(name));
    if ~(isnumeric(candidate) || islogical(candidate)) || ~isvector(candidate)
        continue;
    end
    candidate = double(candidate(:));
    if isempty(rowCount)
        rowCount = numel(candidate);
    elseif numel(candidate) ~= rowCount
        continue;
    end
    columns{end+1} = candidate; %#ok<AGROW>
    columnNames(end+1) = name; %#ok<AGROW>
end
if numel(columns) >= 2
    numericData = horzcat(columns{:});
else
    numericData = [];
    columnNames = strings(1,0);
end
end
