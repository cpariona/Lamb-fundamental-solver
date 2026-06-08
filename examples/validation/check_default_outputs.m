% Lightweight checks for the default A0/S0 calculation.
% This script is intended for manual validation in MATLAB.

startup();

params = defaultParams();
options = defaultOptions("Balanced");
options.computeA0 = true;
options.computeS0 = true;

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
