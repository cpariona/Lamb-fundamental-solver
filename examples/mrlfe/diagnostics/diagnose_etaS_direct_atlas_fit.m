% Compare etaS fitting with maintained and direct viscous atlas mRLFE evaluators.
% Diagnostic only: this does not make the atlas path the default.

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

fprintf('\n=== mRLFE etaS direct-atlas fit diagnostic ===\n');
fprintf('Branch: %s | true etaS = %.4g Pa*s | initial etaS = %.4g Pa*s\n', branchName, trueEtaS, initialEtaS);
fprintf('Frequencies: %.0f to %.0f Hz | requested points = %d\n', min(frequency_Hz), max(frequency_Hz), numel(frequency_Hz));

% Use maintained no-cache forward data as the synthetic reference target.
syntheticOptions = mrlfeDefaultSweepOptions(branchName, 'EtaS', trueEtaS);
syntheticOptions.mrlfeDisableForwardCache = true;
tSynthetic = tic;
[CpSynthetic_mps, rawSynthetic] = mrlfeEvaluateFitModel(trueParams, frequency_Hz, branchName, syntheticOptions);
syntheticSeconds = toc(tSynthetic);
validSynthetic = isfinite(CpSynthetic_mps(:));
assert(any(validSynthetic), 'Synthetic etaS data must contain finite Cp points.');

experimental = struct();
experimental.frequency_Hz = frequency_Hz;
experimental.Cp_mps = CpSynthetic_mps;
experimental.validMask = validSynthetic;

fprintf('Synthetic generation time = %.6g s | solver elapsed = %.6g s | valid = %d/%d\n', ...
    syntheticSeconds, getSolverElapsedSeconds(rawSynthetic), nnz(validSynthetic), numel(validSynthetic));

fitConfigNoCache = makeEtaSFitConfig(branchName, trueParams, initialEtaS, etaSBounds, "maintained_no_cache");
fitConfigCached = makeEtaSFitConfig(branchName, trueParams, initialEtaS, etaSBounds, "maintained_cached");
fitConfigAtlas = makeEtaSFitConfig(branchName, trueParams, initialEtaS, etaSBounds, "direct_atlas");

[tNoCache, fitNoCache] = timeFit(experimental, fitConfigNoCache);
[tCached, fitCached] = timeFit(experimental, fitConfigCached);
[tAtlas, fitAtlas] = timeFit(experimental, fitConfigAtlas);

fprintf('\nFull etaS fit comparison:\n');
printFitLine('maintained no-cache', tNoCache, fitNoCache);
printFitLine('maintained cached',   tCached, fitCached);
printFitLine('direct atlas',        tAtlas, fitAtlas);
fprintf('  speedup atlas vs no-cache = %.6g x\n', tNoCache / tAtlas);
fprintf('  speedup atlas vs cached   = %.6g x\n', tCached / tAtlas);
fprintf('  etaS atlas - cached       = %.6g Pa*s\n', fitAtlas.bestParams.etaS - fitCached.bestParams.etaS);
fprintf('  etaS atlas - no-cache     = %.6g Pa*s\n', fitAtlas.bestParams.etaS - fitNoCache.bestParams.etaS);

validAtlasVsCached = isfinite(fitAtlas.Cp_fit_mps(:)) & isfinite(fitCached.Cp_fit_mps(:));
fitCpRmseAtlasVsCached = sqrt(mean((fitAtlas.Cp_fit_mps(validAtlasVsCached) - fitCached.Cp_fit_mps(validAtlasVsCached)).^2, 'omitnan'));
validAtlasVsNoCache = isfinite(fitAtlas.Cp_fit_mps(:)) & isfinite(fitNoCache.Cp_fit_mps(:));
fitCpRmseAtlasVsNoCache = sqrt(mean((fitAtlas.Cp_fit_mps(validAtlasVsNoCache) - fitNoCache.Cp_fit_mps(validAtlasVsNoCache)).^2, 'omitnan'));

fprintf('\nFitted Cp comparison:\n');
fprintf('  RMSE atlas vs cached fitted Cp   = %.6g m/s\n', fitCpRmseAtlasVsCached);
fprintf('  RMSE atlas vs no-cache fitted Cp = %.6g m/s\n', fitCpRmseAtlasVsNoCache);

