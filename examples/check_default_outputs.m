% Lightweight checks for the default A0/S0 calculation.
% This script is intended for manual validation in MATLAB.

startup();

params = struct();
params.modelType = "YoungPoissonFixedCL";
params.rho = 1070;
params.E = 475e3;
params.nu = 0.4999;
params.CL = 1500;
params.lambda = 2.40e9;
params.mu = 158e3;
params.thickness = 0.50e-3;
params.fmin = 10;
params.fmax = 8000;
params.numFrequencyPoints = 250;
params.frequencySpacing = "logspace";

options = struct();
options.computeA0 = true;
options.computeS0 = true;
options.gridPointsInitial = 3000;
options.gridPointsTracking = 600;
options.jumpTol = 0.35;
options.residualTolerance = 1e-5;

results = computeFundamentalLambModes(params, options);

fprintf('\nDefault output check\n');
fprintf('--------------------\n');
fprintf('Material: E = %.6g Pa, nu = %.6g, CL = %.6g m/s, CT = %.6g m/s\n', ...
    results.material.E, results.material.nu, results.material.CL, results.material.CT);
fprintf('thickness = %.6g m\n\n', results.geometry.thickness);

modeNames = fieldnames(results.modes);
for i = 1:numel(modeNames)
    name = modeNames{i};
    mode = results.modes.(name);
    finiteCp = isfinite(mode.Cp);
    finiteKThickness = isfinite(mode.kThickness);
    finiteResidual = isfinite(mode.residual);

    fprintf('%s:\n', name);
    fprintf('  valid points: %d / %d\n', sum(mode.valid), numel(mode.valid));
    fprintf('  finite Cp points: %d / %d\n', sum(finiteCp), numel(finiteCp));
    fprintf('  finite kThickness points: %d / %d\n', sum(finiteKThickness), numel(finiteKThickness));

    if any(finiteCp)
        fprintf('  Cp min/max: %.6g / %.6g m/s\n', min(mode.Cp(finiteCp)), max(mode.Cp(finiteCp)));
    else
        fprintf('  Cp min/max: no finite values\n');
    end

    if any(finiteResidual)
        fprintf('  max residual: %.3e\n', max(mode.residual(finiteResidual)));
    else
        fprintf('  max residual: no finite values\n');
    end
    fprintf('\n');
end
