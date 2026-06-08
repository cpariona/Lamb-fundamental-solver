% Compare mRLFE tracker with brute-force residual/condition peaks.
% This script is diagnostic only. It does not change the solver.
%
% Purpose:
%   1) Verify that the current mRLFE tracker lies on a true local residual
%      minimum of the mRLFE matrix.
%   2) Show why global-minimum tracking is unsafe when a low-Cp valley
%      dominates the residual landscape.
%   3) Quantify continuity of the tracked branch.
%   4) Compare the cost of the current tracker with brute-force scanning.
%
% Recommended use:
%   Run from the repository root after startup, or just run this script
%   directly; it calls startup() internally.

clear; clc; close all;
startup();

fprintf('\n=== mRLFE tracker vs brute-force residual/condition scan ===\n');

%% Configuration
branchName = "A0Like";              % "A0Like" or "S0Like"
modelName  = "mRLFEElasticRealK";   % "mRLFEElasticRealK" or "mRLFEHanViscoRealK"

frequencyList = [500 1000 3000 5000 7000 9000 12000 16000];

% Brute-force scan range in phase velocity.
% CpMin = 0.25 intentionally exposes low-Cp residual valleys if they exist.
CpMin = 0.25;
CpMax = 80.0;
numCpScan = 5000;

% Use a representative soft-material case.
params = defaultParams();
params.modelType = "YoungPoissonFixedCL";
params.E = 100e3;          % Pa
params.nu = 0.4999;
params.CL = 1500;          % m/s
params.rho = 1050;         % kg/m^3
params.thickness = 0.5e-3; % m
params.fmin = 500;
params.fmax = 16000;
params.numFrequencyPoints = 120;
params.frequencySpacing = "hybrid";

options = defaultOptions("Balanced");
options.computeA0 = branchName == "A0Like";
options.computeS0 = branchName == "S0Like";
options.computeMRLFERealK = true;
options.computeMRLFEHanViscoRealK = modelName == "mRLFEHanViscoRealK";
options.computeMRLFEComplexK = false;
options.mrlfeComputeA0Like = branchName == "A0Like";
options.mrlfeComputeS0Like = branchName == "S0Like";

mrlfeParams = defaultMRLFEParams();
mrlfeParams.fluidDensity = 1000;
mrlfeParams.fluidSoundSpeed = 1500;
mrlfeParams.etaS = 0.05; % used only for mRLFEHanViscoRealK
mrlfeParams.etaL = 0;
mrlfeParams.useComplexLambda = false;
options.mrlfeParams = mrlfeParams;

fprintf('Model: %s | Branch: %s\n', modelName, branchName);
fprintf('E = %.4g kPa | thickness = %.4g mm | nu = %.5f\n', ...
    params.E/1e3, params.thickness*1e3, params.nu);
fprintf('Cp scan: %.3g to %.3g m/s | points = %d\n', CpMin, CpMax, numCpScan);

%% Current solver
solverTimer = tic;
results = computeFundamentalLambModes(params, options);
solverSeconds = toc(solverTimer);

if ~isfield(results.models, modelName)
    error('Requested model "%s" was not found in results.models.', modelName);
end
if ~isfield(results.models.(modelName).branches, branchName)
    error('Requested branch "%s" was not found in results.models.%s.branches.', branchName, modelName);
end

branch = results.models.(modelName).branches.(branchName);
validMask = getValidMask(branch);
validCp = branch.Cp(validMask);
validFrequency = branch.frequency(validMask);

if isempty(validCp)
    error('The requested branch has no valid Cp points.');
end

continuity = computeContinuityMetrics(validFrequency, validCp);

%% Brute-force residual/condition scan at selected frequencies
frequencyList = frequencyList(:).';
frequencyList = frequencyList(frequencyList >= min(branch.frequency) & frequencyList <= max(branch.frequency));
if isempty(frequencyList)
    error('frequencyList does not overlap with the computed branch frequency range.');
end

