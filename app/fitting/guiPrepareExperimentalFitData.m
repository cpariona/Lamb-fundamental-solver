function prepared = guiPrepareExperimentalFitData(imported, varargin)
%GUIPREPAREEXPERIMENTALFITDATA Select, convert, validate, and sort fit data.

p = inputParser;
addRequired(p, 'imported', @isstruct);
addParameter(p, 'FrequencyColumn', 1, @(x)isnumeric(x) && isscalar(x) && x >= 1);
addParameter(p, 'PhaseSpeedColumn', 2, @(x)isnumeric(x) && isscalar(x) && x >= 1);
addParameter(p, 'UseColumn', 0, @(x)isnumeric(x) && isscalar(x) && x >= 0);
addParameter(p, 'FrequencyUnit', "Hz", @(x)ischar(x) || isstring(x));
addParameter(p, 'PhaseSpeedUnit', "m/s", @(x)ischar(x) || isstring(x));
addParameter(p, 'DuplicatePolicy', "mean", @(x)ischar(x) || isstring(x));
parse(p, imported, varargin{:});

if ~isfield(imported, 'numericData') || ~isnumeric(imported.numericData)
    error('FitDataImport:InvalidImportedData', 'Imported data must contain numericData.');
end

data = double(imported.numericData);
nColumns = size(data, 2);
freqColumn = p.Results.FrequencyColumn;
cpColumn = p.Results.PhaseSpeedColumn;
useColumn = p.Results.UseColumn;
if any([freqColumn, cpColumn] > nColumns) || (useColumn > 0 && useColumn > nColumns)
    error('FitDataImport:ColumnOutOfRange', 'Selected column index exceeds the imported data width.');
end
if freqColumn == cpColumn
    error('FitDataImport:DuplicateColumnRole', 'Frequency and phase-speed columns must be different.');
end

frequency = data(:, freqColumn);
phaseSpeed = data(:, cpColumn);
frequencyUnit = string(p.Results.FrequencyUnit);
phaseSpeedUnit = string(p.Results.PhaseSpeedUnit);

switch lower(frequencyUnit)
    case "hz"
        frequencyScale = 1;
    case "khz"
        frequencyScale = 1e3;
    case "mhz"
        frequencyScale = 1e6;
    otherwise
        error('FitDataImport:UnsupportedFrequencyUnit', 'Unsupported frequency unit: %s.', frequencyUnit);
end
switch lower(phaseSpeedUnit)
    case {"m/s", "mps"}
        speedScale = 1;
    case {"mm/s", "mmps"}
        speedScale = 1e-3;
    otherwise
        error('FitDataImport:UnsupportedSpeedUnit', 'Unsupported phase-speed unit: %s.', phaseSpeedUnit);
end

frequency = frequency .* frequencyScale;
phaseSpeed = phaseSpeed .* speedScale;
if useColumn > 0
    requestedUse = data(:, useColumn) ~= 0;
else
    requestedUse = true(size(frequency));
end

finiteMask = isfinite(frequency) & isfinite(phaseSpeed);
positiveMask = frequency > 0 & phaseSpeed > 0;
keptMask = finiteMask & positiveMask;
frequency = frequency(keptMask);
phaseSpeed = phaseSpeed(keptMask);
requestedUse = requestedUse(keptMask);

if numel(frequency) < 2
    error('FitDataImport:InsufficientValidRows', ...
        'At least two finite rows with positive frequency and phase speed are required.');
end

[frequency, order] = sort(frequency, 'ascend');
phaseSpeed = phaseSpeed(order);
requestedUse = requestedUse(order);

[uniqueFrequency, ~, group] = unique(frequency, 'stable');
duplicateCount = numel(frequency) - numel(uniqueFrequency);
policy = lower(string(p.Results.DuplicatePolicy));
if duplicateCount > 0
    switch policy
        case "mean"
            phaseSpeed = accumarray(group, phaseSpeed, [], @mean);
            requestedUse = accumarray(group, requestedUse, [], @any);
            frequency = uniqueFrequency;
        case "first"
            firstIndex = accumarray(group, (1:numel(group))', [], @min);
            phaseSpeed = phaseSpeed(firstIndex);
            requestedUse = requestedUse(firstIndex);
            frequency = uniqueFrequency;
        case "error"
            error('FitDataImport:DuplicateFrequency', 'Duplicate frequency values were found.');
        otherwise
            error('FitDataImport:UnsupportedDuplicatePolicy', 'Unsupported duplicate policy: %s.', policy);
    end
end

prepared = struct();
prepared.frequency_Hz = frequency(:);
prepared.Cp_mps = phaseSpeed(:);
prepared.validMask = logical(requestedUse(:));
prepared.tableData = [prepared.frequency_Hz, prepared.Cp_mps, double(prepared.validMask)];
prepared.metadata = struct();
prepared.metadata.sourceType = "experimental_file";
prepared.metadata.filePath = localField(imported, 'filePath', "");
prepared.metadata.fileName = localField(imported, 'fileName', "");
prepared.metadata.sourceVariable = localField(imported, 'sourceVariable', "");
prepared.metadata.frequencyColumn = freqColumn;
prepared.metadata.phaseSpeedColumn = cpColumn;
prepared.metadata.useColumn = useColumn;
prepared.metadata.frequencyColumnName = localColumnName(imported, freqColumn);
prepared.metadata.phaseSpeedColumnName = localColumnName(imported, cpColumn);
prepared.metadata.useColumnName = localColumnName(imported, useColumn);
prepared.metadata.inputFrequencyUnit = frequencyUnit;
prepared.metadata.inputPhaseSpeedUnit = phaseSpeedUnit;
prepared.metadata.outputFrequencyUnit = "Hz";
prepared.metadata.outputPhaseSpeedUnit = "m/s";
prepared.metadata.duplicatePolicy = policy;
prepared.metadata.duplicateRowsCollapsed = duplicateCount;
prepared.metadata.inputRows = size(data,1);
prepared.metadata.removedInvalidRows = size(data,1) - nnz(keptMask);
prepared.metadata.outputRows = numel(frequency);
prepared.metadata.sortedByFrequency = true;
end

function value = localField(s, name, defaultValue)
if isfield(s, name) && ~isempty(s.(name))
    value = string(s.(name));
else
    value = string(defaultValue);
end
end

function name = localColumnName(imported, index)
if index <= 0
    name = "";
elseif isfield(imported, 'columnNames') && numel(imported.columnNames) >= index
    name = string(imported.columnNames(index));
else
    name = "Column" + string(index);
end
end
