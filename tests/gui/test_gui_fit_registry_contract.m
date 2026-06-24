clear; clc;
startup

fprintf('\nRunning GUI fitting backend contract test...\n');
fprintf('------------------------------------------\n');

registry = guiGetFitRegistry();
assert(isfield(registry, 'defaultModelFamily'), 'Fit registry missing defaultModelFamily.');
assert(isfield(registry, 'modelFamilies'), 'Fit registry missing modelFamilies.');
assert(~isempty(registry.modelFamilies), 'Fit registry must expose at least one model family.');

rlFamily = registry.modelFamilies(1);
assert(rlFamily.id == "rayleigh_lamb", 'First Phase 3 fit family should be Rayleigh-Lamb.');
assert(any(rlFamily.branchNames == "A0"), 'Rayleigh-Lamb fit registry must include A0.');
assert(any([rlFamily.parameters.canFit]), 'At least one Rayleigh-Lamb parameter must be fit-capable.');

trueParams = rlDefaultParams();
trueParams.mu = 85e3;
trueParams.thickness = 0.50e-3;
trueParams.rho = 1070;
trueParams.nu = 0.4999;

frequency_Hz = linspace(1000, 8000, 8).';
solverOptions = rlDefaultOptions("Fast");
CpSynthetic_mps = rlEvaluateFitModel(trueParams, frequency_Hz, "A0", solverOptions);

experimental = struct();
experimental.frequency_Hz = frequency_Hz;
experimental.Cp_mps = CpSynthetic_mps;
experimental.validMask = true(size(frequency_Hz));

request = guiBuildFitRequest("rayleigh_lamb", ...
    'branchName', "A0", ...
    'mode', "basic", ...
    'experimental', experimental, ...
    'fixedParams', struct('thickness', trueParams.thickness, 'rho', trueParams.rho, 'nu', trueParams.nu), ...
    'freeParams', "mu", ...
    'initialGuess', struct('mu', 50e3), ...
    'bounds', struct('mu', [20e3, 200e3]), ...
    'controls', struct('robustness', "Fast"), ...
    'fitOptions', struct('useStandardErrorWeights', false));

fitOutput = guiRunFit(request);
assert(fitOutput.modelFamily == "rayleigh_lamb", 'Unexpected fitOutput modelFamily.');
assert(fitOutput.branchName == "A0", 'Unexpected fitOutput branchName.');
assert(isfield(fitOutput, 'fitResult'), 'fitOutput missing fitResult.');
assert(isfield(fitOutput, 'normalized'), 'fitOutput missing normalized result.');

relativeMuError = abs(fitOutput.fitResult.bestParams.mu - trueParams.mu) / trueParams.mu;
assert(relativeMuError < 0.03, 'App-level Rayleigh-Lamb fit did not recover mu within 3%%.');
assert(fitOutput.normalized.metrics.RMSE < 0.05, 'Normalized app-level fit RMSE is unexpectedly high.');
assert(fitOutput.normalized.identifiability.classification == "locally_identifiable", ...
    'App-level synthetic fit should be locally identifiable.');
assert(height(fitOutput.normalized.summaryTable) == 1, 'Normalized summary table should contain one free parameter.');

fprintf('Recovered mu: %.3f kPa\n', fitOutput.fitResult.bestParams.mu / 1e3);
fprintf('\nGUI fitting backend contract test passed.\n');