CpGrid = linspace(CpMin, CpMax, numCpScan);
scanRows = table();
scanProfiles = struct([]);

for i = 1:numel(frequencyList)
    f0 = frequencyList(i);
    [~, idx] = min(abs(branch.frequency - f0));
    f = branch.frequency(idx);
    omega = 2*pi*f;
    solverCp = branch.Cp(idx);

    scanTimer = tic;
    residual = nan(size(CpGrid));
    for j = 1:numel(CpGrid)
        Cp = CpGrid(j);
        k = omega / Cp;
        residual(j) = mrlfeResidual(k, omega, results.material, results.geometry, options.mrlfeParams);
    end
    bruteSeconds = toc(scanTimer);

    localMask = isLocalMinimum(residual);
    localCp = CpGrid(localMask);
    localResidual = residual(localMask);

    [globalMinResidual, globalIdx] = min(residual);
    globalMinCp = CpGrid(globalIdx);

    if isempty(localCp) || ~isfinite(solverCp)
        nearestLocalCp = nan;
        nearestLocalResidual = nan;
        cpDifference = nan;
        relativeCpDifference = nan;
    else
        [~, nearestIdx] = min(abs(localCp - solverCp));
        nearestLocalCp = localCp(nearestIdx);
        nearestLocalResidual = localResidual(nearestIdx);
        cpDifference = abs(solverCp - nearestLocalCp);
        relativeCpDifference = cpDifference / max(abs(solverCp), eps);
    end

    globalToSolverRelativeError = abs(globalMinCp - solverCp) / max(abs(solverCp), eps);
    globalMatchesSolver = globalToSolverRelativeError < 0.02;

    newRow = table(f, solverCp, nearestLocalCp, cpDifference, relativeCpDifference, ...
        globalMinCp, globalMinResidual, nearestLocalResidual, sum(localMask), ...
        globalMatchesSolver, bruteSeconds, ...
        'VariableNames', {'Frequency_Hz','SolverCp','NearestLocalMinCp', ...
        'AbsCpDifference','RelativeCpDifference','GlobalMinCp', ...
        'GlobalMinResidual','NearestLocalMinResidual','NumLocalMinima', ...
        'GlobalMinMatchesTracker','BruteForceSeconds'});

    scanRows = [scanRows; newRow]; %#ok<AGROW>

    scanProfiles(i).frequency = f; %#ok<SAGROW>
    scanProfiles(i).CpGrid = CpGrid;
    scanProfiles(i).residual = residual;
    scanProfiles(i).localCp = localCp;
    scanProfiles(i).localResidual = localResidual;
    scanProfiles(i).solverCp = solverCp;
    scanProfiles(i).nearestLocalCp = nearestLocalCp;
    scanProfiles(i).globalMinCp = globalMinCp;
end

%% Aggregate summary
validScan = isfinite(scanRows.AbsCpDifference);
if any(validScan)
    maxAbsTrackerLocalDifference = max(scanRows.AbsCpDifference(validScan));
    medianAbsTrackerLocalDifference = median(scanRows.AbsCpDifference(validScan));
    maxRelativeTrackerLocalDifference = max(scanRows.RelativeCpDifference(validScan));
else
    maxAbsTrackerLocalDifference = nan;
    medianAbsTrackerLocalDifference = nan;
    maxRelativeTrackerLocalDifference = nan;
end

globalMismatchCount = sum(~scanRows.GlobalMinMatchesTracker);
globalMismatchFraction = globalMismatchCount / height(scanRows);

meanBruteSeconds = mean(scanRows.BruteForceSeconds, 'omitnan');
estimatedBruteForceFullBranchSeconds = meanBruteSeconds * numel(branch.frequency);
speedupVsEstimatedBrute = estimatedBruteForceFullBranchSeconds / solverSeconds;

