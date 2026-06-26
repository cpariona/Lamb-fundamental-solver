% Diagnose a direct viscous mRLFE Cp-atlas prototype against the maintained solver.
% Diagnostic only: does not replace the maintained solver by default.
%
% This compares:
%   A. maintained viscous real-k forward solve without fitting cache;
%   B. maintained viscous real-k forward solve with cached elastic reference;
%   C. direct viscous Cp-atlas evaluator seeded only by the Rayleigh-Lamb branch.

clear; clc;
startup

branchName = "A0Like";
etaS = 0.12;
frequency_Hz = linspace(1000, 8000, 10).';

params = mrlfeDefaultSweepParams();
params.mu = 75e3;
params.thickness = 0.50e-3;
params.rho = 1070;
params.nu = 0.4999;
params.etaS = etaS;

fprintf('\n=== mRLFE direct viscous atlas diagnostic ===\n');
fprintf('Branch: %s | etaS = %.4g Pa*s\n', branchName, etaS);
fprintf('Frequencies: %.0f to %.0f Hz | requested points = %d\n', min(frequency_Hz), max(frequency_Hz), numel(frequency_Hz));

%% A. Maintained forward solve without explicit fitting cache.
optionsNoCache = mrlfeDefaultSweepOptions(branchName, 'EtaS', etaS);
optionsNoCache.mrlfeDisableForwardCache = true;

tNoCache = tic;
[CpNoCache, rawNoCache] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, optionsNoCache);
timeNoCache = toc(tNoCache);

%% B. Maintained forward solve with elastic reference cache through fitting problem.
experimentalDummy = struct();
experimentalDummy.frequency_Hz = frequency_Hz;
experimentalDummy.Cp_mps = CpNoCache;
experimentalDummy.validMask = isfinite(CpNoCache(:));
fitConfigCached = struct();
fitConfigCached.branchName = branchName;
fitConfigCached.freeParams = "etaS";
fitConfigCached.fixedParams = struct('mu', params.mu, 'thickness', params.thickness, 'rho', params.rho, 'nu', params.nu);
fitConfigCached.initialGuess = struct('etaS', etaS);
fitConfigCached.bounds = struct('etaS', [0.0, 0.30]);
fitConfigCached.solverOptions = mrlfeDefaultSweepOptions(branchName, 'EtaS', etaS);
fitConfigCached.fitOptions = struct('useStandardErrorWeights', false);

tBuildCached = tic;
problemCached = mrlfeBuildFitProblem(experimentalDummy, fitConfigCached);
buildCachedSeconds = toc(tBuildCached);

tCachedEval = tic;
[CpCached, rawCached] = problemCached.evaluateModel(params);
timeCachedEval = toc(tCachedEval);

%% C. Direct viscous atlas through the fitting evaluator.
optionsAtlas = mrlfeDefaultSweepOptions(branchName, 'EtaS', etaS);
optionsAtlas.mrlfeUseDirectViscoAtlas = true;
optionsAtlas.mrlfeViscoAtlasCpScanPoints = 900;
optionsAtlas.mrlfeViscoAtlasCandidates = 8;
optionsAtlas.mrlfeViscoAtlasCpWindow = [0.25, 3.00];
optionsAtlas.mrlfeViscoAtlasSeedWeight = 0.10;
optionsAtlas.mrlfeViscoAtlasResidualWeight = 0.45;
optionsAtlas.mrlfeViscoAtlasJumpWeight = 18.0;
optionsAtlas.mrlfeViscoAtlasCurvatureWeight = 12.0;
optionsAtlas.mrlfeViscoAtlasResidualTolerance = 1e-3;

tAtlas = tic;
[CpAtlas, rawAtlas] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, optionsAtlas);
timeAtlas = toc(tAtlas);
atlasBranch = rawAtlas.branch;

validAgainstNoCache = isfinite(CpNoCache(:)) & isfinite(CpAtlas(:));
rmseAtlasVsNoCache = sqrt(mean((CpAtlas(validAgainstNoCache) - CpNoCache(validAgainstNoCache)).^2, 'omitnan'));
maxAbsAtlasVsNoCache = max(abs(CpAtlas(validAgainstNoCache) - CpNoCache(validAgainstNoCache)), [], 'omitnan');
validFractionAtlas = nnz(isfinite(CpAtlas(:))) / numel(CpAtlas);
validFractionAtlasStrict = nnz(atlasBranch.validCp(:) & isfinite(CpAtlas(:))) / numel(CpAtlas);

