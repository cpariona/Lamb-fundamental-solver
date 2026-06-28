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
% Rayleigh-Lamb A0/S0 branches are computed only as seeds for mRLFE. This
% adapter exposes only the maintained mRLFERealK branch on the normalized GUI
% plotting surface. Seed branches remain available in result.metadata.rawResult.

if nargin < 1 || isempty(guiRequest)
    guiRequest = struct();
end

params = mergeStructs(rlDefaultParams(), getStructField(guiRequest, 'params', struct()));
options = mergeStructs(rlDefaultOptions(), getStructField(guiRequest, 'options', struct()));

computeVisco = logical(getStructField(guiRequest, 'computeVisco', false));
computeA0Like = getStructField(options, 'mrlfeComputeA0Like', true);
computeS0Like = getStructField(options, 'mrlfeComputeS0Like', true);

if isfield(guiRequest, 'mrlfeParams') && isstruct(guiRequest.mrlfeParams)
    options.mrlfeParams = guiRequest.mrlfeParams;
end
if ~isfield(options, 'mrlfeParams') || isempty(options.mrlfeParams)
    options.mrlfeParams = defaultMRLFEParams();
end
options.mrlfeParams.solveComplexK = false;
options.mrlfeParams.etaL = 0;
options.mrlfeParams.useComplexLambda = false;

options.computeMRLFE = false;
options.computeMRLFEElasticRealK = false;
options.computeMRLFEViscoRealK = false;
options.computeMRLFERealK = false;
options.computeMRLFEComplexK = false;
options.mrlfeUseUnifiedAtlasRoute = logical(getStructField(options, 'mrlfeUseUnifiedAtlasRoute', computeVisco));
options.mrlfeA0Policy = string(getStructField(options, 'mrlfeA0Policy', "delayedCut"));
options.mrlfeComputeA0Like = logical(computeA0Like);
options.mrlfeComputeS0Like = logical(computeS0Like);

seedOptions = options;
seedOptions.computeA0 = logical(getStructField(options, 'computeA0', true) || computeA0Like);
seedOptions.computeS0 = logical(getStructField(options, 'computeS0', false) || computeS0Like);
seedOptions.computeMRLFE = false;
seedOptions.computeMRLFEElasticRealK = false;
seedOptions.computeMRLFEViscoRealK = false;
seedOptions.computeMRLFERealK = false;
seedOptions.computeMRLFEComplexK = false;

elapsedTimer = tic;
rawResult = rlComputeFundamentalLambModes(params, seedOptions);
frequency = rawResult.grid.frequency(:);
if shouldUseUnifiedAtlas(options, computeVisco)
    mrlfeResult = solveMRLFEAtlasUnified(frequency, rawResult.material, rawResult.geometry, rawResult.modes, options.mrlfeParams, options);
else
    elasticParams = options.mrlfeParams;
    elasticParams.etaS = 0;
    mrlfeResult = computeMRLFE(frequency, rawResult.material, rawResult.geometry, rawResult.modes, elasticParams, options);
end
rawResult.models.mRLFERealK = mrlfeResult;
rawResult.models.mRLFE = mrlfeResult;
elapsedSeconds = toc(elapsedTimer);

result = guiNormalizeRawResult(rawResult, mfilename);
result.branches = filterMRLFEBranches(result.branches);
result.diagnostics.branchCount = numel(result.branches);
result.diagnostics.elapsedSeconds = elapsedSeconds;
result.diagnostics.seedBranchesHiddenFromPlotSurface = true;
result.diagnostics.mrlfeUseUnifiedAtlasRoute = options.mrlfeUseUnifiedAtlasRoute;
result.diagnostics.mrlfeA0Policy = options.mrlfeA0Policy;
result.metadata.params = params;
result.metadata.options = options;
result.metadata.elapsedSeconds = elapsedSeconds;
result.metadata.seedBranchesHiddenFromPlotSurface = true;
result.metadata.mrlfeUseUnifiedAtlasRoute = options.mrlfeUseUnifiedAtlasRoute;
result.metadata.mrlfeA0Policy = options.mrlfeA0Policy;
end

function tf = shouldUseUnifiedAtlas(options, computeVisco)
etaS = 0;
if isfield(options, 'mrlfeParams') && isfield(options.mrlfeParams, 'etaS') && ~isempty(options.mrlfeParams.etaS)
    etaS = options.mrlfeParams.etaS;
end
tf = logical(computeVisco) && etaS > 0 && logical(getStructField(options, 'mrlfeUseUnifiedAtlasRoute', true));
end

function branches = filterMRLFEBranches(branches)
if isempty(branches)
    return;
end
modelNames = string({branches.modelName});
keep = modelNames == "mRLFERealK";
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
