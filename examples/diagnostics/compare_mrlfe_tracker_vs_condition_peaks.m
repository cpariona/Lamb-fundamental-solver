% Compare mRLFE tracker with brute-force residual/condition peaks.
% This script is diagnostic only. It does not change the solver.
%
% Purpose
% -------
% 1) Check whether the tracked mRLFE branch is continuous.
% 2) Compare the tracker solution against the residual landscape.
% 3) Show why global-minimum / minimum-Cp tracking is unsafe.
% 4) Provide timing evidence that dense brute-force scanning is mainly
%    diagnostic, not the preferred full-branch solver.
%
% Recommended use
% ---------------
% Run from the repository root:
%
%   clear; clc; close all;
%   startup
%   examples/diagnostics/compare_mrlfe_tracker_vs_condition_peaks
%
% You can change branchName/modelName/frequencyList near the top.

clear; clc; close all;
startup();

fprintf('\n=== mRLFE tracker vs brute-force residual/condition scan ===\n');

%% User-facing diagnostic settings
branchName = "A0Like";              % "A0Like" or "S0Like"
modelName  = "mRLFEElasticRealK";   % "mRLFEElasticRealK" or "mRLFEHanViscoRealK"

% Frequencies selected for expensive brute-force residual scans.
% These do not need to include every solver frequency.
frequencyList = [500 1000 3000 5000 7000 9000 12000 16000];

% Cp scan range for brute-force landscape visualization.
CpMin = 0.25;
CpMax = 80;
numCpScanPoints = 5000;

% Modal-window comparison around the solver solution.
% This is intentionally local: it asks whether the solver lies near a
% residual valley in its own modal neighborhood, instead of asking whether a
% crude global discrete local-min detector found the same point.
modalWindowRelativeHalfWidth = 0.15;      % +/-15% around solver Cp
modalWindowMinHalfWidthAbs = 0.15;        % at least +/-0.15 m/s

% Global-min mismatch tolerance. If the global minimum is outside this
% relative distance from the solver, it is counted as a mismatch.
globalMatchRelativeTolerance = 0.03;      % 3%

% Material/geometry defaults for the diagnostic case.
params = defaultParams();
params.modelType = "YoungPoissonFixedCL";
params.E = 100e3;
params.nu = 0.4999;
params.rho = 1050;
params.CL = 1500;
params.thickness = 0.5e-3;
params.fmin = 500;
params.fmax = 16000;
params.numFrequencyPoints = 120;
params.frequencySpacing = "linear";

options = defaultOptions("Balanced");
options.computeA0 = branchName == "A0Like";
options.computeS0 = branchName == "S0Like";
options.computeMRLFERealK = true;
options.computeMRLFEHanViscoRealK = modelName == "mRLFEHanViscoRealK";
options.computeMRLFEComplexK = false;
options.mrlfeComputeA0Like = branchName == "A0Like";
options.mrlfeComputeS0Like = branchName == "S0Like";
options.mrlfeParams = defaultMRLFEParams();
options.mrlfeParams.fluidDensity = 1000;
options.mrlfeParams.fluidSoundSpeed = 1500;
options.mrlfeParams.etaS = 0.05;  % only relevant if modelName is viscoelastic

fprintf('Model: %s | Branch: %s\n', modelName, branchName);
fprintf('E = %.4g kPa | thickness = %.4g mm | nu = %.5f\n', ...
    params.E/1e3, params.thickness*1e3, params.nu);
fprintf('Cp scan: %.4g to %.4g m/s | points = %d\n', CpMin, CpMax, numCpScanPoints);
fprintf('Modal local window: solver Cp +/- %.1f%%, minimum half-width %.3g m/s\n', ...
    100*modalWindowRelativeHalfWidth, modalWindowMinHalfWidthAbs);

%% Compute current tracked branch
solverTimer = tic;
results = computeFundamentalLambModes(params, options);
solverSeconds = toc(solverTimer);

if ~isfield(results.models, modelName)
    error('Requested model %s was not computed.', modelName);
end
if ~isfield(results.models.(modelName).branches, branchName)
    error('Requested branch %s was not computed in %s.', branchName, modelName);
end

branch = results.models.(modelName).branches.(branchName);
validMask = getValidMask(branch);
frequency = branch.frequency(:);
solverCp = branch.Cp(:);

%% Continuity metrics for full tracked branch
continuity = computeContinuityMetrics(frequency, solverCp, validMask);

