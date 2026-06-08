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

    % Han real-k uses the elastic real-k branch as its modal reference. Keep
    % this reference in the results even when Han was the only explicitly
    % requested fluid-loaded model, so it can be plotted/exported/diagnosed.
    results.models.mRLFEElasticRealK = elasticResult;
    results.models.mRLFERealK = results.models.mRLFEElasticRealK;
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
elasticOptions.mrlfeResidualTolerance = max(getOptionValue(options, 'mrlfeResidualTolerance', 1e-4), 1e-3);
end

function hanOptions = makeHanRealKOptions(options)
% Han real-k uses real lambda, complex mu*, and real k.  The global residual
% minimum can fall into a spurious low-Cp valley.  Therefore Han uses a
% conservative modal-local tracker: local minima are filtered by a
% branch-specific Cp window around the elastic mRLFE reference, and the branch
% is cut when no mode-relevant local minimum remains.
hanOptions = options;
hanOptions.mrlfeA0UseDPTracker = false;
hanOptions.mrlfeRealKAnchorToSeed = true;
hanOptions.mrlfeRealKHardReferenceWindow = false;
hanOptions.mrlfeRealKScoreMode = "modal";
hanOptions.mrlfeRealKRequireLocalMinimum = true;
hanOptions.mrlfeRealKUseModalCpWindow = getOptionValue(options, 'mrlfeHanUseModalLocalTracker', true);
hanOptions.mrlfeRealKStopAtFirstMissingModalMinimum = getOptionValue(options, 'mrlfeRealKStopAtFirstMissingModalMinimum', true);
hanOptions.mrlfeRealKReferenceWeight = 120.0;
hanOptions.mrlfeRealKPredictionWeight = 6.0;
hanOptions.mrlfeRealKPreviousCpWeight = getOptionValue(options, 'mrlfeHanPreviousCpWeight', 80.0);
hanOptions.mrlfeRealKPreviousKWeight = getOptionValue(options, 'mrlfeHanPreviousKWeight', 0.0);
hanOptions.mrlfeRealKPreviousCpMaxRelativeJump = getOptionValue(options, 'mrlfeHanPreviousCpMaxRelativeJump', inf);
hanOptions.mrlfeRealKMaxRelativeKDrift = inf;
hanOptions.mrlfeRealKValidationMaxRelativeKDrift = inf;
hanOptions.mrlfeRealKValidationMaxRelativeCpDrift = inf;
hanOptions.mrlfeResidualTolerance = max(getOptionValue(options, 'mrlfeResidualTolerance', 1e-4), 1e-3);
end

function value = getOptionValue(options, fieldName, defaultValue)
if isfield(options, fieldName)
    value = options.(fieldName);
else
    value = defaultValue;
end
end
