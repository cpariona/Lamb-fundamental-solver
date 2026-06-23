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

computeMRLFERealK = getOption(options, 'computeMRLFERealK', false) || ...
    getOption(options, 'computeMRLFEElasticRealK', false) || ...
    getOption(options, 'computeMRLFEViscoRealK', false) || ...
    getOption(options, 'computeMRLFEHanViscoRealK', false) || ...
    getOption(options, 'computeMRLFE', false);
computeComplexK = getOption(options, 'computeMRLFEComplexK', false);
needMRLFE = computeMRLFERealK || computeComplexK;

computeMRLFEA0Like = getOption(options, 'mrlfeComputeA0Like', true);
computeMRLFES0Like = getOption(options, 'mrlfeComputeS0Like', true);

% mRLFE branches are dependent on Rayleigh-Lamb seed branches. Force the seed
% branches required by the selected A0-like/S0-like branches even when the RL
% checkboxes are not selected explicitly in the GUI.
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
    mrlfeParams = buildMRLFEParamsFromOptions(options);
    mrlfeParams.solveComplexK = false;
    mrlfeParams.etaL = 0;
    mrlfeParams.useComplexLambda = false;

    if getOption(mrlfeParams, 'etaS', 0) <= 0
        elasticResult = computeElasticMRLFERealK(frequency, material, results.geometry, results.modes, options);
        realKResult = elasticResult;
        results.models.mRLFEElasticRealK = elasticResult;
    else
        elasticReference = getElasticReferenceResult(options, frequency, results.modes);
        if isempty(elasticReference)
            elasticReference = computeElasticMRLFERealK(frequency, material, results.geometry, results.modes, options);
            results.models.mRLFEElasticRealK = elasticReference;
        else
            results.models.mRLFEElasticRealK = elasticReference;
        end

        viscoOptions = makeViscoRealKOptions(options);
        realKResult = computeMRLFE(frequency, material, results.geometry, elasticReference.branches, mrlfeParams, viscoOptions);
        results.models.mRLFEViscoRealK = realKResult;
        results.models.mRLFEHanViscoRealK = realKResult; % legacy alias
    end

    results.models.mRLFERealK = realKResult;
    results.models.mRLFE = realKResult;
end

% Complex-k remains an experimental attenuation path. It is hidden from the
% main GUI, but kept available for advanced scripts.
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
% Elastic fluid-loaded mRLFE is seeded from Rayleigh-Lamb A0/S0. Modal scoring
% prevents low-stiffness branches from switching to another residual valley.
elasticOptions = options;
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
% Viscous real-k is seeded from the etaS = 0 real-k result. It uses a
% conservative modal-local tracker because viscosity can introduce competing
% residual valleys and low-Cp edge minima.
viscoOptions = options;
viscoOptions.mrlfeA0UseDPTracker = false;
viscoOptions.mrlfeRealKAnchorToSeed = true;
viscoOptions.mrlfeRealKHardReferenceWindow = false;
viscoOptions.mrlfeRealKScoreMode = "modal";
viscoOptions.mrlfeRealKRequireLocalMinimum = true;
viscoOptions.mrlfeRealKUseModalCpWindow = getOption(options, 'mrlfeViscoUseModalLocalTracker', getOption(options, 'mrlfeHanUseModalLocalTracker', true));
viscoOptions.mrlfeRealKStopAtFirstMissingModalMinimum = getOption(options, 'mrlfeRealKStopAtFirstMissingModalMinimum', true);
viscoOptions.mrlfeRealKReferenceWeight = 120.0;
viscoOptions.mrlfeRealKPredictionWeight = 6.0;
viscoOptions.mrlfeRealKPreviousCpWeight = getOption(options, 'mrlfeViscoPreviousCpWeight', getOption(options, 'mrlfeHanPreviousCpWeight', 80.0));
viscoOptions.mrlfeRealKPreviousKWeight = getOption(options, 'mrlfeViscoPreviousKWeight', getOption(options, 'mrlfeHanPreviousKWeight', 0.0));
viscoOptions.mrlfeRealKPreviousCpMaxRelativeJump = getOption(options, 'mrlfeViscoPreviousCpMaxRelativeJump', getOption(options, 'mrlfeHanPreviousCpMaxRelativeJump', inf));
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

function value = getOption(options, fieldName, defaultValue)
if isstruct(options) && isfield(options, fieldName) && ~isempty(options.(fieldName))
    value = options.(fieldName);
else
    value = defaultValue;
end
end