validCached = isfinite(CpCached(:)) & isfinite(CpNoCache(:));
rmseCachedVsNoCache = sqrt(mean((CpCached(validCached) - CpNoCache(validCached)).^2, 'omitnan'));

fprintf('\nForward comparison:\n');
fprintf('  maintained no-cache time     = %.6g s | solver elapsed = %.6g s | valid = %d/%d\n', ...
    timeNoCache, getSolverElapsedSeconds(rawNoCache), nnz(isfinite(CpNoCache)), numel(CpNoCache));
fprintf('  cached build time            = %.6g s | cache enabled = %d\n', ...
    buildCachedSeconds, problemCached.forwardCache.enabled);
fprintf('  maintained cached eval time  = %.6g s | solver elapsed = %.6g s | valid = %d/%d\n', ...
    timeCachedEval, getSolverElapsedSeconds(rawCached), nnz(isfinite(CpCached)), numel(CpCached));
fprintf('  direct atlas eval time       = %.6g s | solver elapsed = %.6g s | valid finite = %d/%d | valid strict = %d/%d\n', ...
    timeAtlas, getSolverElapsedSeconds(rawAtlas), nnz(isfinite(CpAtlas)), numel(CpAtlas), nnz(atlasBranch.validCp(:) & isfinite(CpAtlas(:))), numel(CpAtlas));
fprintf('  direct atlas path            = %s\n', rawAtlas.evaluationPath.path);

fprintf('\nAccuracy against maintained no-cache forward solve:\n');
fprintf('  cached RMSE difference       = %.6g m/s\n', rmseCachedVsNoCache);
fprintf('  atlas RMSE difference        = %.6g m/s\n', rmseAtlasVsNoCache);
fprintf('  atlas max abs difference     = %.6g m/s\n', maxAbsAtlasVsNoCache);
fprintf('  atlas valid fraction finite  = %.6g\n', validFractionAtlas);
fprintf('  atlas valid fraction strict  = %.6g\n', validFractionAtlasStrict);

fprintf('\nCp values [m/s]:\n');
T = table(frequency_Hz(:), CpNoCache(:), CpCached(:), CpAtlas(:), CpAtlas(:) - CpNoCache(:), ...
    'VariableNames', {'frequency_Hz','Cp_no_cache','Cp_cached','Cp_direct_atlas','atlas_minus_no_cache'});
disp(T);

summary = struct();
summary.params = params;
summary.branchName = branchName;
summary.frequency_Hz = frequency_Hz;
summary.CpNoCache = CpNoCache;
summary.CpCached = CpCached;
summary.CpAtlas = CpAtlas;
summary.rawNoCache = rawNoCache;
summary.rawCached = rawCached;
summary.rawAtlas = rawAtlas;
summary.atlasBranch = atlasBranch;
summary.problemCached = problemCached;
summary.timeNoCache = timeNoCache;
summary.buildCachedSeconds = buildCachedSeconds;
summary.timeCachedEval = timeCachedEval;
summary.timeAtlas = timeAtlas;
summary.rmseCachedVsNoCache = rmseCachedVsNoCache;
summary.rmseAtlasVsNoCache = rmseAtlasVsNoCache;
summary.maxAbsAtlasVsNoCache = maxAbsAtlasVsNoCache;
summary.validFractionAtlas = validFractionAtlas;
summary.validFractionAtlasStrict = validFractionAtlasStrict;
assignin('base', 'MRLFEViscoDirectAtlasDiagnostic', summary);

fprintf('\nInterpretation notes:\n');
fprintf('  - The direct atlas does not precompute an etaS=0 mRLFE reference.\n');
fprintf('  - It still uses the Rayleigh-Lamb seed branch to identify the modal family and Cp scan window.\n');
fprintf('  - A useful prototype should be faster than the maintained path and close in Cp.\n');
fprintf('  - If it is fast but inaccurate, tune Cp window/candidate weights before integration.\n');
fprintf('  - If it is accurate but slow, reduce cpScanPoints or add coarse-to-fine refinement.\n');

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
