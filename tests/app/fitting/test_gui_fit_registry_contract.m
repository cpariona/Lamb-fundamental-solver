clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

fprintf('\nRunning GUI fitting backend contract test...\n');
fprintf('------------------------------------------\n');

registry = guiGetFitRegistry();
assert(isfield(registry, 'defaultModelFamily'), 'Fit registry missing defaultModelFamily.');
assert(isfield(registry, 'modelFamilies'), 'Fit registry missing modelFamilies.');
assert(numel(registry.modelFamilies) >= 3, 'Fit registry must expose Rayleigh-Lamb, mRLFE, and AE IOP/HGO model families.');

rlFamily = registry.modelFamilies(1);
assert(rlFamily.id == "rayleigh_lamb", 'First fit family should be Rayleigh-Lamb.');
assert(any(rlFamily.branchNames == "A0"), 'Rayleigh-Lamb fit registry must include A0.');
assert(any([rlFamily.parameters.canFit]), 'At least one Rayleigh-Lamb parameter must be fit-capable.');

mrlfeFamily = registry.modelFamilies(2);
assert(mrlfeFamily.id == "mrlfe", 'Second fit family should be mRLFE.');
assert(any(mrlfeFamily.branchNames == "A0Like"), 'mRLFE fit registry must include A0Like.');
assert(any([mrlfeFamily.parameters.canFit]), 'At least one mRLFE parameter must be fit-capable.');

aeFamily = registry.modelFamilies(3);
assert(aeFamily.id == "acoustoelastic_iop_hgo", 'Third fit family should be AE IOP/HGO.');
assert(any(aeFamily.branchNames == "atlasA0"), 'AE IOP/HGO fit registry must include atlasA0.');
assert(any([aeFamily.parameters.canFit]), 'At least one AE IOP/HGO parameter must be fit-capable.');

%% Rayleigh-Lamb app-level fit
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
rlSummary = fitOutput.normalized.summaryTable;
assert(height(rlSummary) == numel(rlFamily.parameters), ...
    'Normalized Rayleigh-Lamb summary must contain every registered parameter.');
assert(nnz(string(rlSummary.Role) == "Fit") == 1, ...
    'Normalized Rayleigh-Lamb summary must contain exactly one fitted parameter.');
assert(nnz(string(rlSummary.Role) == "Fixed") == numel(rlFamily.parameters) - 1, ...
    'Normalized Rayleigh-Lamb summary must contain all fixed parameters.');
assert(any(string(rlSummary.Parameter) == "Shear modulus" & string(rlSummary.Role) == "Fit"), ...
    'Normalized Rayleigh-Lamb summary must identify shear modulus as fitted.');
fprintf('Rayleigh-Lamb recovered mu: %.3f kPa\n', fitOutput.fitResult.bestParams.mu / 1e3);

%% mRLFE app-level fit
mrlfeParams = mrlfeDefaultSweepParams();
mrlfeParams.mu = 75e3;
mrlfeParams.thickness = 0.50e-3;
mrlfeParams.rho = 1070;
mrlfeParams.nu = 0.4999;

mrlfeFrequency_Hz = linspace(1000, 8000, 6).';
mrlfeOptions = mrlfeDefaultSweepOptions("A0Like", 'EtaS', 0.0);
mrlfeCpSynthetic_mps = mrlfeEvaluateFitModel(mrlfeParams, mrlfeFrequency_Hz, "A0Like", mrlfeOptions);

mrlfeExperimental = struct();
mrlfeExperimental.frequency_Hz = mrlfeFrequency_Hz;
mrlfeExperimental.Cp_mps = mrlfeCpSynthetic_mps;
mrlfeExperimental.validMask = true(size(mrlfeFrequency_Hz));

mrlfeRequest = guiBuildFitRequest("mrlfe", ...
    'branchName', "A0Like", ...
    'mode', "basic", ...
    'experimental', mrlfeExperimental, ...
    'fixedParams', struct('thickness', mrlfeParams.thickness, 'rho', mrlfeParams.rho, 'nu', mrlfeParams.nu), ...
    'freeParams', "mu", ...
    'initialGuess', struct('mu', 50e3), ...
    'bounds', struct('mu', [20e3, 160e3]), ...
    'controls', struct('robustness', "Fast", 'etaS', 0.0, 'fluidDensity', 1000, 'fluidSoundSpeed', 1500), ...
    'fitOptions', struct('useStandardErrorWeights', false, ...
        'optimizerOptions', optimset('Display', 'off', 'MaxIter', 35, 'MaxFunEvals', 70, 'TolX', 1e-4)));

mrlfeFitOutput = guiRunFit(mrlfeRequest);
assert(mrlfeFitOutput.modelFamily == "mrlfe", 'Unexpected mRLFE fitOutput modelFamily.');
assert(mrlfeFitOutput.branchName == "A0Like", 'Unexpected mRLFE fitOutput branchName.');
assert(isfield(mrlfeFitOutput, 'fitResult'), 'mRLFE fitOutput missing fitResult.');
assert(isfield(mrlfeFitOutput, 'normalized'), 'mRLFE fitOutput missing normalized result.');

mrlfeRelativeMuError = abs(mrlfeFitOutput.fitResult.bestParams.mu - mrlfeParams.mu) / mrlfeParams.mu;
assert(mrlfeRelativeMuError < 0.05, 'App-level mRLFE fit did not recover mu within 5%%.');
assert(mrlfeFitOutput.normalized.metrics.RMSE < 0.10, 'Normalized app-level mRLFE fit RMSE is unexpectedly high.');
assert(mrlfeFitOutput.normalized.identifiability.classification == "locally_identifiable", ...
    'App-level mRLFE synthetic fit should be locally identifiable.');
mrlfeSummary = mrlfeFitOutput.normalized.summaryTable;
assert(height(mrlfeSummary) == numel(mrlfeFamily.parameters), ...
    'Normalized mRLFE summary must contain every registered parameter.');
assert(nnz(string(mrlfeSummary.Role) == "Fit") == 1, ...
    'Normalized mRLFE summary must contain exactly one fitted parameter.');
assert(nnz(string(mrlfeSummary.Role) == "Fixed") == numel(mrlfeFamily.parameters) - 1, ...
    'Normalized mRLFE summary must contain all fixed parameters.');
assert(any(string(mrlfeSummary.Parameter) == "Shear modulus" & string(mrlfeSummary.Role) == "Fit"), ...
    'Normalized mRLFE summary must identify shear modulus as fitted.');
fprintf('mRLFE recovered mu: %.3f kPa\n', mrlfeFitOutput.fitResult.bestParams.mu / 1e3);

fprintf('\nGUI fitting backend contract test passed.\n');
