function guiResult = guiNormalizeRawResult(rawResult, adapterName)
%GUINORMALIZERAWRESULT Convert a raw solver result to normalized GUI branches.
%
% guiResult = guiNormalizeRawResult(rawResult) converts the maintained raw
% Rayleigh-Lamb/mRLFE result schema used by the legacy GUI plotting code into
% the normalized GUI adapter schema. This lets cache-updated GUI results keep a
% normalized representation without re-running a full adapter call.

if nargin < 2 || strlength(string(adapterName)) == 0
    adapterName = "guiNormalizeRawResult";
end

if nargin < 1 || ~isstruct(rawResult)
    error('guiNormalizeRawResult:InvalidInput', 'Expected a raw solver result struct.');
end

branches = repmat(emptyBranch(), 0, 1);

if isfield(rawResult, 'modes')
    if isfield(rawResult.modes, 'A0')
        branches(end+1, 1) = normalizeModeBranch("RayleighLamb", "A0", rawResult.modes.A0, rawResult); %#ok<AGROW>
    end
    if isfield(rawResult.modes, 'S0')
        branches(end+1, 1) = normalizeModeBranch("RayleighLamb", "S0", rawResult.modes.S0, rawResult); %#ok<AGROW>
    end
end

if isfield(rawResult, 'models') && isstruct(rawResult.models)
    branches = [branches; normalizeMRLFEModelBranches(rawResult)]; %#ok<AGROW>
end

guiResult = struct();
guiResult.modelName = inferTopLevelModelName(branches);
guiResult.branchName = "";
guiResult.frequency = getRawFrequency(rawResult);
guiResult.phaseVelocity = [];
guiResult.wavenumber = [];
guiResult.kThickness = [];
guiResult.branches = branches;
guiResult.metadata = struct();
guiResult.metadata.rawResult = rawResult;
guiResult.metadata.adapter = string(adapterName);
guiResult.diagnostics = struct();
guiResult.diagnostics.branchCount = numel(branches);
end

function branches = normalizeMRLFEModelBranches(rawResult)
branches = repmat(emptyBranch(), 0, 1);
modelNames = string(fieldnames(rawResult.models));
modelNames = modelNames(modelNames ~= "mRLFE");

% mRLFERealK is the maintained unified real-k result. Elastic and viscous
% named fields can remain in raw results as reference/compatibility data, but
% the normalized GUI surface should expose only the unified branch.
if any(modelNames == "mRLFERealK")
    modelNames = modelNames(modelNames ~= "mRLFEElasticRealK");
    modelNames = modelNames(modelNames ~= "mRLFEViscoRealK");
    modelNames = modelNames(modelNames ~= "mRLFEHanViscoRealK");
else
    if any(modelNames == "mRLFEElasticRealK")
        modelNames = modelNames(modelNames ~= "mRLFERealK");
    end
    if any(modelNames == "mRLFEViscoRealK")
        modelNames = modelNames(modelNames ~= "mRLFEHanViscoRealK");
    end
end

for iModel = 1:numel(modelNames)
    rawModelName = modelNames(iModel);
    modelName = normalizeModelName(rawModelName);
    modelResult = rawResult.models.(char(rawModelName));
    if ~isfield(modelResult, 'branches') || ~isstruct(modelResult.branches)
        continue;
    end
    branchNames = string(fieldnames(modelResult.branches));
    for iBranch = 1:numel(branchNames)
        branchName = branchNames(iBranch);
        rawBranch = modelResult.branches.(char(branchName));
        branches(end+1, 1) = normalizeModelBranch(modelName, rawModelName, branchName, rawBranch, modelResult); %#ok<AGROW>
    end
end
end