summary = table( ...
    solverSeconds, ...
    sum(validMask), ...
    numel(branch.frequency), ...
    continuity.NumSegments, ...
    continuity.MaxAbsCpJump, ...
    continuity.MaxRelativeCpJump, ...
    continuity.MedianRelativeCpJump, ...
    continuity.MaxCurvatureLikeChange, ...
    maxAbsTrackerLocalDifference, ...
    medianAbsTrackerLocalDifference, ...
    maxRelativeTrackerLocalDifference, ...
    globalMismatchCount, ...
    globalMismatchFraction, ...
    sum(scanRows.NumLocalMinima), ...
    sum(scanRows.BruteForceSeconds), ...
    estimatedBruteForceFullBranchSeconds, ...
    speedupVsEstimatedBrute, ...
    'VariableNames', {'SolverSeconds','ValidCpPoints','TotalBranchPoints', ...
    'NumValiditySegments','MaxAbsCpJump','MaxRelativeCpJump', ...
    'MedianRelativeCpJump','MaxCurvatureLikeChange', ...
    'MaxAbsTrackerLocalDifference','MedianAbsTrackerLocalDifference', ...
    'MaxRelativeTrackerLocalDifference','GlobalMismatchCount', ...
    'GlobalMismatchFraction','TotalLocalMinimaFound', ...
    'BruteForceSelectedSeconds','EstimatedBruteForceFullBranchSeconds', ...
    'EstimatedSpeedupVsBruteForce'});

%% Print report
disp(scanRows);
fprintf('\nContinuity metrics for tracked branch\n');
disp(summary(:, {'ValidCpPoints','TotalBranchPoints','NumValiditySegments', ...
    'MaxAbsCpJump','MaxRelativeCpJump','MedianRelativeCpJump','MaxCurvatureLikeChange'}));

fprintf('\nTracker-vs-local-minimum metrics\n');
disp(summary(:, {'MaxAbsTrackerLocalDifference','MedianAbsTrackerLocalDifference', ...
    'MaxRelativeTrackerLocalDifference','GlobalMismatchCount','GlobalMismatchFraction'}));

fprintf('\nTiming summary\n');
fprintf('  Current solver, full branch: %.3f s\n', solverSeconds);
fprintf('  Brute-force scan, %d selected frequencies only: %.3f s\n', ...
    height(scanRows), sum(scanRows.BruteForceSeconds));
fprintf('  Estimated brute-force time for all %d branch points: %.3f s\n', ...
    numel(branch.frequency), estimatedBruteForceFullBranchSeconds);
fprintf('  Estimated speedup of current solver vs full brute-force scan: %.2fx\n', ...
    speedupVsEstimatedBrute);

fprintf('\nInterpretation:\n');
fprintf('  - Small tracker-vs-nearest-local-minimum errors show the tracker follows a true local singular/residual minimum.\n');
fprintf('  - Global-minimum mismatches show why global-minimum or minimum-Cp tracking is unsafe.\n');
fprintf('  - Continuity metrics quantify whether the branch has artificial jumps.\n');
fprintf('  - Brute-force scanning is useful diagnostically, but expensive as a full solver.\n');

%% Figures
figure('Name','mRLFE tracker vs residual landscape','Color','w');
tiledlayout('flow');

for i = 1:numel(scanProfiles)
    nexttile;
    profile = scanProfiles(i);
    semilogy(profile.CpGrid, profile.residual, 'k-', 'LineWidth', 1.2);
    hold on;
    if ~isempty(profile.localCp)
        semilogy(profile.localCp, profile.localResidual, 'bo', 'MarkerSize', 4, ...
            'DisplayName','local minima');
    end
    xline(profile.solverCp, 'r-', 'LineWidth', 1.5, 'DisplayName','tracker Cp');
    if isfinite(profile.nearestLocalCp)
        xline(profile.nearestLocalCp, 'g--', 'LineWidth', 1.2, 'DisplayName','nearest local min');
    end
    xline(profile.globalMinCp, 'm:', 'LineWidth', 1.2, 'DisplayName','global min');
    grid on;
    xlabel('Cp [m/s]');
    ylabel('mRLFE residual');
    title(sprintf('f = %.0f Hz', profile.frequency));
