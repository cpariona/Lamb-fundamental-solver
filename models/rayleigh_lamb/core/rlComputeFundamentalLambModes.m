function results = rlComputeFundamentalLambModes(params, options)
% Compute fundamental A0/S0 branches using independent continuation solves.

rlValidateParams(params);
rlValidateOptions(options);

material = rlComputeMaterial(params);
geometry = rlComputeGeometry(params);
frequency = rlBuildFrequencyVector(params);
omega = 2 * pi * frequency;

solverOptions = buildSolverOptions(options, material);

results = struct();
results.material = material;
results.geometry = rmfield(geometry, 'halfThickness');
results.grid.frequency = frequency;
results.grid.omega = omega;
results.modes = struct();
results.approximations = rlComputeAnalyticalApproximations(frequency, material, results.geometry);
results.models = struct();

computeMRLFERealK = shouldComputeMRLFERealK(options);
computeComplexK = getOption(options, 'computeMRLFEComplexK', false);
needMRLFE = computeMRLFERealK || computeComplexK;

computeMRLFEA0Like = getOption(options, 'mrlfeComputeA0Like', true);
computeMRLFES0Like = getOption(options, 'mrlfeComputeS0Like', true);

computeA0 = options.computeA0 || (needMRLFE && computeMRLFEA0Like);
computeS0 = options.computeS0 || (needMRLFE && computeMRLFES0Like);

if computeA0
    geometryForSpec = geometry;
    geometryForSpec.frequency0 = frequency(1);
    branchSpecA = rlMakeBranchSpec("A0", material, geometryForSpec);
    solverOptionsA = applyBranchSpec(solverOptions, branchSpecA);

    residualFcnA = @(Cp, f) rlAResidual(Cp, f, material.CL, material.CT, geometry.halfThickness);
    [CpA0, residualA0] = rlSolveFundamentalBranch(frequency, residualFcnA, solverOptionsA);
    kA0 = omega ./ CpA0;

    results.modes.A0 = packModeResults("A0", branchSpecA.family, frequency, omega, CpA0, kA0, geometry.thickness, residualA0);
end

if computeS0
    branchSpecS = rlMakeBranchSpec("S0", material, geometry);
    solverOptionsS = applyBranchSpec(solverOptions, branchSpecS);

    residualFcnS = @(Cp, f) rlSResidual(Cp, f, material.CL, material.CT, geometry.halfThickness);
    [CpS0, residualS0] = rlSolveFundamentalBranch(frequency, residualFcnS, solverOptionsS);
    kS0 = omega ./ CpS0;

    results.modes.S0 = packModeResults("S0", branchSpecS.family, frequency, omega, CpS0, kS0, geometry.thickness, residualS0);
end

if computeMRLFERealK
    [realKResult, realKReference, isViscoelastic] = computeMRLFERealKModel(frequency, material, results.geometry, results.modes, options);
    results = registerMRLFERealKResults(results, realKResult, realKReference, isViscoelastic);
end

if computeComplexK
    mrlfeParams = buildMRLFEParamsFromOptions(options);
    mrlfeParams.solveComplexK = false;
    mrlfeParams.etaL = 0;
    mrlfeParams.useComplexLambda = false;
    realKSeed = computeElasticMRLFERealK(frequency, material, results.geometry, results.modes, options);
    mrlfeParams.solveComplexK = true;
    results.models.mRLFEComplexK = computeMRLFE(frequency, material, results.geometry, realKSeed.branches, mrlfeParams, options);
    if ~isfield(results.models, 'mRLFE')
        results.models.mRLFE = results.models.mRLFEComplexK;
    end
end
end

function tf = shouldComputeMRLFERealK(options)
tf = getOption(options, 'computeMRLFERealK', false) || ...
    getOption(options, 'computeMRLFEElasticRealK', false) || ...
    getOption(options, 'computeMRLFEViscoRealK', false) || ...
    getOption(options, 'computeMRLFE', false);
end

function [realKResult, elasticReference, isViscoelastic] = computeMRLFERealKModel(frequency, material, geometry, seedModes, options)
mrlfeParams = buildMRLFEParamsFromOptions(options);
mrlfeParams.solveComplexK = false;
mrlfeParams.etaL = 0;
mrlfeParams.useComplexLambda = false;
isViscoelastic = getOption(mrlfeParams, 'etaS', 0) > 0;

if ~isViscoelastic
    elasticReference = computeElasticMRLFERealK(frequency, material, geometry, seedModes, options);
    realKResult = elasticReference;
    return;
end

