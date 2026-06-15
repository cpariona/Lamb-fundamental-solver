function branchTable = guiNormalizedBranchToTable(branch)
%GUINORMALIZEDBRANCHTOTABLE Convert a normalized GUI branch struct to a table.
%
% branchTable = guiNormalizedBranchToTable(branch) converts one normalized
% adapter branch into a table suitable for workspace export. The helper keeps
% table schema decisions outside GUI callbacks so future plotting/export code
% can consume the same normalized adapter results.

if nargin < 1 || ~isstruct(branch)
    error('guiNormalizedBranchToTable:InvalidInput', 'Expected a normalized GUI branch struct.');
end

frequency = getColumn(branch, 'frequency');
phaseVelocity = getColumn(branch, 'phaseVelocity');
wavenumber = getColumn(branch, 'wavenumber');
kThickness = getColumn(branch, 'kThickness');

n = max([numel(frequency), numel(phaseVelocity), numel(wavenumber), numel(kThickness), 0]);
frequency = padColumn(frequency, n);
phaseVelocity = padColumn(phaseVelocity, n);
wavenumber = padColumn(wavenumber, n);
kThickness = padColumn(kThickness, n);

modelName = repmat(string(getScalarField(branch, 'modelName', "")), n, 1);
branchName = repmat(string(getScalarField(branch, 'branchName', "")), n, 1);

branchTable = table(modelName, branchName, frequency, phaseVelocity, wavenumber, kThickness, ...
    'VariableNames', {'ModelName','BranchName','Frequency_Hz','PhaseVelocity_mps','Wavenumber_1_per_m','kThickness'});

if isfield(branch, 'diagnostics') && isstruct(branch.diagnostics)
    if isfield(branch.diagnostics, 'valid')
        branchTable.Valid = logical(padColumn(branch.diagnostics.valid(:), n));
    end
    if isfield(branch.diagnostics, 'validCp')
        branchTable.ValidCp = logical(padColumn(branch.diagnostics.validCp(:), n));
    end
    if isfield(branch.diagnostics, 'residual')
        branchTable.Residual = padColumn(branch.diagnostics.residual(:), n);
    end
    if isfield(branch.diagnostics, 'objective')
        branchTable.Objective = padColumn(branch.diagnostics.objective(:), n);
    end
    if isfield(branch.diagnostics, 'pointStatus')
        branchTable.PointStatus = string(padStringColumn(branch.diagnostics.pointStatus(:), n));
    end
end
end

function value = getColumn(s, fieldName)
if isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = s.(fieldName)(:);
else
    value = [];
end
end

function value = getScalarField(s, fieldName, defaultValue)
if isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = s.(fieldName);
else
    value = defaultValue;
end
end

function value = padColumn(value, n)
value = value(:);
if isempty(value)
    value = nan(n, 1);
elseif numel(value) < n
    value(end+1:n, 1) = nan;
end
end

function value = padStringColumn(value, n)
value = string(value(:));
if isempty(value)
    value = strings(n, 1);
elseif numel(value) < n
    value(end+1:n, 1) = "";
end
end
