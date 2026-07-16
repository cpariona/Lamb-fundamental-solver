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
    error('rlComputeFundamentalLambModes:mRLFEComplexKRemoved', ...
        ['The legacy mRLFE complex-k route has been removed. ', ...
        'Use the public mrlfeSolve real-k production API.']);
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

elasticParams = mrlfeParams;
elasticParams.etaS = 0;
elasticReference = solvePublicMRLFERealK(frequency, material, geometry, seedModes, elasticParams, options);
if isViscoelastic
    realKResult = solvePublicMRLFERealK(frequency, material, geometry, seedModes, mrlfeParams, options);
else
    realKResult = elasticReference;
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

function mrlfeParams = buildMRLFEParamsFromOptions(options)
mrlfeParams = mrlfeDefaultInternalParameters();
if isfield(options, 'mrlfeParams')
    userParams = options.mrlfeParams;
    names = fieldnames(userParams);
    for i = 1:numel(names)
        mrlfeParams.(names{i}) = userParams.(names{i});
    end
end
end

function result = solvePublicMRLFERealK(frequency, material, geometry, seedModes, mrlfeParams, options)
branchNames = requestedMRLFEBranches(seedModes, options);
modelResults = cell(1, numel(branchNames));
for i = 1:numel(branchNames)
    request = buildPublicMRLFERequest(frequency, material, geometry, mrlfeParams, branchNames(i));
    modelResults{i} = mrlfeSolve(request);
end

if ~isempty(modelResults)
    result = modelResults{1}.debug.rawInternalResult.rawFullResult.models.mRLFERealK;
else
    result = emptyPublicMRLFEResult(frequency, mrlfeParams);
end
result.parameters = mrlfeParams;
result.frequency = frequency(:);
result.requestedBranches = struct('A0Like', any(branchNames == "A0Like"), ...
    'S0Like', any(branchNames == "S0Like"));
result.branches = struct();
for i = 1:numel(modelResults)
    branchName = char(modelResults{i}.branch);
    result.branches.(branchName) = modelResults{i}.debug.rawInternalResult.branch;
end
result.publicModelResults = modelResultsByBranch(modelResults);
result.diagnostics = buildPublicMRLFEDiagnostics(result, modelResults);
end

function request = buildPublicMRLFERequest(frequency, material, geometry, mrlfeParams, branchName)
request = struct();
request.branch = string(branchName);
request.frequency_Hz = frequency(:);
request.material = struct('mu_Pa', material.mu, ...
    'etaS_Pas', getOption(mrlfeParams, 'etaS', 0), ...
    'rho_kgm3', material.rho, ...
    'nu', material.nu);
request.geometry = struct('thickness_m', geometry.thickness);
request.fluid = struct('density_kgm3', getOption(mrlfeParams, 'fluidDensity', 1000), ...
    'soundSpeed_mps', getOption(mrlfeParams, 'fluidSoundSpeed', 1500));
request.numerics = struct('preset', "fast");
request.selection = struct('strategy', "adaptive");
if string(branchName) == "A0Like"
    request.termination = struct('policy', "physicalTail");
else
    request.termination = struct('policy', "none");
end
request.fallback = struct('policy', "none");
end

function branchNames = requestedMRLFEBranches(seedModes, options)
branchNames = strings(1, 0);
if isfield(seedModes, 'A0') && getOption(options, 'mrlfeComputeA0Like', true)
    branchNames(end+1) = "A0Like";
end
if isfield(seedModes, 'S0') && getOption(options, 'mrlfeComputeS0Like', true)
    branchNames(end+1) = "S0Like";
end
end

function diagnostics = buildPublicMRLFEDiagnostics(result, modelResults)
diagnostics = struct();
diagnostics.variant = "real-k";
diagnostics.branchNames = string(fieldnames(result.branches));
diagnostics.usedInternalTrackingGrid = false;
diagnostics.requestedPointCount = numel(result.frequency);
diagnostics.trackingPointCount = numel(result.frequency);
diagnostics.summary = struct();
diagnostics.execution = modelResultsByBranch(modelResults);
end

function out = modelResultsByBranch(modelResults)
out = struct();
for i = 1:numel(modelResults)
    out.(char(modelResults{i}.branch)) = modelResults{i};
end
end

function result = emptyPublicMRLFEResult(frequency, mrlfeParams)
result = struct();
result.modelName = "mRLFE";
result.variant = "real-k";
result.description = "Public mRLFE real-k solve with no requested branches.";
result.parameters = mrlfeParams;
result.frequency = frequency(:);
result.branches = struct();
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
