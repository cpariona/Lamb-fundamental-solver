% Diagnose mRLFE fitting timing and objective landscape cost.
% Diagnostic only: does not change solver internals.
%
% Purpose:
%   1) Measure one forward mRLFE fitting evaluation.
%   2) Measure a coarse one-parameter RMSE landscape.
%   3) Measure the current mRLFE fitting call.
%   4) Report where an atlas/cache strategy would save repeated work.

clear; clc;
startup

branchName = "A0Like";            % "A0Like" or "S0Like"
etaS = 0.0;                       % 0 for elastic real-k baseline; >0 for viscous real-k
trueMu = 75e3;
initialMu = 55e3;
muBounds = [30e3, 140e3];
muGrid = linspace(muBounds(1), muBounds(2), 17).';
frequency_Hz = linspace(1000, 8000, 10).';

paramsTrue = mrlfeDefaultSweepParams();
paramsTrue.mu = trueMu;
paramsTrue.thickness = 0.50e-3;
paramsTrue.rho = 1070;
paramsTrue.nu = 0.4999;
paramsTrue.etaS = etaS;

solverOptions = mrlfeDefaultSweepOptions(branchName, 'EtaS', etaS);
solverOptions.mrlfeUseInternalTrackingGrid = true;
solverOptions.mrlfeInternalTrackingMinPoints = 30;
solverOptions.mrlfeInternalTrackingPointFactor = 2;
solverOptions.mrlfeInternalTrackingMaxPoints = 80;

fprintf('\n=== mRLFE fitting timing diagnostic ===\n');
fprintf('Branch: %s | etaS = %.4g Pa*s\n', branchName, etaS);
fprintf('Frequencies: %.0f to %.0f Hz | requested points = %d\n', min(frequency_Hz), max(frequency_Hz), numel(frequency_Hz));
fprintf('mu bounds: %.3f to %.3f kPa | grid points = %d\n', muBounds(1)/1e3, muBounds(2)/1e3, numel(muGrid));

% Synthetic data generation is timed separately because current fitting workflows
% repeatedly call the same forward evaluator during optimization.
tSynthetic = tic;
[CpSynthetic_mps, rawSynthetic] = mrlfeEvaluateFitModel(paramsTrue, frequency_Hz, branchName, solverOptions);
timeSynthetic = toc(tSynthetic);
validSynthetic = isfinite(CpSynthetic_mps(:));
assert(any(validSynthetic), 'Synthetic mRLFE data generation produced no valid points.');

experimental = struct();
experimental.frequency_Hz = frequency_Hz;
experimental.Cp_mps = CpSynthetic_mps;
experimental.validMask = validSynthetic;

fprintf('\nSynthetic generation:\n');
fprintf('  time = %.6g s\n', timeSynthetic);
fprintf('  valid = %d/%d\n', nnz(validSynthetic), numel(validSynthetic));
printMrlfeRawTiming(rawSynthetic, '  ');

% Single forward evaluation at the initial guess.
paramsProbe = paramsTrue;
paramsProbe.mu = initialMu;
tForward = tic;
[CpProbe_mps, rawProbe] = mrlfeEvaluateFitModel(paramsProbe, frequency_Hz, branchName, solverOptions);
timeForward = toc(tForward);
residualProbe = CpProbe_mps(validSynthetic) - CpSynthetic_mps(validSynthetic);
rmseProbe = sqrt(mean(residualProbe.^2, 'omitnan'));

fprintf('\nSingle forward evaluation at initial mu %.3f kPa:\n', initialMu/1e3);
fprintf('  time = %.6g s\n', timeForward);
fprintf('  RMSE = %.6g m/s\n', rmseProbe);
fprintf('  valid = %d/%d\n', nnz(isfinite(CpProbe_mps)), numel(CpProbe_mps));
printMrlfeRawTiming(rawProbe, '  ');

% Coarse objective landscape.
rmse = nan(size(muGrid));
validFraction = nan(size(muGrid));
forwardSeconds = nan(size(muGrid));
trackingPoints = nan(size(muGrid));
solverSeconds = nan(size(muGrid));

for i = 1:numel(muGrid)
    params = paramsTrue;
    params.mu = muGrid(i);
    tEval = tic;
    [CpModel_mps, rawModel] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, solverOptions);
    forwardSeconds(i) = toc(tEval);

    valid = isfinite(CpModel_mps(:)) & validSynthetic(:);
    validFraction(i) = nnz(valid) / numel(valid);
    if any(valid)
        r = CpModel_mps(valid) - CpSynthetic_mps(valid);
        rmse(i) = sqrt(mean(r.^2, 'omitnan'));
    end
    trackingPoints(i) = getTrackingPointCount(rawModel);
    solverSeconds(i) = getSolverElapsedSeconds(rawModel);
end

[bestGridRmse, bestGridIdx] = min(rmse);
bestGridMu = muGrid(bestGridIdx);
landscapeTable = table(muGrid/1e3, rmse, validFraction, forwardSeconds, solverSeconds, trackingPoints, ...
    'VariableNames', {'mu_kPa','RMSE_mps','validFraction','forwardSeconds','solverSeconds','trackingPoints'});