function branch = normalizeModeBranch(modelName, branchName, mode, rawResult)
branch = emptyBranch();
branch.modelName = modelName;
branch.rawModelName = modelName;
branch.branchName = branchName;
branch.frequency = getFieldOrDefault(mode, 'frequency', getRawFrequency(rawResult));
branch.phaseVelocity = getFieldOrDefault(mode, 'Cp', []);
branch.wavenumber = getFieldOrDefault(mode, 'k', []);
branch.kThickness = getFieldOrDefault(mode, 'kThickness', []);
if isempty(branch.kThickness) && ~isempty(branch.wavenumber) && isfield(rawResult, 'geometry') && isfield(rawResult.geometry, 'thickness')
    branch.kThickness = branch.wavenumber(:) .* rawResult.geometry.thickness;
end
branch = finalizeBranch(branch);
branch.metadata.rawBranch = mode;
branch.metadata.units = defaultUnits();
branch.diagnostics.residual = getFieldOrDefault(mode, 'residual', []);
branch.diagnostics.valid = getFieldOrDefault(mode, 'valid', isfinite(branch.phaseVelocity));
end

function branch = normalizeModelBranch(modelName, rawModelName, branchName, rawBranch, modelResult)
branch = emptyBranch();
branch.modelName = modelName;
branch.rawModelName = rawModelName;
branch.branchName = branchName;
branch.frequency = getFieldOrDefault(rawBranch, 'frequency', []);
branch.phaseVelocity = getFieldOrDefault(rawBranch, 'Cp', []);
branch.wavenumber = getFieldOrDefault(rawBranch, 'k', []);
branch.kThickness = getFieldOrDefault(rawBranch, 'kThickness', []);
branch = finalizeBranch(branch);
branch.metadata.rawBranch = rawBranch;
branch.metadata.rawModel = modelResult;
branch.metadata.rawModelName = rawModelName;
branch.metadata.units = defaultUnits();
branch.diagnostics.residual = getFieldOrDefault(rawBranch, 'residual', []);
branch.diagnostics.valid = getFieldOrDefault(rawBranch, 'valid', isfinite(branch.phaseVelocity));
if isfield(rawBranch, 'validCp')
    branch.diagnostics.validCp = rawBranch.validCp;
end
if isfield(rawBranch, 'objective')
    branch.diagnostics.objective = rawBranch.objective;
end
if isfield(rawBranch, 'pointStatus')
    branch.diagnostics.pointStatus = rawBranch.pointStatus;
end
end

function modelName = normalizeModelName(rawModelName)
rawModelName = string(rawModelName);
switch rawModelName
    case {"mRLFEHanViscoRealK", "mRLFEViscoRealK"}
        modelName = "mRLFERealK";
    otherwise
        modelName = rawModelName;
end
end

function branch = finalizeBranch(branch)
branch.frequency = branch.frequency(:);
branch.phaseVelocity = branch.phaseVelocity(:);
branch.wavenumber = branch.wavenumber(:);
branch.kThickness = branch.kThickness(:);
end

function branch = emptyBranch()
branch = struct();
branch.modelName = "";
branch.rawModelName = "";
branch.branchName = "";
branch.frequency = [];
branch.phaseVelocity = [];
branch.wavenumber = [];
branch.kThickness = [];
branch.metadata = struct();
branch.diagnostics = struct();
end

function frequency = getRawFrequency(rawResult)
if isfield(rawResult, 'grid') && isfield(rawResult.grid, 'frequency')
    frequency = rawResult.grid.frequency(:);
else
    frequency = [];
end
end

function units = defaultUnits()
units = struct('frequency', 'Hz', 'phaseVelocity', 'm/s', 'wavenumber', '1/m', 'kThickness', 'dimensionless');
end

function modelName = inferTopLevelModelName(branches)
if isempty(branches)
    modelName = "";
elseif any(string({branches.modelName}) == "mRLFERealK") || any(string({branches.modelName}) == "mRLFEElasticRealK")
    modelName = "mRLFE";
else
    modelName = "RayleighLamb";
end
end

function value = getFieldOrDefault(s, fieldName, defaultValue)
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = s.(fieldName);
else
    value = defaultValue;
end
end
