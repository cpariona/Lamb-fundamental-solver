function result = guiRunMRLFEModel(guiRequest)
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
options.mrlfeUseUnifiedAtlasRoute = true;
options.mrlfeA0Policy = string(getStructField(options, 'mrlfeA0Policy', "adaptivePhysicalTail"));
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
options = applyGuiAtlasPreset(options, computeVisco);
mrlfeResult = solveMRLFEAtlasUnified(rawResult.grid.frequency(:), rawResult.material, rawResult.geometry, rawResult.modes, options.mrlfeParams, options);
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
result.diagnostics.mrlfeGuiAtlasPreset = getStructField(options, 'mrlfeGuiAtlasPreset', "none");
result.metadata.params = params;
result.metadata.options = options;
result.metadata.elapsedSeconds = elapsedSeconds;
result.metadata.seedBranchesHiddenFromPlotSurface = true;
result.metadata.mrlfeUseUnifiedAtlasRoute = options.mrlfeUseUnifiedAtlasRoute;
result.metadata.mrlfeA0Policy = options.mrlfeA0Policy;
result.metadata.mrlfeGuiAtlasPreset = getStructField(options, 'mrlfeGuiAtlasPreset', "none");
end

function options = applyGuiAtlasPreset(options, computeVisco)
if ~logical(getStructField(options, 'mrlfeUseGuiFastAtlasPreset', true))
    options.mrlfeGuiAtlasPreset = "off";
    return;
end
if computeVisco
    options.mrlfeGuiAtlasPreset = "fast_viscous";
else
    options.mrlfeGuiAtlasPreset = "fast_elastic";
end
options.mrlfeModalAtlasApplyAmbiguityCut = getStructField(options, 'mrlfeModalAtlasApplyAmbiguityCut', false);
options.mrlfeModalAtlasCpScanPoints = getStructField(options, 'mrlfeModalAtlasCpScanPoints', 420);
options.mrlfeModalAtlasTopNMinima = getStructField(options, 'mrlfeModalAtlasTopNMinima', 12);
options.mrlfeModalAtlasRefineMinima = getStructField(options, 'mrlfeModalAtlasRefineMinima', false);
options.mrlfeModalAtlasRequireResidualValidity = getStructField(options, 'mrlfeModalAtlasRequireResidualValidity', false);
options.mrlfeViscoAtlasCpScanPoints = getStructField(options, 'mrlfeViscoAtlasCpScanPoints', 260);
options.mrlfeA0DPCpScanPoints = getStructField(options, 'mrlfeA0DPCpScanPoints', 260);
options.mrlfeA0DPCandidates = getStructField(options, 'mrlfeA0DPCandidates', 5);
options.mrlfeA0DPRefineCandidates = getStructField(options, 'mrlfeA0DPRefineCandidates', false);
options.mrlfeAdaptiveCpScanPoints = getStructField(options, 'mrlfeAdaptiveCpScanPoints', 260);
options.mrlfeAdaptiveRefineCandidates = getStructField(options, 'mrlfeAdaptiveRefineCandidates', false);
options.mrlfeAdaptiveWindows = getStructField(options, 'mrlfeAdaptiveWindows', [0.20 0.40 0.80]);
options.mrlfeAdaptiveValleyFallbackRelativeWindow = getStructField(options, 'mrlfeAdaptiveValleyFallbackRelativeWindow', 0.12);
end

function branches = filterMRLFEBranches(branches)
if isempty(branches)
    return;
end
modelNames = string({branches.modelName});
branches = branches(modelNames == "mRLFERealK");
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
