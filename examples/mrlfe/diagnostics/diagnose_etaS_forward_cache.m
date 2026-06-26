% Diagnose the mRLFE etaS fitting elastic-reference forward cache.
% Diagnostic only: does not change solver internals.
%
% The etaS fit changes viscosity while keeping mu, thickness, rho, and nu fixed.
% Therefore the elastic etaS=0 reference branch can be precomputed once and
% reused across viscous objective evaluations.

clear; clc;
startup

branchName = "A0Like";
trueEtaS = 0.12;
initialEtaS = 0.04;
etaSBounds = [0.0, 0.30];
frequency_Hz = linspace(1000, 8000, 10).';

trueParams = mrlfeDefaultSweepParams();
trueParams.mu = 75e3;
trueParams.thickness = 0.50e-3;
trueParams.rho = 1070;
trueParams.nu = 0.4999;
trueParams.etaS = trueEtaS;

solverOptionsSynthetic = mrlfeDefaultSweepOptions(branchName, 'EtaS', trueEtaS);
[CpSynthetic_mps, rawSynthetic] = mrlfeEvaluateFitModel(trueParams, frequency_Hz, branchName, solverOptionsSynthetic);
validSynthetic = isfinite(CpSynthetic_mps(:));
assert(any(validSynthetic), 'Synthetic viscous mRLFE data must contain finite Cp points.');

experimental = struct();
experimental.frequency_Hz = frequency_Hz;
experimental.Cp_mps = CpSynthetic_mps;
experimental.validMask = validSynthetic;

fprintf('\n=== mRLFE etaS forward-cache diagnostic ===\n');
fprintf('Branch: %s | true etaS = %.4g Pa*s | initial etaS = %.4g Pa*s\n', branchName, trueEtaS, initialEtaS);
fprintf('Frequencies: %.0f to %.0f Hz | requested points = %d\n', min(frequency_Hz), max(frequency_Hz), numel(frequency_Hz));
fprintf('Synthetic valid points: %d/%d\n', nnz(validSynthetic), numel(validSynthetic));
fprintf('Synthetic solver elapsed: %.6g s\n', getSolverElapsedSeconds(rawSynthetic));

fitConfigCached = makeEtaSFitConfig(branchName, trueParams, initialEtaS, etaSBounds, false);
fitConfigNoCache = makeEtaSFitConfig(branchName, trueParams, initialEtaS, etaSBounds, true);

% Build-problem timing includes cache precomputation when enabled.
tBuildCached = tic;
problemCached = mrlfeBuildFitProblem(experimental, fitConfigCached);
buildCachedSeconds = toc(tBuildCached);

tBuildNoCache = tic;
problemNoCache = mrlfeBuildFitProblem(experimental, fitConfigNoCache);
buildNoCacheSeconds = toc(tBuildNoCache);

probeParams = trueParams;
probeParams.etaS = initialEtaS;

tEvalCached = tic;
[CpCachedProbe, rawCachedProbe] = problemCached.evaluateModel(probeParams);
evalCachedSeconds = toc(tEvalCached);

tEvalNoCache = tic;
[CpNoCacheProbe, rawNoCacheProbe] = problemNoCache.evaluateModel(probeParams);
evalNoCacheSeconds = toc(tEvalNoCache);

validProbe = isfinite(CpCachedProbe(:)) & isfinite(CpNoCacheProbe(:));
probeRmseDiff = sqrt(mean((CpCachedProbe(validProbe) - CpNoCacheProbe(validProbe)).^2, 'omitnan'));

fprintf('\nBuild/evaluation comparison at etaS = %.4g Pa*s:\n', initialEtaS);
fprintf('  build cached   = %.6g s\n', buildCachedSeconds);
fprintf('  build no cache = %.6g s\n', buildNoCacheSeconds);
fprintf('  eval cached    = %.6g s | solver elapsed = %.6g s\n', evalCachedSeconds, getSolverElapsedSeconds(rawCachedProbe));
fprintf('  eval no cache  = %.6g s | solver elapsed = %.6g s\n', evalNoCacheSeconds, getSolverElapsedSeconds(rawNoCacheProbe));
fprintf('  eval speedup   = %.6g x\n', evalNoCacheSeconds / evalCachedSeconds);
fprintf('  probe Cp RMSE difference cached vs no-cache = %.6g m/s\n', probeRmseDiff);
fprintf('  cache enabled = %d | kind = %s | reason = %s\n', ...
    problemCached.forwardCache.enabled, problemCached.forwardCache.kind, problemCached.forwardCache.reason);
