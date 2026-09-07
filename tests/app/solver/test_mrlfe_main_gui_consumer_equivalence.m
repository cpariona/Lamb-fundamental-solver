function test_mrlfe_main_gui_consumer_equivalence()
%TEST_MRLFE_MAIN_GUI_CONSUMER_EQUIVALENCE Compare Main GUI and FitTool consumers.

fprintf('\nRunning mRLFE Main GUI consumer-equivalence test...\n');
fprintf('---------------------------------------------------\n');

branchName = "A0Like";
etaS = 0.05;
mu = 75e3;
[mainOut, params, options] = runMainCase(branchName, etaS, mu);
mainResult = mainOut.metadata.modelResults.A0Like;

%% FitTool requested-curve evaluator on the same numerical preset grid.
fitParams = params;
fitParams.etaS = etaS;
[fitOptions, ~] = mrlfeResolveExecutionProfile(branchName, "Fast", ...
    'Surface', "fit", 'EtaS', etaS, 'A0Policy', "physicalTail");
fitOptions.mrlfeParams.fluidDensity = 1000;
fitOptions.mrlfeParams.fluidSoundSpeed = 1500;
fitOptions.forwardModel = struct('gridPolicy', "numericalPreset");
[fitCp, fitRaw] = lamb.fitting.mrlfe.mrlfeEvaluateFitModel(fitParams, mainResult.frequency_Hz, branchName, fitOptions);

assert(fitRaw.fitGrid.gridPolicy == "numericalPreset", ...
    'FitTool comparison must use the numericalPreset grid policy.');
assertVectorEqual(mainResult.phaseVelocity_mps, fitCp, ...
    'Main GUI and FitTool requested-curve Cp differ.');
assert(isequal(mainResult.validMask(:), fitRaw.validMask(:)), ...
    'Main GUI and FitTool requested-curve valid masks differ.');

fprintf('Main GUI vs FitTool max Cp diff: %.12g\n', max(abs(mainResult.phaseVelocity_mps - fitCp), [], 'omitnan'));
fprintf('\nmRLFE Main GUI consumer-equivalence test passed.\n');
end

function [out, params, options] = runMainCase(branchName, etaS, mu)
params = lamb.models.rayleigh_lamb.rlDefaultParams();
params.fmin = 1000;
params.fmax = 6000;
params.numFrequencyPoints = "auto";
params.frequencySpacing = "hybrid";
params.mu = mu;
params.thickness = 0.5e-3;
params.rho = 1070;
params.nu = 0.4999;

[options, ~] = mrlfeResolveExecutionProfile(branchName, "Fast", ...
    'Surface', "main", 'EtaS', etaS, 'A0Policy', "physicalTail");
options.branchNames = branchName;

out = guiRunMRLFEModel(struct('params', params, 'options', options, ...
    'mrlfeParams', options.mrlfeParams, 'computeVisco', etaS > 0));
end

function assertVectorEqual(a, b, message)
a = a(:);
b = b(:);
both = isfinite(a) & isfinite(b);
assert(isequal(isfinite(a), isfinite(b)), message);
if any(both)
    assert(max(abs(a(both) - b(both))) == 0, message);
end
end
