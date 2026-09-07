function results = rlSolveFundamentalModes(params, options)
%RLSOLVEFUNDAMENTALMODES Solve fundamental A0/S0 branches.

timerStart = tic;
lamb.models.rayleigh_lamb.configuration.rlValidateParams(params);
lamb.models.rayleigh_lamb.configuration.rlValidateOptions(options);

material = lamb.models.rayleigh_lamb.core.rlComputeMaterial(params);
geometry = lamb.models.rayleigh_lamb.core.rlComputeGeometry(params);
frequency = lamb.grids.buildFrequencyVector(params);
omega = 2 * pi * frequency;

solverOptions = buildSolverOptions(options, material);

modes = struct();
publicGeometry = rmfield(geometry, 'halfThickness');
approximations = lamb.models.rayleigh_lamb.approximations.rlComputeAnalyticalApproximations(frequency, material, publicGeometry);

if options.computeA0
    geometryForSpec = geometry;
    geometryForSpec.frequency0 = frequency(1);
    branchSpecA = lamb.models.rayleigh_lamb.core.rlMakeBranchSpec("A0", material, geometryForSpec);
    solverOptionsA = applyBranchSpec(solverOptions, branchSpecA);

    residualFcnA = @(Cp, f) lamb.models.rayleigh_lamb.equations.rlAResidual(Cp, f, material.CL, material.CT, geometry.halfThickness);
    [CpA0, residualA0] = lamb.models.rayleigh_lamb.tracking.rlSolveFundamentalBranch(frequency, residualFcnA, solverOptionsA);
    kA0 = omega ./ CpA0;

    modes.A0 = packModeResults("A0", branchSpecA.family, frequency, omega, CpA0, kA0, geometry.thickness, residualA0);
end
if options.computeS0
    branchSpecS = lamb.models.rayleigh_lamb.core.rlMakeBranchSpec("S0", material, geometry);
    solverOptionsS = applyBranchSpec(solverOptions, branchSpecS);

    residualFcnS = @(Cp, f) lamb.models.rayleigh_lamb.equations.rlSResidual(Cp, f, material.CL, material.CT, geometry.halfThickness);
    [CpS0, residualS0] = lamb.models.rayleigh_lamb.tracking.rlSolveFundamentalBranch(frequency, residualFcnS, solverOptionsS);
    kS0 = omega ./ CpS0;

    modes.S0 = packModeResults("S0", branchSpecS.family, frequency, omega, CpS0, kS0, geometry.thickness, residualS0);
end
elapsedSeconds = toc(timerStart);
results = lamb.models.rayleigh_lamb.results.rlBuildResult(params, options, material, geometry, frequency, modes, approximations, elapsedSeconds);
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
    'frequency_Hz', frequency(:), ...
    'phaseVelocity_mps', Cp(:), ...
    'wavenumber_radpm', k(:), ...
    'validMask', isfinite(Cp(:)), ...
    'angularFrequency_radps', omega(:), ...
    'wavenumberThickness', k(:) * thickness, ...
    'diagnostics', struct('residual', residual(:)));
end
