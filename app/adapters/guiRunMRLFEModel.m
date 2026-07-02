function result = guiRunMRLFEModel(guiRequest)
if nargin < 1 || isempty(guiRequest)
    guiRequest = struct();
end

params = guiMergeStructs(rlDefaultParams(), guiGetStructField(guiRequest, 'params', struct()));
options = guiMergeStructs(rlDefaultOptions(), guiGetStructField(guiRequest, 'options', struct()));
computeVisco = logical(guiGetStructField(guiRequest, 'computeVisco', false));
computeA0Like = guiGetStructField(options, 'mrlfeComputeA0Like', true);
computeS0Like = guiGetStructField(options, 'mrlfeComputeS0Like', true);

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
options.mrlfeUseUnifiedAtlasRoute = logical(guiGetStructField(options, 'mrlfeUseUnifiedAtlasRoute', computeVisco));
options.mrlfeA0Policy = string(guiGetStructField(options, 'mrlfeA0Policy', "adaptivePhysicalTail"));
options.mrlfeComputeA0Like = logical(computeA0Like);
options.mrlfeComputeS0Like = logical(computeS0Like);

seedOptions = options;
seedOptions.computeA0 = logical(guiGetStructField(options, 'computeA0', true) || computeA0Like);
seedOptions.computeS0 = logical(guiGetStructField(options, 'computeS0', false) || computeS0Like);
seedOptions.computeMRLFE = false;
seedOptions.computeMRLFEElasticRealK = false;
seedOptions.computeMRLFEViscoRealK = false;
seedOptions.computeMRLFERealK = false;
seedOptions.computeMRLFEComplexK = false;

elapsedTimer = tic;
rawResult = rlComputeFundamentalLambModes(params, seedOptions);
useViscousAtlas = shouldUseUnifiedAtlas(options, computeVisco);
useZeroViscosityAdaptive = shouldUseZeroViscosityAdaptive(options, computeVisco);
zeroViscosityFallback = false;
zeroViscosityQuality = struct('validFraction', NaN, 'validCount', 0, 'totalCount', 0, 'maxJumpRelative', NaN);
actualRoute = "elastic_reference";

if useViscousAtlas
    options = applyGuiAtlasPreset(options, "viscous");
    mrlfeResult = solveMRLFEAtlasUnified(rawResult.grid.frequency(:), rawResult.material, rawResult.geometry, rawResult.modes, options.mrlfeParams, options);
    actualRoute = "viscous_unified_atlas";
elseif useZeroViscosityAdaptive
    options = applyGuiAtlasPreset(options, "zero_viscosity_adaptive");
    candidate = solveZeroViscosityAdaptiveResult(rawResult, options);
    zeroViscosityQuality = summarizeMRLFEAtlasCpQuality(candidate);
    minValidFraction = guiGetStructField(options, 'mrlfeZeroViscosityAdaptiveGuiMinValidFraction', 0.85);
    maxJumpRelative = guiGetStructField(options, 'mrlfeZeroViscosityAdaptiveGuiMaxJumpRelative', 0.25);
    if zeroViscosityQuality.validFraction >= minValidFraction && zeroViscosityQuality.maxJumpRelative <= maxJumpRelative
        mrlfeResult = candidate;
        actualRoute = "zero_viscosity_adaptive_atlas";
    else
        zeroViscosityFallback = true;
        mrlfeResult = computeElasticReference(rawResult, options);
        actualRoute = "zero_viscosity_adaptive_fallback";
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
result.diagnostics.mrlfeUseUnifiedAtlasRoute = useViscousAtlas;
result.diagnostics.mrlfeUseZeroViscosityAdaptiveGuiRoute = useZeroViscosityAdaptive;
result.diagnostics.mrlfeZeroViscosityAdaptiveFallback = zeroViscosityFallback;
result.diagnostics.mrlfeZeroViscosityAdaptiveQuality = zeroViscosityQuality;
result.diagnostics.mrlfeGuiActualRoute = actualRoute;
result.diagnostics.mrlfeA0Policy = options.mrlfeA0Policy;
result.diagnostics.mrlfeGuiAtlasPreset = guiGetStructField(options, 'mrlfeGuiAtlasPreset', "none");
result.metadata.params = params;
result.metadata.options = options;
result.metadata.elapsedSeconds = elapsedSeconds;
result.metadata.seedBranchesHiddenFromPlotSurface = true;
result.metadata.mrlfeUseUnifiedAtlasRoute = useViscousAtlas;
result.metadata.mrlfeUseZeroViscosityAdaptiveGuiRoute = useZeroViscosityAdaptive;
result.metadata.mrlfeZeroViscosityAdaptiveFallback = zeroViscosityFallback;
result.metadata.mrlfeZeroViscosityAdaptiveQuality = zeroViscosityQuality;
result.metadata.mrlfeGuiActualRoute = actualRoute;
result.metadata.mrlfeA0Policy = options.mrlfeA0Policy;
result.metadata.mrlfeGuiAtlasPreset = guiGetStructField(options, 'mrlfeGuiAtlasPreset', "none");
end

