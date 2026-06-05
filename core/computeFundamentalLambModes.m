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

if computeElasticRealK
    mrlfeParams = buildMRLFEParamsFromOptions(options);
    mrlfeParams.solveComplexK = false;
    mrlfeParams.etaS = 0;
    mrlfeParams.etaL = 0;
    mrlfeParams.useComplexLambda = false;
    results.models.mRLFEElasticRealK = computeMRLFE(frequency, material, results.geometry, results.modes, mrlfeParams, options);
    results.models.mRLFERealK = results.models.mRLFEElasticRealK;
end

if computeHanViscoRealK
    mrlfeParams = buildMRLFEParamsFromOptions(options);
    mrlfeParams.solveComplexK = false;
    mrlfeParams.etaL = 0;
    mrlfeParams.useComplexLambda = false;
    results.models.mRLFEHanViscoRealK = computeMRLFE(frequency, material, results.geometry, results.modes, mrlfeParams, options);
end

% Complex-k remains an experimental attenuation path. It is hidden from the
% main GUI, but kept available for advanced scripts.
realKNeededForComplexSeed = computeComplexK;
if realKNeededForComplexSeed
    mrlfeParams = buildMRLFEParamsFromOptions(options);
    mrlfeParams.solveComplexK = false;
    mrlfeParams.etaL = 0;
    mrlfeParams.useComplexLambda = false;
    realKResult = computeMRLFE(frequency, material, results.geometry, results.modes, mrlfeParams, options);
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