fprintf('\nCoarse RMSE landscape:\n');
disp(landscapeTable);
fprintf('  best grid mu = %.6g kPa\n', bestGridMu/1e3);
fprintf('  best grid RMSE = %.6g m/s\n', bestGridRmse);
fprintf('  median forward time = %.6g s\n', median(forwardSeconds, 'omitnan'));
fprintf('  total landscape time = %.6g s\n', sum(forwardSeconds, 'omitnan'));

% Current optimizer timing.
fitConfig = struct();
fitConfig.branchName = branchName;
fitConfig.freeParams = "mu";
fitConfig.fixedParams = struct('thickness', paramsTrue.thickness, 'rho', paramsTrue.rho, 'nu', paramsTrue.nu, 'etaS', etaS);
fitConfig.initialGuess = struct('mu', initialMu);
fitConfig.bounds = struct('mu', muBounds);
fitConfig.solverOptions = solverOptions;
fitConfig.fitOptions = struct();
fitConfig.fitOptions.useStandardErrorWeights = false;
fitConfig.fitOptions.optimizerOptions = optimset('Display', 'off', 'MaxIter', 35, 'MaxFunEvals', 80, 'TolX', 1e-5);

tFit = tic;
fitResult = mrlfeFitDispersionData(experimental, fitConfig);
timeFit = toc(tFit);

fprintf('\nCurrent mRLFE fit:\n');
fprintf('  time = %.6g s\n', timeFit);
fprintf('  optimizer = %s\n', fitResult.optimizer.name);
fprintf('  iterations = %s\n', getOutputFieldAsText(fitResult.optimizer.output, 'iterations'));
fprintf('  funcCount = %s\n', getOutputFieldAsText(fitResult.optimizer.output, 'funcCount'));
fprintf('  best mu = %.6g kPa\n', fitResult.bestParams.mu/1e3);
fprintf('  RMSE = %.6g m/s\n', fitResult.metrics.RMSE);
printMrlfeRawTiming(fitResult.rawSolverResult, '  final ');

summary = struct();
summary.branchName = branchName;
summary.etaS = etaS;
summary.frequency_Hz = frequency_Hz;
summary.muGrid = muGrid;
summary.landscapeTable = landscapeTable;
summary.timeSynthetic = timeSynthetic;
summary.timeForwardInitial = timeForward;
summary.timeFit = timeFit;
summary.bestGridMu = bestGridMu;
summary.fitResult = fitResult;
summary.rawSynthetic = rawSynthetic;
summary.rawProbe = rawProbe;

assignin('base', 'MRLFEFitTimingDiagnostic', summary);

fprintf('\nInterpretation notes:\n');
fprintf('  - If fit time is roughly funcCount times one forward evaluation, optimization is dominated by repeated forward solves.\n');
fprintf('  - If solverSeconds is close to forwardSeconds, the mRLFE/RL branch solver dominates over MATLAB wrapper overhead.\n');
fprintf('  - If the coarse RMSE landscape is smooth, a coarse-global plus local refine or atlas/cache strategy is plausible.\n');
fprintf('  - For A0Like etaS=0, DP candidate extraction already behaves like a local Cp atlas per parameter value.\n');
fprintf('  - A useful next step is to cache/reuse parameter-independent pieces before building a full parameter atlas.\n');

function printMrlfeRawTiming(rawResult, prefix)
if nargin < 2
    prefix = '';
end
fprintf('%stracking points = %d\n', prefix, getTrackingPointCount(rawResult));
solverSeconds = getSolverElapsedSeconds(rawResult);
if isfinite(solverSeconds)
    fprintf('%ssolver diagnostics elapsedSeconds = %.6g s\n', prefix, solverSeconds);
else
    fprintf('%ssolver diagnostics elapsedSeconds = NaN\n', prefix);
end
if isfield(rawResult, 'rawFullResult') && isfield(rawResult.rawFullResult, 'models') && ...
        isfield(rawResult.rawFullResult.models, 'mRLFERealK') && ...
        isfield(rawResult.rawFullResult.models.mRLFERealK, 'diagnostics')
    disp(rawResult.rawFullResult.models.mRLFERealK.diagnostics.summary);
end
end

function n = getTrackingPointCount(rawResult)
n = NaN;
try
    if isfield(rawResult, 'rawFullResult') && isfield(rawResult.rawFullResult, 'models') && ...
            isfield(rawResult.rawFullResult.models, 'mRLFERealK') && ...
            isfield(rawResult.rawFullResult.models.mRLFERealK, 'diagnostics')
        n = rawResult.rawFullResult.models.mRLFERealK.diagnostics.trackingPointCount;
    elseif isfield(rawResult, 'branchSolve') && isfield(rawResult.branchSolve, 'frequency')
        n = numel(rawResult.branchSolve.frequency);
    end
catch
    n = NaN;
end
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

function text = getOutputFieldAsText(output, fieldName)
if isstruct(output) && isfield(output, fieldName)
    value = output.(fieldName);
    if isnumeric(value)
        text = sprintf('%.12g', value);
    else
        text = char(string(value));
    end
else
    text = 'n/a';
end
end