function mrlfeResult = computeElasticReference(rawResult, options)
elasticParams = options.mrlfeParams;
elasticParams.etaS = 0;
mrlfeResult = computeMRLFE(rawResult.grid.frequency(:), rawResult.material, rawResult.geometry, rawResult.modes, elasticParams, options);
end

function mrlfeResult = solveZeroViscosityAdaptiveResult(rawResult, options)
frequency = rawResult.grid.frequency(:);
material = rawResult.material;
geometry = rawResult.geometry;
zeroParams = options.mrlfeParams;
zeroParams.etaS = 0;
zeroParams.solveComplexK = false;
zeroParams.etaL = 0;
zeroParams.useComplexLambda = false;

mrlfeResult = struct();
mrlfeResult.modelName = "mRLFE";
mrlfeResult.variant = "zero-viscosity-adaptive-real-k";
mrlfeResult.description = "Zero-viscosity adaptive mRLFE real-k GUI route.";
mrlfeResult.parameters = zeroParams;
mrlfeResult.frequency = frequency;
mrlfeResult.branches = struct();
mrlfeResult.atlasUnified = struct('isViscous', false, 'useZeroViscosityAdaptiveAtlas', true, 'seedStrategy', "RayleighLambOrPhysicalSynthetic");

if guiGetStructField(options, 'mrlfeComputeA0Like', true)
    seedA0 = mrlfeMakePhysicalSeedMode("A0Like", frequency, material, geometry, rawResult.modes);
    branch = solveMRLFEBranchAdaptiveAtlas("A0Like", seedA0, material, geometry, zeroParams, options);
    branch.atlasUnifiedPolicy = "zeroViscosityA0AdaptivePhysicalTailCut";
    branch.solverRoute = "zeroViscosityAdaptiveAtlas";
    branch.seedMode = seedA0;
    if guiGetStructField(options, 'mrlfeUseA0PhysicalTailCut', true)
        corridorOptions = makeA0PhysicalTailCutOptions(options);
        branch = mrlfeApplyPhysicalCorridorCut(branch, seedA0.Cp, seedA0.frequency, corridorOptions);
    end
    mrlfeResult.branches.A0Like = branch;
end

if guiGetStructField(options, 'mrlfeComputeS0Like', false)
    seedS0 = mrlfeMakePhysicalSeedMode("S0Like", frequency, material, geometry, rawResult.modes);
    branch = solveMRLFEBranchAdaptiveAtlas("S0Like", seedS0, material, geometry, zeroParams, options);
    branch.atlasUnifiedPolicy = "zeroViscosityS0AdaptiveContinuation";
    branch.solverRoute = "zeroViscosityAdaptiveAtlas";
    branch.seedMode = seedS0;
    mrlfeResult.branches.S0Like = branch;
end

mrlfeResult.diagnostics = struct('variant', mrlfeResult.variant, 'branchNames', string(fieldnames(mrlfeResult.branches)));
end

function corridorOptions = makeA0PhysicalTailCutOptions(options)
corridorOptions = struct();
corridorOptions.minRatioToGuide = guiGetStructField(options, 'mrlfeA0PhysicalMinRatioToGuide', 0.70);
corridorOptions.maxRatioToGuide = guiGetStructField(options, 'mrlfeA0PhysicalMaxRatioToGuide', inf);
corridorOptions.minFrequencyHz = guiGetStructField(options, 'mrlfeA0PhysicalMinFrequencyHz', 1000);
corridorOptions.minValidRunBeforeCut = guiGetStructField(options, 'mrlfeA0PhysicalMinValidRunBeforeCut', 8);
corridorOptions.maxLocalDropRelative = guiGetStructField(options, 'mrlfeA0PhysicalMaxLocalDropRelative', 0.05);
corridorOptions.maxTwoStepDropRelative = guiGetStructField(options, 'mrlfeA0PhysicalMaxTwoStepDropRelative', 0.10);
end