fprintf('\nFit evaluation paths:\n');
fprintf('  no-cache final path = %s\n', fitNoCache.rawSolverResult.evaluationPath.path);
fprintf('  cached final path   = %s\n', fitCached.rawSolverResult.evaluationPath.path);
fprintf('  atlas final path    = %s\n', fitAtlas.rawSolverResult.evaluationPath.path);
fprintf('  atlas branch used elastic mRLFE reference = %d\n', fitAtlas.rawSolverResult.branch.viscoAtlas.usedElasticMRLFEReference);

T = table(frequency_Hz(:), experimental.Cp_mps(:), fitNoCache.Cp_fit_mps(:), fitCached.Cp_fit_mps(:), fitAtlas.Cp_fit_mps(:), ...
    fitAtlas.Cp_fit_mps(:) - fitNoCache.Cp_fit_mps(:), ...
    'VariableNames', {'frequency_Hz','Cp_synthetic','Cp_fit_no_cache','Cp_fit_cached','Cp_fit_atlas','atlas_minus_no_cache'});
fprintf('\nFitted Cp values [m/s]:\n');
disp(T);

summary = struct();
summary.frequency_Hz = frequency_Hz;
summary.experimental = experimental;
summary.fitNoCache = fitNoCache;
summary.fitCached = fitCached;
summary.fitAtlas = fitAtlas;
summary.tNoCache = tNoCache;
summary.tCached = tCached;
summary.tAtlas = tAtlas;
summary.syntheticSeconds = syntheticSeconds;
summary.rawSynthetic = rawSynthetic;
summary.fitCpRmseAtlasVsCached = fitCpRmseAtlasVsCached;
summary.fitCpRmseAtlasVsNoCache = fitCpRmseAtlasVsNoCache;
assignin('base', 'MRLFEEtaSDirectAtlasFitDiagnostic', summary);

fprintf('\nInterpretation notes:\n');
fprintf('  - The direct atlas fit uses the optional mrlfeUseDirectViscoAtlas evaluator path.\n');
fprintf('  - The maintained cached fit is exact relative to the maintained no-cache path.\n');
fprintf('  - The atlas fit is useful if it materially reduces fit time while preserving etaS and RMSE.\n');

function fitConfig = makeEtaSFitConfig(branchName, trueParams, initialEtaS, etaSBounds, mode)
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
fitConfig.fitOptions = struct('useStandardErrorWeights', false, ...
    'optimizerOptions', optimset('Display', 'off', 'MaxIter', 35, 'MaxFunEvals', 80, 'TolX', 1e-5));

switch string(mode)
    case "maintained_no_cache"
        fitConfig.solverOptions.mrlfeDisableForwardCache = true;
    case "maintained_cached"
        fitConfig.solverOptions.mrlfeDisableForwardCache = false;
    case "direct_atlas"
        fitConfig.solverOptions.mrlfeDisableForwardCache = true;
        fitConfig.solverOptions.mrlfeUseDirectViscoAtlas = true;
        fitConfig.solverOptions.mrlfeViscoAtlasCpScanPoints = 900;
        fitConfig.solverOptions.mrlfeViscoAtlasCandidates = 8;
        fitConfig.solverOptions.mrlfeViscoAtlasCpWindow = [0.25, 3.00];
        fitConfig.solverOptions.mrlfeViscoAtlasSeedWeight = 0.10;
        fitConfig.solverOptions.mrlfeViscoAtlasResidualWeight = 0.45;
        fitConfig.solverOptions.mrlfeViscoAtlasJumpWeight = 18.0;
        fitConfig.solverOptions.mrlfeViscoAtlasCurvatureWeight = 12.0;
        fitConfig.solverOptions.mrlfeViscoAtlasResidualTolerance = 1e-3;
    otherwise
        error('Unknown etaS fit diagnostic mode: %s.', mode);
end
end

function [elapsedSeconds, fitResult] = timeFit(experimental, fitConfig)
t = tic;
fitResult = mrlfeFitDispersionData(experimental, fitConfig);
elapsedSeconds = toc(t);
end

function printFitLine(label, elapsedSeconds, fitResult)
fprintf('  %-20s time = %.6g s | etaS = %.6g Pa*s | RMSE = %.6g m/s | funcCount = %g | path = %s\n', ...
    label, elapsedSeconds, fitResult.bestParams.etaS, fitResult.metrics.RMSE, ...
    fitResult.optimizer.output.funcCount, fitResult.rawSolverResult.evaluationPath.path);
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