end

figure('Name','Tracked branch continuity and local-min comparison','Color','w');
plot(branch.frequency(validMask), branch.Cp(validMask), 'r-', 'LineWidth', 2, ...
    'DisplayName','tracker branch');
hold on;
scatter(scanRows.Frequency_Hz, scanRows.NearestLocalMinCp, 40, 'g', 'filled', ...
    'DisplayName','nearest local minima');
scatter(scanRows.Frequency_Hz, scanRows.GlobalMinCp, 30, 'm', 'filled', ...
    'DisplayName','global minima');
grid on;
xlabel('frequency [Hz]');
ylabel('Cp [m/s]');
title(sprintf('%s / %s continuity diagnostic', modelName, branchName), 'Interpreter','none');
legend('Location','best');

%% Export to base workspace
DiagnosticResults = struct();
DiagnosticResults.config.branchName = branchName;
DiagnosticResults.config.modelName = modelName;
DiagnosticResults.config.frequencyList = frequencyList;
DiagnosticResults.config.CpGrid = CpGrid;
DiagnosticResults.results = results;
DiagnosticResults.branch = branch;
DiagnosticResults.validMask = validMask;
DiagnosticResults.scanRows = scanRows;
DiagnosticResults.summary = summary;
DiagnosticResults.continuity = continuity;
DiagnosticResults.scanProfiles = scanProfiles;
assignin('base', 'MRLFETrackerDiagnosticResults', DiagnosticResults);

%% Local functions
function mask = getValidMask(branch)
if isfield(branch, 'validCp')
    mask = branch.validCp & isfinite(branch.Cp);
elseif isfield(branch, 'valid')
    mask = branch.valid & isfinite(branch.Cp);
else
    mask = isfinite(branch.Cp);
end
end

function tf = isLocalMinimum(y)
tf = false(size(y));
finiteMask = isfinite(y);
for ii = 2:numel(y)-1
    tf(ii) = finiteMask(ii-1) && finiteMask(ii) && finiteMask(ii+1) && ...
        y(ii) <= y(ii-1) && y(ii) <= y(ii+1) && ...
        (y(ii) < y(ii-1) || y(ii) < y(ii+1));
end
end

function metrics = computeContinuityMetrics(frequency, Cp)
frequency = frequency(:);
Cp = Cp(:);

valid = isfinite(frequency) & isfinite(Cp);
frequency = frequency(valid);
Cp = Cp(valid);

metrics = struct();
metrics.NumPoints = numel(Cp);

if numel(Cp) < 2
    metrics.NumSegments = double(numel(Cp) > 0);
    metrics.MaxAbsCpJump = 0;
    metrics.MaxRelativeCpJump = 0;
    metrics.MedianRelativeCpJump = 0;
    metrics.MaxCurvatureLikeChange = 0;
    return;
end

dCp = diff(Cp);
relativeJump = abs(dCp) ./ max(abs(Cp(1:end-1)), eps);

% A conservative segment counter based on finite continuity only. Since this
% function receives only finite valid points, gaps are detected from frequency
% spacing jumps larger than three times the median step.
df = diff(frequency);
if isempty(df) || median(df) == 0
    gapMask = false(size(df));
else
    gapMask = df > 3 * median(df);
end

metrics.NumSegments = 1 + sum(gapMask);
metrics.MaxAbsCpJump = max(abs(dCp));
metrics.MaxRelativeCpJump = max(relativeJump);
metrics.MedianRelativeCpJump = median(relativeJump);

if numel(Cp) >= 3
    secondDifference = diff(Cp, 2);
    normalization = max(abs(Cp(2:end-1)), eps);
    metrics.MaxCurvatureLikeChange = max(abs(secondDifference) ./ normalization);
else
    metrics.MaxCurvatureLikeChange = 0;
end
end