function tf = shouldUseUnifiedAtlas(options, computeVisco)
etaS = getEtaS(options);
tf = logical(computeVisco) && etaS > 0 && logical(guiGetStructField(options, 'mrlfeUseUnifiedAtlasRoute', true));
end

function tf = shouldUseZeroViscosityAdaptive(options, computeVisco)
etaS = getEtaS(options);
defaultUse = ~logical(computeVisco) && etaS == 0;
tf = defaultUse && logical(guiGetStructField(options, 'mrlfeUseZeroViscosityAdaptiveGuiRoute', true));
end

function etaS = getEtaS(options)
etaS = 0;
if isfield(options, 'mrlfeParams') && isfield(options.mrlfeParams, 'etaS') && ~isempty(options.mrlfeParams.etaS)
    etaS = options.mrlfeParams.etaS;
end
end

function options = applyGuiAtlasPreset(options, routeMode)
if ~logical(guiGetStructField(options, 'mrlfeUseGuiFastAtlasPreset', true))
    options.mrlfeGuiAtlasPreset = "off";
    return;
end
routeMode = string(routeMode);
switch routeMode
    case "viscous"
        options.mrlfeGuiAtlasPreset = "fast_viscous";
    case "zero_viscosity_adaptive"
        options.mrlfeGuiAtlasPreset = "fast_zero_viscosity_adaptive";
    otherwise
        options.mrlfeGuiAtlasPreset = "elastic_reference";
end

options.mrlfeZeroViscosityAdaptiveGuiMinValidFraction = guiGetStructField(options, 'mrlfeZeroViscosityAdaptiveGuiMinValidFraction', 0.85);
options.mrlfeZeroViscosityAdaptiveGuiMaxJumpRelative = guiGetStructField(options, 'mrlfeZeroViscosityAdaptiveGuiMaxJumpRelative', 0.25);
options.mrlfeUseA0PhysicalTailCut = guiGetStructField(options, 'mrlfeUseA0PhysicalTailCut', true);
options.mrlfeViscoAtlasCpScanPoints = guiGetStructField(options, 'mrlfeViscoAtlasCpScanPoints', 260);
options.mrlfeA0DPCpScanPoints = guiGetStructField(options, 'mrlfeA0DPCpScanPoints', 260);
options.mrlfeA0DPCandidates = guiGetStructField(options, 'mrlfeA0DPCandidates', 5);
options.mrlfeA0DPRefineCandidates = guiGetStructField(options, 'mrlfeA0DPRefineCandidates', false);
options.mrlfeAdaptiveCpScanPoints = guiGetStructField(options, 'mrlfeAdaptiveCpScanPoints', 260);
options.mrlfeAdaptiveRefineCandidates = guiGetStructField(options, 'mrlfeAdaptiveRefineCandidates', false);
options.mrlfeAdaptiveWindows = guiGetStructField(options, 'mrlfeAdaptiveWindows', [0.20 0.40 0.80]);
options.mrlfeAdaptiveValleyFallbackRelativeWindow = guiGetStructField(options, 'mrlfeAdaptiveValleyFallbackRelativeWindow', 0.12);
options.mrlfeAdaptiveResidualWeight = guiGetStructField(options, 'mrlfeAdaptiveResidualWeight', 0.45);
options.mrlfeAdaptivePredictionWeight = guiGetStructField(options, 'mrlfeAdaptivePredictionWeight', 45.0);
options.mrlfeAdaptiveValleyFallbackResidualWeight = guiGetStructField(options, 'mrlfeAdaptiveValleyFallbackResidualWeight', 0.30);
options.mrlfeAdaptiveValleyFallbackPredictionWeight = guiGetStructField(options, 'mrlfeAdaptiveValleyFallbackPredictionWeight', 65.0);
end

function quality = summarizeMRLFEAtlasCpQuality(mrlfeResult)
quality = struct('validFraction', NaN, 'validCount', 0, 'totalCount', 0, 'maxJumpRelative', NaN);
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
    valid = isfinite(cp) & cp > 0;
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
    quality.maxJumpRelative = maxRelativeJump(cp(valid));
    return;
end
end

function y = maxRelativeJump(x)
x = x(:);
x = x(isfinite(x) & x > 0);
if numel(x) < 2
    y = 0;
else
    y = max(abs(diff(x)) ./ max(abs(x(1:end-1)), eps));
end
end

function branches = filterMRLFEBranches(branches)
if isempty(branches)
    return;
end
modelNames = string({branches.modelName});
branches = branches(modelNames == "mRLFERealK");
end
