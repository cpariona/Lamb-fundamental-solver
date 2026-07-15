% Diagnose maintained mRLFE fitting cost, profile sensitivity, and etaS cache.
% Runtime category: extended diagnostic. No files are written.
%
% Last validated with:
%   diagnose_mrlfe_fit_performance

clear; clc;
startup

branchName = "A0Like";
frequency_Hz = linspace(1000, 8000, 10).';
params = mrlfeDefaultSweepParams();
params.mu = 75e3;
params.thickness = 0.50e-3;
params.rho = 1070;
params.nu = 0.4999;
params.etaS = 0.05;

profiles = ["Fast", "Balanced", "Robust"];
rows = repmat(struct('Profile', "", 'ElapsedSeconds', NaN, ...
    'SolvePointCount', NaN, 'ValidCount', 0, 'QualityAccepted', false, ...
    'Engine', "", 'Preset', "", 'GridPolicy', ""), numel(profiles), 1);

fprintf('\n=== maintained mRLFE fit-performance diagnostic ===\n');
for i = 1:numel(profiles)
    options = mrlfeDefaultSweepOptions(branchName, 'EtaS', params.etaS);
    options.executionProfile = profiles(i);
    options.effectiveExecutionProfile = profiles(i);
    options.mrlfeNumericalPreset = lower(profiles(i));
    options.forwardModel = struct('gridPolicy', "fitOptimized", ...
        'minimumPointCount', 12, 'maximumPointCount', 40, 'maximumStep_Hz', 250);
    timerStart = tic;
    [~, raw] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, options);
    rows(i).Profile = profiles(i);
    rows(i).ElapsedSeconds = toc(timerStart);
    rows(i).SolvePointCount = raw.modelResult.diagnostics.summary.solvePointCount;
    rows(i).ValidCount = raw.modelResult.quality.validCount;
    rows(i).QualityAccepted = raw.modelResult.quality.accepted;
    rows(i).Engine = raw.modelResult.execution.internalEngine;
    rows(i).Preset = raw.modelResult.execution.effectivePreset;
    rows(i).GridPolicy = raw.fitGrid.gridPolicy;
end
profileTable = struct2table(rows);
disp(profileTable);

trueParams = params;
trueParams.etaS = 0.12;
syntheticOptions = mrlfeDefaultSweepOptions(branchName, 'EtaS', trueParams.etaS);
[cpSynthetic, ~] = mrlfeEvaluateFitModel(trueParams, frequency_Hz, branchName, syntheticOptions);
experimental = struct('frequency_Hz', frequency_Hz, 'Cp_mps', cpSynthetic, ...
    'validMask', isfinite(cpSynthetic));

cachedConfig = etaSFitConfig(branchName, trueParams, false);
uncachedConfig = etaSFitConfig(branchName, trueParams, true);
timerStart = tic;
cachedProblem = mrlfeBuildFitProblem(experimental, cachedConfig);
cachedBuildSeconds = toc(timerStart);
timerStart = tic;
uncachedProblem = mrlfeBuildFitProblem(experimental, uncachedConfig);
uncachedBuildSeconds = toc(timerStart);

probe = trueParams;
probe.etaS = 0.04;
timerStart = tic;
[cpCached, ~] = cachedProblem.evaluateModel(probe);
cachedEvaluationSeconds = toc(timerStart);
timerStart = tic;
[cpUncached, ~] = uncachedProblem.evaluateModel(probe);
uncachedEvaluationSeconds = toc(timerStart);
valid = isfinite(cpCached) & isfinite(cpUncached);
cacheParityRmse_mps = sqrt(mean((cpCached(valid) - cpUncached(valid)).^2, 'omitnan'));

cacheSummary = table(cachedBuildSeconds, uncachedBuildSeconds, ...
    cachedEvaluationSeconds, uncachedEvaluationSeconds, cacheParityRmse_mps, ...
    cachedProblem.forwardCache.enabled, string(cachedProblem.forwardCache.kind), ...
    'VariableNames', {'CachedBuildSeconds','UncachedBuildSeconds', ...
    'CachedEvaluationSeconds','UncachedEvaluationSeconds','CpParityRMSE_mps', ...
    'CacheEnabled','CacheKind'});
disp(cacheSummary);

diagnostic = struct('profileTable', profileTable, 'cacheSummary', cacheSummary, ...
    'frequency_Hz', frequency_Hz, 'params', params);
assignin('base', 'MRLFEFitPerformanceDiagnostic', diagnostic);

function config = etaSFitConfig(branchName, params, disableCache)
config = struct( ...
    'branchName', branchName, 'freeParams', "etaS", ...
    'fixedParams', struct('mu', params.mu, 'thickness', params.thickness, ...
        'rho', params.rho, 'nu', params.nu), ...
    'initialGuess', struct('etaS', 0.04), ...
    'bounds', struct('etaS', [0, 0.30]), ...
    'solverOptions', mrlfeDefaultSweepOptions(branchName, 'EtaS', 0.04), ...
    'fitOptions', struct('useStandardErrorWeights', false));
config.solverOptions.mrlfeDisableForwardCache = disableCache;
end
