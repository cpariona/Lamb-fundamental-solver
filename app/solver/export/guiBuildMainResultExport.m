function exportData = guiBuildMainResultExport(guiResult, physicalParameters)
%GUIBUILDMAINRESULTEXPORT Build the compact LambFundamental_GUI export payload.
%
% exportData = guiBuildMainResultExport(guiResult, physicalParameters)
% converts the normalized GUI-visible branches into one curve table per branch.
% The export contract is intentionally limited to frequency, phase velocity,
% validity, and the physical parameters captured from the interface.

if nargin < 1 || ~isstruct(guiResult) || ~isfield(guiResult, 'branches') || isempty(guiResult.branches)
    error('guiBuildMainResultExport:MissingBranches', ...
        'Expected a normalized GUI result with at least one visible branch.');
end
if nargin < 2 || ~isstruct(physicalParameters)
    error('guiBuildMainResultExport:InvalidPhysicalParameters', ...
        'Expected the physical parameters captured from the interface.');
end

branches = guiResult.branches(:);
curves = repmat(emptyCurve(), numel(branches), 1);
for i = 1:numel(branches)
    branch = branches(i);
    frequency = getRequiredColumn(branch, 'frequency');
    phaseVelocity = getRequiredColumn(branch, 'phaseVelocity');
    if numel(frequency) ~= numel(phaseVelocity)
        error('guiBuildMainResultExport:InconsistentBranchLength', ...
            'Frequency and phase-velocity vectors must have the same length.');
    end

    valid = isfinite(frequency) & isfinite(phaseVelocity);
    valid = combineDiagnosticMask(valid, branch, 'valid');
    valid = combineDiagnosticMask(valid, branch, 'validCp');

    curves(i).model = string(getScalarField(branch, 'modelName', ""));
    curves(i).branch = string(getScalarField(branch, 'branchName', ""));
    curves(i).data = table(frequency, phaseVelocity, valid, ...
        'VariableNames', {'Frequency_Hz', 'PhaseVelocity_mps', 'Valid'});
end

exportData = struct();
exportData.curves = curves;
exportData.parameters = physicalParameters;
end

function curve = emptyCurve()
curve = struct('model', "", 'branch', "", 'data', table());
end

function value = getRequiredColumn(s, fieldName)
if ~isfield(s, fieldName) || isempty(s.(fieldName))
    error('guiBuildMainResultExport:MissingBranchField', ...
        'Normalized branch is missing required field: %s.', fieldName);
end
value = s.(fieldName)(:);
end

function value = getScalarField(s, fieldName, defaultValue)
if isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = s.(fieldName);
else
    value = defaultValue;
end
end

function valid = combineDiagnosticMask(valid, branch, fieldName)
if ~isfield(branch, 'diagnostics') || ~isstruct(branch.diagnostics) || ...
        ~isfield(branch.diagnostics, fieldName) || isempty(branch.diagnostics.(fieldName))
    return;
end
mask = logical(branch.diagnostics.(fieldName)(:));
if numel(mask) ~= numel(valid)
    error('guiBuildMainResultExport:InconsistentValidityLength', ...
        'Diagnostic validity mask %s has an inconsistent length.', fieldName);
end
valid = valid & mask;
end