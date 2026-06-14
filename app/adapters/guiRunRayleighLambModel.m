function result = guiRunRayleighLambModel(guiRequest)
%GUIRUNRAYLEIGHLAMBMODEL Run the Rayleigh-Lamb model for GUI workflows.
%
% result = guiRunRayleighLambModel(guiRequest) converts a GUI request struct
% into Rayleigh-Lamb params/options, calls the maintained rl* API, and returns
% normalized branch results for later plotting/export layers.
%
% Expected optional guiRequest fields:
%   params  - struct overlay for rlDefaultParams()
%   options - struct overlay for rlDefaultOptions()
%
% This adapter does not change numerical solver behavior.

if nargin < 1 || isempty(guiRequest)
    guiRequest = struct();
end

params = mergeStructs(rlDefaultParams(), getStructField(guiRequest, 'params', struct()));
options = mergeStructs(rlDefaultOptions(), getStructField(guiRequest, 'options', struct()));

rawResult = rlComputeFundamentalLambModes(params, options);

result = struct();
result.modelName = "RayleighLamb";
result.branchName = "";
result.frequency = rawResult.grid.frequency(:);
result.phaseVelocity = [];
result.wavenumber = [];
result.kThickness = [];
result.branches = normalizeRayleighLambBranches(rawResult);
result.metadata = struct();
result.metadata.params = params;
result.metadata.options = options;
result.metadata.rawResult = rawResult;
result.metadata.adapter = mfilename;
result.diagnostics = struct();
result.diagnostics.branchCount = numel(result.branches);
end

function branches = normalizeRayleighLambBranches(rawResult)
branches = repmat(emptyBranch(), 0, 1);
if isfield(rawResult, 'modes')
    if isfield(rawResult.modes, 'A0')
        branches(end+1, 1) = normalizeModeBranch("RayleighLamb", "A0", rawResult.modes.A0, rawResult); %#ok<AGROW>
    end
    if isfield(rawResult.modes, 'S0')
        branches(end+1, 1) = normalizeModeBranch("RayleighLamb", "S0", rawResult.modes.S0, rawResult); %#ok<AGROW>
    end
end
end

function branch = normalizeModeBranch(modelName, branchName, mode, rawResult)
branch = emptyBranch();
branch.modelName = modelName;
branch.branchName = branchName;
branch.frequency = getFieldOrDefault(mode, 'frequency', rawResult.grid.frequency(:));
branch.phaseVelocity = getFieldOrDefault(mode, 'Cp', []);
branch.wavenumber = getFieldOrDefault(mode, 'k', []);
branch.kThickness = getFieldOrDefault(mode, 'kThickness', []);
if isempty(branch.kThickness) && ~isempty(branch.wavenumber) && isfield(rawResult, 'geometry') && isfield(rawResult.geometry, 'thickness')
    branch.kThickness = branch.wavenumber(:) .* rawResult.geometry.thickness;
end
branch.frequency = branch.frequency(:);
branch.phaseVelocity = branch.phaseVelocity(:);
branch.wavenumber = branch.wavenumber(:);
branch.kThickness = branch.kThickness(:);
branch.metadata = struct();
branch.metadata.rawBranch = mode;
branch.metadata.units = struct('frequency', 'Hz', 'phaseVelocity', 'm/s', 'wavenumber', '1/m', 'kThickness', 'dimensionless');
branch.diagnostics = struct();
branch.diagnostics.residual = getFieldOrDefault(mode, 'residual', []);
branch.diagnostics.valid = isfinite(branch.phaseVelocity);
end

function branch = emptyBranch()
branch = struct();
branch.modelName = "";
branch.branchName = "";
branch.frequency = [];
branch.phaseVelocity = [];
branch.wavenumber = [];
branch.kThickness = [];
branch.metadata = struct();
branch.diagnostics = struct();
end

function value = getStructField(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end

function base = mergeStructs(base, overlay)
if ~isstruct(overlay)
    return;
end
names = fieldnames(overlay);
for i = 1:numel(names)
    base.(names{i}) = overlay.(names{i});
end
end

function value = getFieldOrDefault(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