%% Brute-force residual scan at selected frequencies
CpGrid = linspace(CpMin, CpMax, numCpScanPoints);
frequencyList = frequencyList(:);
nFreq = numel(frequencyList);

rows = struct([]);
fig = figure('Name', 'mRLFE tracker vs residual landscape', 'Color', 'w');
tiledlayout(fig, nFreq, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

for i = 1:nFreq
    fTarget = frequencyList(i);
    [~, idx] = min(abs(frequency - fTarget));
    f = frequency(idx);
    omega = 2*pi*f;
    cpSolver = solverCp(idx);

    scanTimer = tic;
    residual = scanResidualVsCp(CpGrid, omega, results.material, results.geometry, options.mrlfeParams);
    bruteSeconds = toc(scanTimer);

    finiteMask = isfinite(residual);
    [globalResidual, globalIdx] = min(residual(finiteMask));
    finiteIndices = find(finiteMask);
    globalIdx = finiteIndices(globalIdx);
    globalCp = CpGrid(globalIdx);

    localMask = isLocalMinimum(residual);
    localIdx = find(localMask);
    localCp = CpGrid(localIdx);
    localResidual = residual(localIdx);

    [nearestLocalCp, nearestLocalResidual, nearestLocalAbsDiff, nearestLocalRelDiff] = ...
        nearestCandidate(localCp, localResidual, cpSolver);

    [modalBestCp, modalBestResidual, modalAbsDiff, modalRelDiff, modalNumPoints] = ...
        bestResidualNearSolver(CpGrid, residual, cpSolver, modalWindowRelativeHalfWidth, modalWindowMinHalfWidthAbs);

    globalRelDiff = abs(globalCp - cpSolver) / max(abs(cpSolver), eps);
    globalMatchesTracker = globalRelDiff <= globalMatchRelativeTolerance;

    rows(i).Frequency_Hz = f;
    rows(i).SolverCp = cpSolver;
    rows(i).NearestDiscreteLocalMinCp = nearestLocalCp;
    rows(i).AbsDiffToDiscreteLocalMin = nearestLocalAbsDiff;
    rows(i).RelDiffToDiscreteLocalMin = nearestLocalRelDiff;
    rows(i).ModalWindowBestCp = modalBestCp;
    rows(i).AbsDiffToModalWindowBest = modalAbsDiff;
    rows(i).RelDiffToModalWindowBest = modalRelDiff;
    rows(i).GlobalMinCp = globalCp;
    rows(i).GlobalMinResidual = globalResidual;
    rows(i).NearestDiscreteLocalMinResidual = nearestLocalResidual;
    rows(i).ModalWindowBestResidual = modalBestResidual;
    rows(i).NumDiscreteLocalMinima = numel(localIdx);
    rows(i).ModalWindowNumPoints = modalNumPoints;
    rows(i).GlobalMinMatchesTracker = globalMatchesTracker;
    rows(i).BruteForceSeconds = bruteSeconds;

    nexttile;
    semilogy(CpGrid, residual, 'k-', 'LineWidth', 1.0); hold on;
    if ~isempty(localIdx)
        semilogy(localCp, localResidual, 'bo', 'MarkerSize', 4, 'DisplayName', 'discrete local minima');
    end
    xline(cpSolver, 'r-', 'LineWidth', 1.5, 'DisplayName', 'tracker Cp');
    if isfinite(nearestLocalCp)
        xline(nearestLocalCp, 'g--', 'LineWidth', 1.1, 'DisplayName', 'nearest discrete local min');
    end
    if isfinite(modalBestCp)
        xline(modalBestCp, 'm-.', 'LineWidth', 1.1, 'DisplayName', 'best residual near tracker');
    end
    xline(globalCp, 'c:', 'LineWidth', 1.1, 'DisplayName', 'global min');
    grid on;
    ylabel('residual');
    title(sprintf('f = %.0f Hz | tracker Cp = %.4g m/s | global Cp = %.4g m/s', ...
        f, cpSolver, globalCp));
    if i == nFreq
        xlabel('Cp [m/s]');
    end
    if i == 1
        legend('Location', 'eastoutside');
    end
end

diagnosticTable = struct2table(rows);
disp(diagnosticTable);

%% Aggregated metrics
finiteDiscrete = isfinite(diagnosticTable.AbsDiffToDiscreteLocalMin);
finiteModal = isfinite(diagnosticTable.AbsDiffToModalWindowBest);

discreteSummary = table();
discreteSummary.MaxAbsDiffToDiscreteLocalMin = maxOrNaN(diagnosticTable.AbsDiffToDiscreteLocalMin(finiteDiscrete));
discreteSummary.MedianAbsDiffToDiscreteLocalMin = medianOrNaN(diagnosticTable.AbsDiffToDiscreteLocalMin(finiteDiscrete));
discreteSummary.MaxRelDiffToDiscreteLocalMin = maxOrNaN(diagnosticTable.RelDiffToDiscreteLocalMin(finiteDiscrete));
discreteSummary.MedianRelDiffToDiscreteLocalMin = medianOrNaN(diagnosticTable.RelDiffToDiscreteLocalMin(finiteDiscrete));
discreteSummary.MissingDiscreteLocalMinCount = sum(~finiteDiscrete);

modalSummary = table();
modalSummary.MaxAbsDiffToModalWindowBest = maxOrNaN(diagnosticTable.AbsDiffToModalWindowBest(finiteModal));
modalSummary.MedianAbsDiffToModalWindowBest = medianOrNaN(diagnosticTable.AbsDiffToModalWindowBest(finiteModal));
modalSummary.MaxRelDiffToModalWindowBest = maxOrNaN(diagnosticTable.RelDiffToModalWindowBest(finiteModal));
modalSummary.MedianRelDiffToModalWindowBest = medianOrNaN(diagnosticTable.RelDiffToModalWindowBest(finiteModal));
modalSummary.MissingModalWindowCount = sum(~finiteModal);

globalSummary = table();
globalSummary.GlobalMismatchCount = sum(~diagnosticTable.GlobalMinMatchesTracker);
globalSummary.GlobalMismatchFraction = mean(~diagnosticTable.GlobalMinMatchesTracker);

continuityTable = struct2table(continuity);

bruteSelectedSeconds = sum(diagnosticTable.BruteForceSeconds);
estimatedBruteFullSeconds = mean(diagnosticTable.BruteForceSeconds) * numel(frequency);
speedupVsBrute = estimatedBruteFullSeconds / solverSeconds;

timingSummary = table();
timingSummary.CurrentSolverFullBranchSeconds = solverSeconds;
timingSummary.BruteForceSelectedSeconds = bruteSelectedSeconds;
timingSummary.EstimatedBruteForceFullBranchSeconds = estimatedBruteFullSeconds;
timingSummary.EstimatedSpeedupVsBruteForce = speedupVsBrute;

fprintf('\nContinuity metrics for tracked branch\n');
disp(continuityTable);

fprintf('\nDiscrete local-minimum diagnostics\n');
disp(discreteSummary);

fprintf('\nModal-window diagnostics around tracker Cp\n');
disp(modalSummary);

fprintf('\nGlobal-minimum mismatch diagnostics\n');
disp(globalSummary);

fprintf('\nTiming summary\n');
disp(timingSummary);

fprintf('\nInterpretation:\n');
fprintf('  - Continuity metrics quantify whether the tracked branch has artificial jumps.\n');
fprintf('  - Global-minimum mismatches show why global-minimum or minimum-Cp tracking is unsafe.\n');
fprintf('  - Discrete local-minimum diagnostics depend on scan resolution and can miss shallow/narrow minima.\n');
fprintf('  - Modal-window diagnostics ask a fairer question: is the tracker near a residual valley in its own modal neighborhood?\n');
fprintf('  - Brute-force scanning is useful diagnostically, but expensive as a full solver.\n');

MRLFETrackerDiagnosticResults = struct();
MRLFETrackerDiagnosticResults.params = params;
MRLFETrackerDiagnosticResults.options = options;
MRLFETrackerDiagnosticResults.modelName = modelName;
MRLFETrackerDiagnosticResults.branchName = branchName;
MRLFETrackerDiagnosticResults.table = diagnosticTable;
MRLFETrackerDiagnosticResults.continuity = continuityTable;
MRLFETrackerDiagnosticResults.discreteLocalMinimumSummary = discreteSummary;
MRLFETrackerDiagnosticResults.modalWindowSummary = modalSummary;
MRLFETrackerDiagnosticResults.globalMinimumSummary = globalSummary;
MRLFETrackerDiagnosticResults.timing = timingSummary;
assignin('base', 'MRLFETrackerDiagnosticResults', MRLFETrackerDiagnosticResults);

%% Local functions
function residual = scanResidualVsCp(CpGrid, omega, material, geometry, mrlfeParams)
    residual = nan(size(CpGrid));
    for j = 1:numel(CpGrid)
        cp = CpGrid(j);
        if ~(isfinite(cp) && cp > 0)
            continue;
        end
        k = omega / cp;
        residual(j) = mrlfeResidual(k, omega, material, geometry, mrlfeParams);
    end
end

function [cp, r, absDiff, relDiff] = nearestCandidate(candidateCp, candidateResidual, targetCp)
    cp = nan; r = nan; absDiff = nan; relDiff = nan;
    if isempty(candidateCp) || ~isfinite(targetCp)
        return;
    end
    [absDiff, idx] = min(abs(candidateCp - targetCp));
    cp = candidateCp(idx);
    r = candidateResidual(idx);
    relDiff = absDiff / max(abs(targetCp), eps);
end

function [bestCp, bestResidual, absDiff, relDiff, nPoints] = bestResidualNearSolver(CpGrid, residual, solverCp, relHalfWidth, minHalfWidthAbs)
    bestCp = nan; bestResidual = nan; absDiff = nan; relDiff = nan; nPoints = 0;
    if ~isfinite(solverCp)
        return;
    end
    halfWidth = max(abs(solverCp) * relHalfWidth, minHalfWidthAbs);
    mask = CpGrid >= (solverCp - halfWidth) & CpGrid <= (solverCp + halfWidth) & isfinite(residual);
    nPoints = sum(mask);
    if nPoints < 1
        return;
    end
    idxAll = find(mask);
    [bestResidual, localIdx] = min(residual(mask));
    idx = idxAll(localIdx);
    bestCp = CpGrid(idx);
    absDiff = abs(bestCp - solverCp);
    relDiff = absDiff / max(abs(solverCp), eps);
end

function continuity = computeContinuityMetrics(frequency, cp, validMask)
    validMask = validMask(:) & isfinite(cp(:));
    cpValid = cp(validMask);
    frequencyValid = frequency(validMask);

    continuity = struct();
    continuity.ValidCpPoints = numel(cpValid);
    continuity.TotalBranchPoints = numel(cp);
    continuity.NumValiditySegments = countSegments(validMask);

    if numel(cpValid) < 2
        continuity.MaxAbsCpJump = nan;
        continuity.MaxRelativeCpJump = nan;
        continuity.MedianRelativeCpJump = nan;
        continuity.MaxCurvatureLikeChange = nan;
        return;
    end

    absJump = abs(diff(cpValid));
    relJump = absJump ./ max(abs(cpValid(1:end-1)), eps);
    continuity.MaxAbsCpJump = max(absJump);
    continuity.MaxRelativeCpJump = max(relJump);
    continuity.MedianRelativeCpJump = median(relJump);

    if numel(cpValid) < 3
        continuity.MaxCurvatureLikeChange = nan;
    else
        df = diff(frequencyValid);
        slope = diff(cpValid) ./ max(df, eps);
        slopeScale = max(abs(slope(1:end-1)), max(abs(slope(2:end)), eps));
        curvatureLike = abs(diff(slope)) ./ slopeScale;
        continuity.MaxCurvatureLikeChange = max(curvatureLike);
    end
end

function nSegments = countSegments(mask)
    mask = logical(mask(:));
    if isempty(mask)
        nSegments = 0;
        return;
    end
    starts = mask & [true; ~mask(1:end-1)];
    nSegments = sum(starts);
end

function mask = getValidMask(branch)
    if isfield(branch, 'validCp')
        mask = branch.validCp;
    elseif isfield(branch, 'valid')
        mask = branch.valid;
    else
        mask = isfinite(branch.Cp);
    end
    mask = mask(:) & isfinite(branch.Cp(:));
end

function mask = isLocalMinimum(y)
    y = y(:).';
    mask = false(size(y));
    finiteMask = isfinite(y);
    for i = 2:numel(y)-1
        if finiteMask(i-1) && finiteMask(i) && finiteMask(i+1)
            mask(i) = y(i) <= y(i-1) && y(i) <= y(i+1) && ...
                (y(i) < y(i-1) || y(i) < y(i+1));
        end
    end
end

function value = maxOrNaN(x)
    if isempty(x)
        value = nan;
    else
        value = max(x);
    end
end

function value = medianOrNaN(x)
    if isempty(x)
        value = nan;
    else
        value = median(x);
    end
end