if shouldUseA0DelayedDirectViscoAtlas(options, mrlfeParams, seedModes)
    if getOption(options, 'mrlfeDirectViscoAtlasComputeElasticReference', false)
        elasticReference = computeElasticMRLFERealK(frequency, material, geometry, seedModes, options);
    else
        elasticReference = makeSkippedElasticReferenceResult(frequency, mrlfeParams, options);
    end
    realKResult = computeA0DelayedDirectViscoAtlasRealK(frequency, material, geometry, seedModes.A0, mrlfeParams, options);
    return;
end

elasticReference = getElasticReferenceResult(options, frequency, seedModes);
if isempty(elasticReference)
    elasticReference = computeElasticMRLFERealK(frequency, material, geometry, seedModes, options);
end

viscoOptions = makeViscoRealKOptions(options);
realKResult = computeMRLFE(frequency, material, geometry, elasticReference.branches, mrlfeParams, viscoOptions);
end

function tf = shouldUseA0DelayedDirectViscoAtlas(options, mrlfeParams, seedModes)
policy = string(getOption(options, 'mrlfeDirectViscoAtlasPolicy', "maintained"));
tf = policy == "A0DelayedCut" && ...
    getOption(mrlfeParams, 'etaS', 0) > 0 && ...
    ~getOption(mrlfeParams, 'solveComplexK', false) && ...
    getOption(options, 'mrlfeComputeA0Like', true) && ...
    ~getOption(options, 'mrlfeComputeS0Like', true) && ...
    isfield(seedModes, 'A0');
end

function realKResult = computeA0DelayedDirectViscoAtlasRealK(frequency, material, geometry, seedA0, mrlfeParams, options)
timerStart = tic;
policyOptions = mrlfeMakeDirectViscoAtlasBranchOptions(options, "A0Like", options);
policyOptions.mrlfeRealKStopAtFirstMissingModalMinimum = false;
branch = solveMRLFEViscoBranchAtlas("A0Like", seedA0, material, geometry, mrlfeParams, policyOptions);
[branch, delayedCutSummary] = mrlfeApplyDelayedViscoModalCut(branch, policyOptions);
branch.experimentalPolicy = "A0DelayedCut";
branch.delayedViscoModalCut = delayedCutSummary;

realKResult = struct();
realKResult.modelName = "mRLFE";
realKResult.variant = "real-k";
realKResult.description = "Experimental A0Like direct viscous real-k atlas with delayed modal cut.";
realKResult.parameters = mrlfeParams;
realKResult.requestedBranches = struct('A0Like', true, 'S0Like', false);
realKResult.frequency = frequency(:);
realKResult.tracking = struct();
realKResult.tracking.usedInternalGrid = false;
realKResult.tracking.requestedFrequency = frequency(:);
realKResult.tracking.trackingFrequency = frequency(:);
realKResult.branches = struct();
realKResult.branches.A0Like = branch;
realKResult.experimental = struct();
realKResult.experimental.directViscoAtlasPolicy = "A0DelayedCut";
realKResult.experimental.S0LikeExcluded = true;
realKResult.experimental.elasticReferenceSkipped = ~getOption(options, 'mrlfeDirectViscoAtlasComputeElasticReference', false);
realKResult.diagnostics = buildDirectAtlasDiagnostics(realKResult, toc(timerStart));
end

function elasticReference = makeSkippedElasticReferenceResult(frequency, mrlfeParams, options)
elasticParams = mrlfeParams;
elasticParams.etaS = 0;
elasticReference = struct();
elasticReference.modelName = "mRLFE";
elasticReference.variant = "real-k-elastic-reference-skipped";
elasticReference.description = "Elastic mRLFE reference skipped by experimental A0DelayedCut direct-visco atlas policy.";
elasticReference.parameters = elasticParams;
elasticReference.requestedBranches = struct('A0Like', false, 'S0Like', false);
elasticReference.frequency = frequency(:);
elasticReference.tracking = struct('usedInternalGrid', false, 'requestedFrequency', frequency(:), 'trackingFrequency', frequency(:));
elasticReference.branches = struct();
elasticReference.experimental = struct('directViscoAtlasPolicy', string(getOption(options, 'mrlfeDirectViscoAtlasPolicy', "maintained")));
elasticReference.diagnostics = struct('elapsedSeconds', 0, 'variant', elasticReference.variant, 'branchNames', strings(0, 1), 'summary', struct());
end