fprintf('  no-cache enabled = %d | reason = %s\n', ...
    problemNoCache.forwardCache.enabled, problemNoCache.forwardCache.reason);

% Full fit timing.
tFitCached = tic;
fitCached = mrlfeFitDispersionData(experimental, fitConfigCached);
fitCachedSeconds = toc(tFitCached);

tFitNoCache = tic;
fitNoCache = mrlfeFitDispersionData(experimental, fitConfigNoCache);
fitNoCacheSeconds = toc(tFitNoCache);

fprintf('\nFull etaS fit comparison:\n');
fprintf('  cached fit time    = %.6g s\n', fitCachedSeconds);
fprintf('  no-cache fit time  = %.6g s\n', fitNoCacheSeconds);
fprintf('  fit speedup        = %.6g x\n', fitNoCacheSeconds / fitCachedSeconds);
fprintf('  cached etaS        = %.6g Pa*s | RMSE = %.6g m/s\n', fitCached.bestParams.etaS, fitCached.metrics.RMSE);
fprintf('  no-cache etaS      = %.6g Pa*s | RMSE = %.6g m/s\n', fitNoCache.bestParams.etaS, fitNoCache.metrics.RMSE);
fprintf('  etaS abs diff      = %.6g Pa*s\n', abs(fitCached.bestParams.etaS - fitNoCache.bestParams.etaS));

summary = struct();
summary.problemCached = problemCached;
summary.problemNoCache = problemNoCache;
summary.buildCachedSeconds = buildCachedSeconds;
summary.buildNoCacheSeconds = buildNoCacheSeconds;
summary.evalCachedSeconds = evalCachedSeconds;
summary.evalNoCacheSeconds = evalNoCacheSeconds;
summary.fitCachedSeconds = fitCachedSeconds;
summary.fitNoCacheSeconds = fitNoCacheSeconds;
summary.fitCached = fitCached;
summary.fitNoCache = fitNoCache;
summary.probeRmseDiff = probeRmseDiff;
assignin('base', 'MRLFEEtaSForwardCacheDiagnostic', summary);

fprintf('\nInterpretation notes:\n');
fprintf('  - The cached build may be slower because it precomputes the elastic reference once.\n');
fprintf('  - Cached objective evaluations should be faster if the internal elastic reference was previously recomputed each time.\n');
fprintf('  - Full-fit speedup depends on optimizer function count and the one-time cache build cost.\n');

function fitConfig = makeEtaSFitConfig(branchName, trueParams, initialEtaS, etaSBounds, disableCache)
fitConfig = struct();
fitConfig.branchName = branchName;
fitConfig.freeParams = "etaS";
fitConfig.fixedParams = struct( ...
    'mu', trueParams.mu, ...
    'thickness', trueParams.thickness, ...
    'rho', trueParams.rho, ...
    'nu', trueParams.nu);
fitConfig.initialGuess = struct('etaS', initialEtaS);
fitConfig.bounds = struct('etaS', etaSBounds);
fitConfig.solverOptions = mrlfeDefaultSweepOptions(branchName, 'EtaS', initialEtaS);
fitConfig.solverOptions.mrlfeDisableForwardCache = disableCache;
fitConfig.fitOptions = struct('useStandardErrorWeights', false, ...
    'optimizerOptions', optimset('Display', 'off', 'MaxIter', 35, 'MaxFunEvals', 80, 'TolX', 1e-5));
end

function t = getSolverElapsedSeconds(rawResult)
t = NaN;
try
    if isfield(rawResult, 'rawFullResult') && isfield(rawResult.rawFullResult, 'models') && ...
            isfield(rawResult.rawFullResult.models, 'mRLFERealK') && ...
            isfield(rawResult.rawFullResult.models.mRLFERealK, 'diagnostics')
        t = rawResult.rawFullResult.models.mRLFERealK.diagnostics.elapsedSeconds;
    end
catch
    t = NaN;
end
end
