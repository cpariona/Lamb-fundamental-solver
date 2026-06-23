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

computeElasticSeedA0 = getOption(options, 'mrlfeComputeA0Like', true);
computeElasticSeedS0 = getOption(options, 'mrlfeComputeS0Like', true);

computeElasticRealK = getOption(options, 'computeMRLFEElasticRealK', false) || ...
    getOption(options, 'computeMRLFERealK', false) || ...
    getOption(options, 'computeMRLFE', false);
computeViscoRealK = getOption(options, 'computeMRLFEViscoRealK', false) || ...
    getOption(options, 'computeMRLFEHanViscoRealK', false);
computeComplexK = getOption(options, 'computeMRLFEComplexK', false);

% mRLFE branches are dependent on Rayleigh-Lamb seed branches. Force the seed
% branches required by the selected A0-like/S0-like branches even when the RL
% checkboxes are not selected explicitly in the GUI.
needMRLFE = computeElasticRealK || computeViscoRealK || computeComplexK;
computeA0 = options.computeA0 || (needMRLFE && computeElasticSeedA0);
computeS0 = options.computeS0 || (needMRLFE && computeElasticSeedS0);

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

elasticResult = [];
if computeElasticRealK || computeViscoRealK
    mrlfeParams = buildMRLFEParamsFromOptions(options);
    mrlfeParams.solveComplexK = false;
    mrlfeParams.etaS = 0;
    mrlfeParams.etaL = 0;
    mrlfeParams.useComplexLambda = false;

    elasticOptions = makeElasticRealKOptions(options);
    elasticResult = computeMRLFE(frequency, material, results.geometry, results.modes, mrlfeParams, elasticOptions);

    % The viscoelastic real-k branch uses this elastic real-k result as its
    % modal reference. Keep it available even when only the viscoelastic model
    % was explicitly requested.
    results.models.mRLFEElasticRealK = elasticResult;
    results.models.mRLFERealK = results.models.mRLFEElasticRealK; % legacy alias
end

if computeViscoRealK
    mrlfeParams = buildMRLFEParamsFromOptions(options);
    mrlfeParams.solveComplexK = false;
    mrlfeParams.etaL = 0;
    mrlfeParams.useComplexLambda = false;

    viscoOptions = makeViscoRealKOptions(options);
    results.models.mRLFEViscoRealK = computeMRLFE(frequency, material, results.geometry, elasticResult.branches, mrlfeParams, viscoOptions);
    results.models.mRLFEHanViscoRealK = results.models.mRLFEViscoRealK; % legacy alias
end

% Complex-k remains an experimental attenuation path. It is hidden from the
% main GUI, but kept available for advanced scripts.
if computeComplexK
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
elseif isfield(results.models, 'mRLFEViscoRealK')
    results.models.mRLFE = results.models.mRLFEViscoRealK;
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
% Viscoelastic real-k is seeded from the elastic real-k result. It uses a
% conservative modal-local tracker because viscosity can introduce strong
% competing residual valleys and low-Cp edge minima.
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
if isfield(options, fieldName) && ~isempty(options.(fieldName))
    value = options.(fieldName);
else
    value = defaultValue;
end
end