function diagnostics = buildDirectAtlasDiagnostics(mrlfeResults, elapsedSeconds)
diagnostics = struct();
diagnostics.elapsedSeconds = elapsedSeconds;
diagnostics.variant = mrlfeResults.variant;
diagnostics.branchNames = string(fieldnames(mrlfeResults.branches));
diagnostics.usedInternalTrackingGrid = false;
diagnostics.requestedPointCount = numel(mrlfeResults.frequency);
diagnostics.trackingPointCount = numel(mrlfeResults.frequency);
diagnostics.summary = struct();
branchNames = fieldnames(mrlfeResults.branches);
for i = 1:numel(branchNames)
    name = branchNames{i};
    branch = mrlfeResults.branches.(name);
    validCp = getBranchValidCp(branch);
    finiteResidual = false(size(branch.Cp(:)));
    if isfield(branch, 'residual')
        finiteResidual = isfinite(branch.residual(:));
    end
    item = struct();
    item.validPoints = nnz(validCp);
    item.validCpPoints = nnz(validCp);
    item.totalPoints = numel(branch.Cp);
    item.maxCpJumpRelative = maxRelativeJump(branch.Cp(validCp));
    if any(finiteResidual)
        residual = branch.residual(:);
        item.maxResidual = max(residual(finiteResidual));
        item.meanResidual = mean(residual(finiteResidual));
    else
        item.maxResidual = nan;
        item.meanResidual = nan;
    end
    if any(validCp)
        item.minCp = min(branch.Cp(validCp));
        item.maxCp = max(branch.Cp(validCp));
    else
        item.minCp = nan;
        item.maxCp = nan;
    end
    diagnostics.summary.(name) = item;
end
end

function validCp = getBranchValidCp(branch)
validCp = isfinite(branch.Cp(:)) & branch.Cp(:) > 0;
if isfield(branch, 'validCp')
    validCp = validCp & logical(branch.validCp(:));
elseif isfield(branch, 'valid')
    validCp = validCp & logical(branch.valid(:));
end
end

function results = registerMRLFERealKResults(results, realKResult, elasticReference, isViscoelastic)
results.models.mRLFEElasticRealK = elasticReference;
if isViscoelastic
    results.models.mRLFEViscoRealK = realKResult;
end
results.models.mRLFERealK = realKResult;
results.models.mRLFE = realKResult;
end

function result = computeElasticMRLFERealK(frequency, material, geometry, seedModes, options)
mrlfeParams = buildMRLFEParamsFromOptions(options);
mrlfeParams.solveComplexK = false;
mrlfeParams.etaS = 0;
mrlfeParams.etaL = 0;
mrlfeParams.useComplexLambda = false;
elasticOptions = makeElasticRealKOptions(options);
result = computeMRLFE(frequency, material, geometry, seedModes, mrlfeParams, elasticOptions);
end

function elasticReference = getElasticReferenceResult(options, frequency, seedModes)
elasticReference = [];
if ~isfield(options, 'mrlfeElasticReferenceResult') || isempty(options.mrlfeElasticReferenceResult)
    return;
end
candidate = options.mrlfeElasticReferenceResult;
if ~isstruct(candidate) || ~isfield(candidate, 'branches') || ~isstruct(candidate.branches)
    return;
end
if ~referenceHasRequiredBranches(candidate, seedModes)
    return;
end
if ~referenceFrequencyMatches(candidate, frequency)
    return;
end
elasticReference = candidate;
end

function tf = referenceHasRequiredBranches(referenceResult, seedModes)
tf = true;
if isfield(seedModes, 'A0') && ~isfield(referenceResult.branches, 'A0Like')
    tf = false;
end
if isfield(seedModes, 'S0') && ~isfield(referenceResult.branches, 'S0Like')
    tf = false;
end
end

function tf = referenceFrequencyMatches(referenceResult, frequency)
tf = true;
branchNames = string(fieldnames(referenceResult.branches));
if isempty(branchNames)
    tf = false;
    return;
end
for i = 1:numel(branchNames)
    branch = referenceResult.branches.(char(branchNames(i)));
    if isfield(branch, 'frequency') && numel(branch.frequency) == numel(frequency)
        if max(abs(branch.frequency(:) - frequency(:))) > 10 * eps(max(1, max(abs(frequency(:)))))
            tf = false;
            return;
        end
    end
end
end

function mrlfeParams = buildMRLFEParamsFromOptions(options)
mrlfeParams = defaultMRLFEParams();
if isfield(options, 'mrlfeParams')
    userParams = options.mrlfeParams;
    names = fieldnames(userParams);
    for i = 1:numel(names)
        mrlfeParams.(names{i}) = userParams.(names{i});
    end
end
end

