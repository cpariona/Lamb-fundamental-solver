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
options.mrlfeUseUnifiedAtlasRoute = logical(getStructField(options, 'mrlfeUseUnifiedAtlasRoute', computeVisco));
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
useViscousAtlas = shouldUseUnifiedAtlas(options, computeVisco);
useElasticAtlas = shouldUseElasticAtlas(options, computeVisco);
elasticAtlasFallback = false;
elasticAtlasQuality = struct('validFraction', NaN, 'validCount', 0, 'totalCount', 0);
actualRoute = "elastic_reference";

if useViscousAtlas
    options = applyGuiAtlasPreset(options, "viscous");
    mrlfeResult = solveMRLFEAtlasUnified(rawResult.grid.frequency(:), rawResult.material, rawResult.geometry, rawResult.modes, options.mrlfeParams, options);
    actualRoute = "viscous_unified_atlas";
elseif useElasticAtlas
    options = applyGuiAtlasPreset(options, "elastic_atlas");
    candidate = solveMRLFEAtlasUnified(rawResult.grid.frequency(:), rawResult.material, rawResult.geometry, rawResult.modes, options.mrlfeParams, options);
    elasticAtlasQuality = summarizeMRLFEAtlasCpQuality(candidate);
    minValidFraction = getStructField(options, 'mrlfeElasticAtlasGuiMinValidFraction', 0.85);
    if elasticAtlasQuality.validFraction >= minValidFraction
        mrlfeResult = candidate;
        actualRoute = "elastic_modal_atlas";
    else
        elasticAtlasFallback = true;
        mrlfeResult = computeElasticReference(rawResult, options);
        actualRoute = "elastic_reference_fallback";
    end
else
    options = applyGuiAtlasPreset(options, "elastic_reference");
    mrlfeResult = computeElasticReference(rawResult, options);
end

rawResult.models.mRLFERealK = mrlfeResult;
rawResult.models.mRLFE = mrlfeResult;
elapsedSeconds = toc(elapsedTimer);

result = guiNormalizeRawResult(rawResult, mfilename);
result.branches = filterMRLFEBranches(result.branches);
result.diagnostics.branchCount = numel(result.branches);
result.diagnostics.elapsedSeconds = elapsedSeconds;
result.diagnostics.seedBranchesHiddenFromPlotSurface = true;
result.diagnostics.mrlfeUseUnifiedAtlasRoute = useViscousAtlas || (useElasticAtlas && ~elasticAtlasFallback);
result.diagnostics.mrlfeUseElasticAtlasGuiRoute = useElasticAtlas;
result.diagnostics.mrlfeElasticAtlasFallback = elasticAtlasFallback;
result.diagnostics.mrlfeElasticAtlasQuality = elasticAtlasQuality;
result.diagnostics.mrlfeGuiActualRoute = actualRoute;
result.diagnostics.mrlfeA0Policy = options.mrlfeA0Policy;
result.diagnostics.mrlfeGuiAtlasPreset = getStructField(options, 'mrlfeGuiAtlasPreset', "none");
result.metadata.params = params;
result.metadata.options = options;
result.metadata.elapsedSeconds = elapsedSeconds;
result.metadata.seedBranchesHiddenFromPlotSurface = true;
result.metadata.mrlfeUseUnifiedAtlasRoute = result.diagnostics.mrlfeUseUnifiedAtlasRoute;
result.metadata.mrlfeUseElasticAtlasGuiRoute = useElasticAtlas;
result.metadata.mrlfeElasticAtlasFallback = elasticAtlasFallback;
result.metadata.mrlfeElasticAtlasQuality = elasticAtlasQuality;
result.metadata.mrlfeGuiActualRoute = actualRoute;
result.metadata.mrlfeA0Policy = options.mrlfeA0Policy;
result.metadata.mrlfeGuiAtlasPreset = getStructField(options, 'mrlfeGuiAtlasPreset', "none");
end

function mrlfeResult = computeElasticReference(rawResult, options)
elasticParams = options.mrlfeParams;
elasticParams.etaS = 0;
mrlfeResult = computeMRLFE(rawResult.grid.frequency(:), rawResult.material, rawResult.geometry, rawResult.modes, elasticParams, options);
end

function tf = shouldUseUnifiedAtlas(options, computeVisco)
etaS = getEtaS(options);
tf = logical(computeVisco) && etaS > 0 && logical(getStructField(options, 'mrlfeUseUnifiedAtlasRoute', true));
end

function tf = shouldUseElasticAtlas(options, computeVisco)
etaS = getEtaS(options);
defaultUseElasticAtlas = ~logical(computeVisco) && etaS == 0;
tf = defaultUseElasticAtlas && logical(getStructField(options, 'mrlfeUseElasticAtlasGuiRoute', true));
end

function etaS = getEtaS(options)
etaS = 0;
if isfield(options, 'mrlfeParams') && isfield(options.mrlfeParams, 'etaS') && ~isempty(options.mrlfeParams.etaS)
    etaS = options.mrlfeParams.etaS;
end
end

function options = applyGuiAtlasPreset(options, routeMode)
if ~logical(getStructField(options, 'mrlfeUseGuiFastAtlasPreset', true))
    options.mrlfeGuiAtlasPreset = "off";
    return;
end
routeMode = string(routeMode);
switch routeMode
    case "viscous"
        options.mrlfeGuiAtlasPreset = "fast_viscous";
    case "elastic_atlas"
        options.mrlfeGuiAtlasPreset = "fast_elastic_atlas_guarded";
    otherwise
        options.mrlfeGuiAtlasPreset = "elastic_reference";
end

options.mrlfeElasticAtlasGuiMinValidFraction = getStructField(options, 'mrlfeElasticAtlasGuiMinValidFraction', 0.85);
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

function quality = summarizeMRLFEAtlasCpQuality(mrlfeResult)
quality = struct('validFraction', NaN, 'validCount', 0, 'totalCount', 0);
if ~isstruct(mrlfeResult) || ~isfield(mrlfeResult, 'branches') || ~isstruct(mrlfeResult.branches)
    return;
end
branchNames = fieldnames(mrlfeResult.branches);
for i = 1:numel(branchNames)
    branch = mrlfeResult.branches.(branchNames{i});
    if isfield(branch, 'Cp')
        cp = branch.Cp(:);
    elseif isfield(branch, 'phaseVelocity')
        cp = branch.phaseVelocity(:);
    else
        continue;
    end
    valid = isfinite(cp);
    if isfield(branch, 'validCp') && numel(branch.validCp) == numel(cp)
        valid = valid & logical(branch.validCp(:));
    elseif isfield(branch, 'valid') && numel(branch.valid) == numel(cp)
        valid = valid & logical(branch.valid(:));
    end
    quality.totalCount = numel(cp);
    quality.validCount = nnz(valid);
    if quality.totalCount > 0
        quality.validFraction = quality.validCount / quality.totalCount;
    end
    return;
end
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
