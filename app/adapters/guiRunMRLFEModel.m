function result = guiRunMRLFEModel(guiRequest)
%GUIRUNMRLFEMODEL Run maintained mRLFE workflows for GUI usage.
%
% result = guiRunMRLFEModel(guiRequest) prepares Rayleigh-Lamb seed modes,
% calls the maintained mRLFE solver surface through the existing rl* workflow,
% and returns normalized mRLFE branch results.
%
% Expected optional guiRequest fields:
%   params         - struct overlay for rlDefaultParams()
%   options        - struct overlay for rlDefaultOptions()
%   mrlfeParams    - struct overlay stored in options.mrlfeParams
%   computeElastic - logical, default true
%   computeHan     - logical, default false
%
% This adapter does not rename mRLFE model functions or change numerical
% solver behavior. It centralizes GUI-facing model calls for later UI cleanup.

if nargin < 1 || isempty(guiRequest)
    guiRequest = struct();
end

params = mergeStructs(rlDefaultParams(), getStructField(guiRequest, 'params', struct()));
options = mergeStructs(rlDefaultOptions(), getStructField(guiRequest, 'options', struct()));

computeElastic = getStructField(guiRequest, 'computeElastic', true);
computeHan = getStructField(guiRequest, 'computeHan', false);
computeA0Like = getStructField(options, 'mrlfeComputeA0Like', true);
computeS0Like = getStructField(options, 'mrlfeComputeS0Like', true);
computeMRLFE = logical(computeElastic || computeHan);

options.computeA0 = logical(getStructField(options, 'computeA0', true) || (computeMRLFE && computeA0Like));
options.computeS0 = logical(getStructField(options, 'computeS0', true) || (computeMRLFE && computeS0Like));
options.computeMRLFE = false;
options.computeMRLFERealK = logical(computeElastic || computeHan);
options.computeMRLFEHanViscoRealK = logical(computeHan);

if isfield(guiRequest, 'mrlfeParams') && isstruct(guiRequest.mrlfeParams)
    options.mrlfeParams = guiRequest.mrlfeParams;
end

rawResult = rlComputeFundamentalLambModes(params, options);

result = struct();
result.modelName = "mRLFE";
result.branchName = "";
result.frequency = rawResult.grid.frequency(:);
result.phaseVelocity = [];
result.wavenumber = [];
result.kThickness = [];
result.branches = normalizeMRLFEBranches(rawResult);
result.metadata = struct();
result.metadata.params = params;
result.metadata.options = options;
result.metadata.rawResult = rawResult;
result.metadata.adapter = mfilename;
result.diagnostics = struct();
result.diagnostics.branchCount = numel(result.branches);
end

function branches = normalizeMRLFEBranches(rawResult)
branches = repmat(emptyBranch(), 0, 1);
if ~isfield(rawResult, 'models')
    return;
end

modelNames = string(fieldnames(rawResult.models));
modelNames = modelNames(modelNames ~= "mRLFE");
if any(modelNames == "mRLFEElasticRealK")
    % mRLFERealK is a compatibility alias for mRLFEElasticRealK in the raw
    % solver result. Keep only the explicit maintained model name so the GUI
    % normalized result does not plot/export duplicated elastic branches.
    modelNames = modelNames(modelNames ~= "mRLFERealK");
end

for i = 1:numel(modelNames)
    modelName = modelNames(i);
    modelResult = rawResult.models.(char(modelName));
    if ~isfield(modelResult, 'branches')
        continue;
    end
    branchNames = string(fieldnames(modelResult.branches));
    for j = 1:numel(branchNames)
        branchName = branchNames(j);
        branch = modelResult.branches.(char(branchName));
        branches(end+1, 1) = normalizeMRLFEBranch(modelName, branchName, branch, modelResult); %#ok<AGROW>
    end
end
end

function out = normalizeMRLFEBranch(modelName, branchName, branch, modelResult)
out = emptyBranch();
out.modelName = modelName;
out.branchName = branchName;
out.frequency = getFieldOrDefault(branch, 'frequency', []);
out.phaseVelocity = getFieldOrDefault(branch, 'Cp', []);
out.wavenumber = getFieldOrDefault(branch, 'k', []);
out.kThickness = getFieldOrDefault(branch, 'kThickness', []);
out.frequency = out.frequency(:);
out.phaseVelocity = out.phaseVelocity(:);
out.wavenumber = out.wavenumber(:);
out.kThickness = out.kThickness(:);
out.metadata = struct();
out.metadata.rawBranch = branch;
out.metadata.rawModel = modelResult;
out.metadata.units = struct('frequency', 'Hz', 'phaseVelocity', 'm/s', 'wavenumber', '1/m', 'kThickness', 'dimensionless');
out.diagnostics = struct();
out.diagnostics.residual = getFieldOrDefault(branch, 'residual', []);
out.diagnostics.valid = getFieldOrDefault(branch, 'valid', isfinite(out.phaseVelocity));
if isfield(branch, 'validCp')
    out.diagnostics.validCp = branch.validCp;
end
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
