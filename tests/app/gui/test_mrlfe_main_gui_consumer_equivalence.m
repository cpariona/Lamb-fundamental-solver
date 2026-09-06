function test_mrlfe_main_gui_consumer_equivalence()
%TEST_MRLFE_MAIN_GUI_CONSUMER_EQUIVALENCE Compare Main GUI, SweepTool, and FitTool consumers.

fprintf('\nRunning mRLFE Main GUI consumer-equivalence test...\n');
fprintf('---------------------------------------------------\n');

branchName = "A0Like";
etaS = 0.05;
mu = 75e3;
[mainOut, params, options] = runMainCase(branchName, etaS, mu);
mainResult = mainOut.metadata.modelResults.A0Like;

%% SweepTool same point.
sweepRequest = guiBuildSweepRequest("mrlfe", ...
    'modelLabel', "mRLFE real-k", ...
    'branchName', branchName, ...
    'sweepField', "mu", ...
    'sweepLabel', "mu", ...
    'sweepValuesDisplay', mu ./ 1e3, ...
    'displayUnit', "kPa", ...
    'displayScale', 1e3, ...
    'baseParams', params, ...
    'controls', struct('executionProfile', "Fast", 'etaS', etaS, ...
        'fluidDensity', 1000, 'fluidSoundSpeed', 1500, ...
        'mrlfeA0Policy', "physicalTail"));
sweepOut = guiRunMRLFESweep(sweepRequest);
sweepResult = sweepOut.sweepResult.points{1}.modelResult;

%% FitTool requested-curve evaluator on the same numerical preset grid.
fitParams = params;
fitParams.etaS = etaS;
fitOptions = mrlfeDefaultSweepOptions(branchName, 'EtaS', etaS, ...
    'A0Policy', "physicalTail");
fitOptions.mrlfeParams.fluidDensity = 1000;
fitOptions.mrlfeParams.fluidSoundSpeed = 1500;
fitOptions.forwardModel = struct('gridPolicy', "numericalPreset");
[fitCp, fitRaw] = mrlfeEvaluateFitModel(fitParams, mainResult.frequency_Hz, branchName, fitOptions);

assertVectorEqual(mainResult.phaseVelocity_mps, sweepResult.phaseVelocity_mps, ...
    'Main GUI and SweepTool Cp differ.');
assert(isequal(mainResult.validMask(:), sweepResult.validMask(:)), ...
    'Main GUI and SweepTool valid masks differ.');
assert(mainResult.execution.effectivePreset == sweepResult.execution.effectivePreset, ...
    'Main GUI and SweepTool presets differ.');
assert(mainResult.execution.internalEngine == sweepResult.execution.internalEngine, ...
    'Main GUI and SweepTool engines differ.');
assert(mainResult.termination.policy == sweepResult.termination.policy, ...
    'Main GUI and SweepTool termination differs.');
assert(mainResult.fallback.policy == sweepResult.fallback.policy && ...
    mainResult.fallback.applied == sweepResult.fallback.applied, ...
    'Main GUI and SweepTool fallback differs.');

assert(fitRaw.fitGrid.gridPolicy == "numericalPreset", ...
    'FitTool comparison must use the numericalPreset grid policy.');
assertVectorEqual(mainResult.phaseVelocity_mps, fitCp, ...
    'Main GUI and FitTool requested-curve Cp differ.');
assert(isequal(mainResult.validMask(:), fitRaw.validMask(:)), ...
    'Main GUI and FitTool requested-curve valid masks differ.');

fprintf('Main GUI vs SweepTool max Cp diff: %.12g\n', max(abs(mainResult.phaseVelocity_mps - sweepResult.phaseVelocity_mps), [], 'omitnan'));
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

options = mrlfeDefaultSweepOptions(branchName, 'EtaS', etaS);
options.branchNames = branchName;
options.mrlfeA0Policy = "physicalTail";
options.mrlfeParams = lamb.models.mrlfe.configuration.mrlfeDefaultInternalParameters();
options.mrlfeParams.etaS = etaS;
options.mrlfeParams.fluidDensity = 1000;
options.mrlfeParams.fluidSoundSpeed = 1500;

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
