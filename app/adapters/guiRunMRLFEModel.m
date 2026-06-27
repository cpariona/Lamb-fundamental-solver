function result = guiRunMRLFEModel(guiRequest)
%GUIRUNMRLFEMODEL Run maintained mRLFE workflows for GUI usage.
%
% Expected optional guiRequest fields:
%   params           - struct overlay for rlDefaultParams()
%   options          - struct overlay for rlDefaultOptions()
%   mrlfeParams      - struct overlay stored in options.mrlfeParams
%   computeElastic   - logical, default true
%   computeVisco     - logical, default false
%
% Rayleigh-Lamb A0/S0 branches may be computed internally as seeds for mRLFE,
% but this adapter exposes only mRLFE branches on the normalized GUI plotting
% surface. The seed branches remain available in result.metadata.rawResult.

if nargin < 1 || isempty(guiRequest)
    guiRequest = struct();
end

params = mergeStructs(rlDefaultParams(), getStructField(guiRequest, 'params', struct()));
options = mergeStructs(rlDefaultOptions(), getStructField(guiRequest, 'options', struct()));

computeElastic = getStructField(guiRequest, 'computeElastic', true);
computeVisco = getStructField(guiRequest, 'computeVisco', false);
computeA0Like = getStructField(options, 'mrlfeComputeA0Like', true);
computeS0Like = getStructField(options, 'mrlfeComputeS0Like', true);
computeMRLFE = logical(computeElastic || computeVisco);

options.computeA0 = logical(getStructField(options, 'computeA0', true) || (computeMRLFE && computeA0Like));
options.computeS0 = logical(getStructField(options, 'computeS0', true) || (computeMRLFE && computeS0Like));
options.computeMRLFE = false;
options.computeMRLFEElasticRealK = logical(computeElastic || computeVisco);
options.computeMRLFEViscoRealK = logical(computeVisco);
options.computeMRLFERealK = options.computeMRLFEElasticRealK;

if isfield(guiRequest, 'mrlfeParams') && isstruct(guiRequest.mrlfeParams)
    options.mrlfeParams = guiRequest.mrlfeParams;
end

elapsedTimer = tic;
rawResult = rlComputeFundamentalLambModes(params, options);
elapsedSeconds = toc(elapsedTimer);

result = guiNormalizeRawResult(rawResult, mfilename);
result.branches = filterMRLFEBranches(result.branches);
result.diagnostics.branchCount = numel(result.branches);
result.diagnostics.elapsedSeconds = elapsedSeconds;
result.diagnostics.seedBranchesHiddenFromPlotSurface = true;
result.metadata.params = params;
result.metadata.options = options;
result.metadata.elapsedSeconds = elapsedSeconds;
result.metadata.seedBranchesHiddenFromPlotSurface = true;
end

function branches = filterMRLFEBranches(branches)
if isempty(branches)
    return;
end
modelNames = string({branches.modelName});
keep = modelNames == "mRLFERealK" | modelNames == "mRLFEElasticRealK" | modelNames == "mRLFEViscoRealK";
branches = branches(keep);
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
