function results = computeFundamentalLambModes(params, options)
% Compute fundamental A0/S0 branches using independent continuation solves.

material = computeMaterial(params);
geometry = computeGeometry(params);
frequency = buildFrequencyVector(params);
omega = 2 * pi * frequency;

solverOptions = struct();
solverOptions.CT = material.CT;
solverOptions.gridPointsInitial = options.gridPointsInitial;
solverOptions.gridPointsTracking = options.gridPointsTracking;
solverOptions.jumpTol = options.jumpTol;
solverOptions.residualTolerance = options.residualTolerance;

results = struct();
results.material = material;
results.geometry = rmfield(geometry, 'halfThickness');
results.grid.frequency = frequency;
results.grid.omega = omega;
results.modes = struct();

if options.computeA0
    residualFcnA = @(Cp, f) rayleighLambAResidual(Cp, f, material.CL, material.CT, geometry.halfThickness);
    [CpA0, residualA0] = solveFundamentalBranch(frequency, residualFcnA, solverOptions);
    kA0 = omega ./ CpA0;

    results.modes.A0 = struct( ...
        'frequency', frequency, ...
        'omega', omega, ...
        'Cp', CpA0, ...
        'k', kA0, ...
        'kThickness', kA0 * geometry.thickness, ...
        'residual', residualA0, ...
        'valid', isfinite(CpA0));
end

if options.computeS0
    solverOptionsS = solverOptions;
    solverOptionsS.initialCpGuess = sqrt(material.E / (material.rho * (1 - material.nu^2)));

    residualFcnS = @(Cp, f) rayleighLambSResidual(Cp, f, material.CL, material.CT, geometry.halfThickness);
    [CpS0, residualS0] = solveFundamentalBranch(frequency, residualFcnS, solverOptionsS);
    kS0 = omega ./ CpS0;

    results.modes.S0 = struct( ...
        'frequency', frequency, ...
        'omega', omega, ...
        'Cp', CpS0, ...
        'k', kS0, ...
        'kThickness', kS0 * geometry.thickness, ...
        'residual', residualS0, ...
        'valid', isfinite(CpS0));
end
end