function elasticOptions = makeElasticRealKOptions(options)
elasticOptions = options;
elasticOptions.mrlfeUseInternalTrackingGrid = getOption(options, 'mrlfeUseInternalTrackingGrid', false);
elasticOptions.mrlfeA0UseDPTracker = true;
elasticOptions.mrlfeRealKAnchorToSeed = true;
elasticOptions.mrlfeRealKHardReferenceWindow = true;
elasticOptions.mrlfeRealKScoreMode = "modal";
elasticOptions.mrlfeRealKRequireLocalMinimum = true;
elasticOptions.mrlfeRealKReferenceWeight = 80.0;
elasticOptions.mrlfeRealKPredictionWeight = 4.0;
elasticOptions.mrlfeRealKMaxRelativeKDrift = 0.30;
elasticOptions.mrlfeRealKValidationMaxRelativeKDrift = 0.35;
elasticOptions.mrlfeRealKValidationMaxRelativeCpDrift = 0.35;
elasticOptions.mrlfeResidualTolerance = max(getOption(options, 'mrlfeResidualTolerance', 1e-4), 1e-3);
end

function viscoOptions = makeViscoRealKOptions(options)
viscoOptions = options;
useInternalGrid = getOption(options, 'mrlfeUseInternalTrackingGrid', false) || ...
    getOption(options, 'mrlfeUseInternalTrackingGridForViscousRealK', true);
viscoOptions.mrlfeUseInternalTrackingGrid = useInternalGrid;
viscoOptions.mrlfeA0UseDPTracker = false;
viscoOptions.mrlfeRealKAnchorToSeed = true;
viscoOptions.mrlfeRealKHardReferenceWindow = false;
viscoOptions.mrlfeRealKScoreMode = "modal";
viscoOptions.mrlfeRealKRequireLocalMinimum = true;
viscoOptions.mrlfeRealKUseModalCpWindow = getOption(options, 'mrlfeViscoUseModalLocalTracker', true);
viscoOptions.mrlfeRealKStopAtFirstMissingModalMinimum = getOption(options, 'mrlfeRealKStopAtFirstMissingModalMinimum', true);
viscoOptions.mrlfeRealKReferenceWeight = 120.0;
viscoOptions.mrlfeRealKPredictionWeight = 6.0;
viscoOptions.mrlfeRealKPreviousCpWeight = getOption(options, 'mrlfeViscoPreviousCpWeight', 80.0);
viscoOptions.mrlfeRealKPreviousKWeight = getOption(options, 'mrlfeViscoPreviousKWeight', 0.0);
viscoOptions.mrlfeRealKPreviousCpMaxRelativeJump = getOption(options, 'mrlfeViscoPreviousCpMaxRelativeJump', inf);
viscoOptions.mrlfeRealKMaxRelativeKDrift = inf;
viscoOptions.mrlfeRealKValidationMaxRelativeKDrift = inf;
viscoOptions.mrlfeRealKValidationMaxRelativeCpDrift = inf;
viscoOptions.mrlfeResidualTolerance = max(getOption(options, 'mrlfeResidualTolerance', 1e-4), 1e-3);
end

function solverOptions = buildSolverOptions(options, material)
solverOptions = struct();
solverOptions.CT = material.CT;
solverOptions.gridPointsInitial = options.gridPointsInitial;
solverOptions.gridPointsTracking = options.gridPointsTracking;
solverOptions.jumpTol = options.jumpTol;
solverOptions.residualTolerance = options.residualTolerance;

optionalFields = {'searchFactors', 'minCpAbsolute', 'minCpRelativeToCT', ...
    'maxCpFactorCT', 'minCpGlobalMax', 'initialGuessWeight', 'predictionWeight', ...
    'maxPredictionRelativeError', 'maxSinglePointSpikeRelative', 'preferPreviousRootWeight'};
for i = 1:numel(optionalFields)
    fieldName = optionalFields{i};
    if isfield(options, fieldName)
        solverOptions.(fieldName) = options.(fieldName);
    end
end
end

function solverOptions = applyBranchSpec(solverOptions, branchSpec)
solverOptions.branchName = branchSpec.name;
solverOptions.initialCpGuess = branchSpec.initialCpGuess;
solverOptions.initialSearchRange = branchSpec.initialSearchRange;
solverOptions.preferLowestCp = branchSpec.preferLowestCp;
end

function mode = packModeResults(name, family, frequency, omega, Cp, k, thickness, residual)
mode = struct( ...
    'name', name, ...
    'family', family, ...
    'frequency', frequency, ...
    'omega', omega, ...
    'Cp', Cp, ...
    'k', k, ...
    'kThickness', k * thickness, ...
    'residual', residual, ...
    'valid', isfinite(Cp));
end

function value = maxRelativeJump(x)
if numel(x) < 2
    value = 0;
else
    value = max(abs(diff(x)) ./ max(abs(x(1:end-1)), eps));
end
end

function value = getOption(options, fieldName, defaultValue)
if isstruct(options) && isfield(options, fieldName) && ~isempty(options.(fieldName))
    value = options.(fieldName);
else
    value = defaultValue;
end
end
