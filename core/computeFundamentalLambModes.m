function results = computeFundamentalLambModes(params, options)
% Compute fundamental A0/S0 branches using independent continuation solves.

validateParams(params);
validateOptions(options);

material = computeMaterial(params);
geometry = computeGeometry(params);
frequency = buildFrequencyVector(params);
omega = 2 * pi * frequency;

solverOptions = buildSolverOptions(options, material);

results = struct();
results.material = material;
results.geometry = rmfield(geometry, 'halfThickness');
results.grid.frequency = frequency;
results.grid.omega = omega;
results.modes = struct();
results.approximations = computeAnalyticalApproximations(frequency, material, results.geometry);
results.models = struct();

if options.computeA0
    geometryForSpec = geometry;
    geometryForSpec.frequency0 = frequency(1);
    branchSpecA = makeBranchSpec("A0", material, geometryForSpec);
    solverOptionsA = applyBranchSpec(solverOptions, branchSpecA);

    residualFcnA = @(Cp, f) rayleighLambAResidual(Cp, f, material.CL, material.CT, geometry.halfThickness);
    [CpA0, residualA0] = solveFundamentalBranch(frequency, residualFcnA, solverOptionsA);
    kA0 = omega ./ CpA0;

    results.modes.A0 = packModeResults("A0", branchSpecA.family, frequency, omega, CpA0, kA0, geometry.thickness, residualA0);
end

if options.computeS0
    branchSpecS = makeBranchSpec("S0", material, geometry);
    solverOptionsS = applyBranchSpec(solverOptions, branchSpecS);

    residualFcnS = @(Cp, f) rayleighLambSResidual(Cp, f, material.CL, material.CT, geometry.halfThickness);
    [CpS0, residualS0] = solveFundamentalBranch(frequency, residualFcnS, solverOptionsS);
    kS0 = omega ./ CpS0;

    results.modes.S0 = packModeResults("S0", branchSpecS.family, frequency, omega, CpS0, kS0, geometry.thickness, residualS0);
end

computeElasticRealK = isfield(options, 'computeMRLFERealK') && options.computeMRLFERealK;
computeHanViscoRealK = isfield(options, 'computeMRLFEHanViscoRealK') && options.computeMRLFEHanViscoRealK;
computeComplexK = isfield(options, 'computeMRLFEComplexK') && options.computeMRLFEComplexK;
if isfield(options, 'computeMRLFE') && options.computeMRLFE
    computeElasticRealK = true;
end

elasticResult = [];
if computeElasticRealK || computeHanViscoRealK
    mrlfeParams = buildMRLFEParamsFromOptions(options);
    mrlfeParams.solveComplexK = false;
    mrlfeParams.etaS = 0;
    mrlfeParams.etaL = 0;
    mrlfeParams.useComplexLambda = false;

    elasticOptions = makeElasticRealKOptions(options);
    elasticResult = computeMRLFE(frequency, material, results.geometry, results.modes, mrlfeParams, elasticOptions);
    if computeElasticRealK
        results.models.mRLFEElasticRealK = elasticResult;
        results.models.mRLFERealK = results.models.mRLFEElasticRealK;
    end
end

if computeHanViscoRealK
    mrlfeParams = buildMRLFEParamsFromOptions(options);
    mrlfeParams.solveComplexK = false;
    mrlfeParams.etaL = 0;
    mrlfeParams.useComplexLambda = false;

    hanOptions = makeHanRealKOptions(options);
    results.models.mRLFEHanViscoRealK = computeMRLFE(frequency, material, results.geometry, elasticResult.branches, mrlfeParams, hanOptions);
end

% Complex-k remains an experimental attenuation path. It is hidden from the
% main GUI, but kept available for advanced scripts.
realKNeededForComplexSeed = computeComplexK;
if realKNeededForComplexSeed
    mrlfeParams = buildMRLFEParamsFromOptions(options);
    mrlfeParams.solveComplexK = false;
    mrlfeParams.etaL = 0;
    mrlfeParams.useComplexLambda = false;
    realKResult = computeMRLFE(frequency, material, results.geometry, results.modes, mrlfeParams, makeElasticRealKOptions(options));
    mrlfeParams.solveComplexK = true;
    results.models.mRLFEComplexK = computeMRLFE(frequency, material, results.geometry, realKResult.branches, mrlfeParams, options);
end

% Backward-compatible alias for scripts expecting results.models.mRLFE.
if isfield(results.models, 'mRLFEElasticRealK')
    results.models.mRLFE = results.models.mRLFEElasticRealK;
elseif isfield(results.models, 'mRLFEHanViscoRealK')
    results.models.mRLFE = results.models.mRLFEHanViscoRealK;
elseif isfield(results.models, 'mRLFEComplexK')
    results.models.mRLFE = results.models.mRLFEComplexK;
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
% Elastic fluid-loaded mRLFE is seeded from Rayleigh-Lamb A0/S0.  Modal
% scoring prevents low-stiffness branches from switching to another residual
% valley merely because it has a smaller singular-value residual. A0-like is
% additionally tracked with a multicandidate DP path selector.
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

function hanOptions = makeHanRealKOptions(options)
% Han viscoelastic real-k is seeded from the elastic real-k result. It uses a
% stricter modal score because viscosity can introduce strong competing
% residual valleys at high frequency.
hanOptions = options;
hanOptions.mrlfeA0UseDPTracker = false;
hanOptions.mrlfeRealKAnchorToSeed = true;
hanOptions.mrlfeRealKHardReferenceWindow = true;
hanOptions.mrlfeRealKScoreMode = "modal";
hanOptions.mrlfeRealKRequireLocalMinimum = true;
hanOptions.mrlfeRealKReferenceWeight = 120.0;
hanOptions.mrlfeRealKPredictionWeight = 6.0;
hanOptions.mrlfeRealKMaxRelativeKDrift = 0.22;
hanOptions.mrlfeRealKValidationMaxRelativeKDrift = 0.30;
hanOptions.mrlfeRealKValidationMaxRelativeCpDrift = 0.30;
hanOptions.mrlfeResidualTolerance = max(getOption(options, 'mrlfeResidualTolerance', 1e-4), 1e-3);
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
if isfield(options, fieldName)
    value = options.(fieldName);
else
    value = defaultValue;
end
end
