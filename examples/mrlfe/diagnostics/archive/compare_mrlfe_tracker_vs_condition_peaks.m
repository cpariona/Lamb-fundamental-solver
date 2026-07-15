% Compare mRLFE tracker with brute-force residual/condition scans.
% Diagnostic only: does not change solver internals.
%
% Purpose:
%   1) Check whether the tracked branch is continuous.
%   2) Show why global-minimum or minimum-Cp tracking is unsafe.
%   3) Compare the tracked Cp with the residual landscape near the tracked mode.
%   4) Estimate the computational cost of brute-force scanning versus tracking.

startup();

branchName = "A0Like";              % "A0Like" or "S0Like"
modelName  = "mRLFEElasticRealK";   % "mRLFEElasticRealK" or "mRLFEViscoRealK"

params = rlDefaultParams();
params.E = 100e3;
params.nu = 0.4999;
params.CL = 1500;
params.rho = 1050;
params.thickness = 0.5e-3;
params.fmin = 500;
params.fmax = 16000;
params.numFrequencyPoints = 120;
params.frequencySpacing = "linspace";

options = rlDefaultOptions("Balanced");
options.computeA0 = branchName == "A0Like";
options.computeS0 = branchName == "S0Like";
options.computeMRLFERealK = true;
options.computeMRLFEViscoRealK = modelName == "mRLFEViscoRealK";
options.computeMRLFEComplexK = false;
options.mrlfeComputeA0Like = branchName == "A0Like";
options.mrlfeComputeS0Like = branchName == "S0Like";
options.mrlfeParams = defaultMRLFEParams();
options.mrlfeParams.fluidDensity = 1000;
options.mrlfeParams.fluidSoundSpeed = 1500;
options.mrlfeParams.etaS = 0.1;

CpMin = 0.25;
CpMax = 80;
CpScanPoints = 5000;
numPeaksToShow = 5;

% Tight local window around the tracker. This is intentionally narrower than
% the previous +/-15% modal window: here we are not searching for another
% branch, only checking the residual landscape in the immediate neighborhood
% of the tracked solution.
localWindowRelativeHalfWidth = 0.02;  % +/-2% around SolverCp
localWindowMinHalfWidthAbs = 0.05;    % at least +/-0.05 m/s
localWindowEdgeGuardPoints = 2;
globalMatchRelativeTol = 0.02;

fprintf('\n=== mRLFE tracker vs brute-force residual/condition scan ===\n');
fprintf('Model: %s | Branch: %s\n', modelName, branchName);
fprintf('E = %.3g kPa | thickness = %.3g mm | nu = %.5f\n', params.E/1e3, params.thickness*1e3, params.nu);
fprintf('Cp scan: %.3g to %.3g m/s | points = %d\n', CpMin, CpMax, CpScanPoints);
fprintf('Tight local window: solver Cp +/- %.1f%%, minimum half-width %.3g m/s\n', ...
    100*localWindowRelativeHalfWidth, localWindowMinHalfWidthAbs);

solverTimer = tic;
results = rlComputeFundamentalLambModes(params, options);
solverTime = toc(solverTimer);

branch = results.models.(modelName).branches.(branchName);
validMask = getValidMask(branch);
validIndex = find(validMask & isfinite(branch.Cp));
if isempty(validIndex)
    error('No valid Cp points were found for %s / %s.', modelName, branchName);
end

continuity = computeContinuityMetrics(branch, validIndex);

sampleIndex = round(linspace(validIndex(1), validIndex(end), min(8, numel(validIndex))));
if isfinite(continuity.MaxJumpIndexBefore)
    jumpNeighborhood = max(validIndex(1), continuity.MaxJumpIndexBefore-1):min(validIndex(end), continuity.MaxJumpIndexAfter+1);
    sampleIndex = unique([sampleIndex(:); jumpNeighborhood(:)]).';
end
sampleIndex = sampleIndex(isfinite(branch.Cp(sampleIndex)) & validMask(sampleIndex));

material = results.material;
geometry = results.geometry;
mrlfeParams = results.models.(modelName).parameters;
CpScan = linspace(CpMin, CpMax, CpScanPoints);

n = numel(sampleIndex);
freq = nan(n,1);
solverCp = nan(n,1);
solverResidual = nan(n,1);
globalMinCp = nan(n,1);
globalMinResidual = nan(n,1);
globalMinMatchesTracker = false(n,1);
nearestLocalCp = nan(n,1);
nearestLocalResidual = nan(n,1);
absDiffToLocal = nan(n,1);
relDiffToLocal = nan(n,1);
localWindowBestCp = nan(n,1);
localWindowBestResidual = nan(n,1);
localWindowBestAtEdge = false(n,1);
localWindowNumPoints = nan(n,1);
absDiffToWindow = nan(n,1);
relDiffToWindow = nan(n,1);
solverResidualOverWindowBest = nan(n,1);
numLocalMinima = nan(n,1);
scanSeconds = nan(n,1);

figure('Name','mRLFE tracker vs condition/residual scan','Color','w');
tiledlayout(n,1,'TileSpacing','compact','Padding','compact');

for ii = 1:n
    idx = sampleIndex(ii);
    freq(ii) = branch.frequency(idx);
    omega = branch.omega(idx);
    solverCp(ii) = branch.Cp(idx);
    solverResidual(ii) = mrlfeResidual(omega/solverCp(ii), omega, material, geometry, mrlfeParams);

    tLocal = tic;
    residual = nan(size(CpScan));
    for jj = 1:numel(CpScan)
        residual(jj) = mrlfeResidual(omega/CpScan(jj), omega, material, geometry, mrlfeParams);
    end
    scanSeconds(ii) = toc(tLocal);

    [globalMinResidual(ii), bestIdx] = min(residual);
    globalMinCp(ii) = CpScan(bestIdx);
    globalMinMatchesTracker(ii) = relativeDifference(globalMinCp(ii), solverCp(ii)) <= globalMatchRelativeTol;

    localIdx = find(isLocalMinimum(residual));
    localIdx = localIdx(isfinite(residual(localIdx)));
    numLocalMinima(ii) = numel(localIdx);
    if ~isempty(localIdx)
        [~, nearPos] = min(abs(CpScan(localIdx) - solverCp(ii)));
        nearIdx = localIdx(nearPos);
        nearestLocalCp(ii) = CpScan(nearIdx);
        nearestLocalResidual(ii) = residual(nearIdx);
        absDiffToLocal(ii) = abs(nearestLocalCp(ii) - solverCp(ii));
        relDiffToLocal(ii) = relativeDifference(nearestLocalCp(ii), solverCp(ii));
    end

    halfWidth = max(localWindowRelativeHalfWidth * abs(solverCp(ii)), localWindowMinHalfWidthAbs);
    inWindow = CpScan >= solverCp(ii) - halfWidth & CpScan <= solverCp(ii) + halfWidth;
    localWindowNumPoints(ii) = sum(inWindow);
    windowIdx = find(inWindow & isfinite(residual));
    if ~isempty(windowIdx)
        [localWindowBestResidual(ii), pos] = min(residual(windowIdx));
        bestWindowIdx = windowIdx(pos);
        localWindowBestCp(ii) = CpScan(bestWindowIdx);
        absDiffToWindow(ii) = abs(localWindowBestCp(ii) - solverCp(ii));
        relDiffToWindow(ii) = relativeDifference(localWindowBestCp(ii), solverCp(ii));
        solverResidualOverWindowBest(ii) = solverResidual(ii) / max(localWindowBestResidual(ii), eps);
        localWindowBestAtEdge(ii) = pos <= localWindowEdgeGuardPoints || pos >= numel(windowIdx) - localWindowEdgeGuardPoints + 1;
    end

    nexttile;
    semilogy(CpScan, residual, 'k-', 'LineWidth', 1.0); hold on;
    if ~isempty(localIdx)
        [~, order] = sort(residual(localIdx), 'ascend');
        shown = localIdx(order(1:min(numPeaksToShow,numel(order))));
        semilogy(CpScan(shown), residual(shown), 'bo', 'MarkerSize', 4);
    end
    xline(solverCp(ii), 'r-', 'LineWidth', 1.5);
    xline(globalMinCp(ii), 'Color', [0.5 0.5 0.5], 'LineStyle', ':', 'LineWidth', 1.0);
    if isfinite(nearestLocalCp(ii)), xline(nearestLocalCp(ii), 'g--', 'LineWidth', 1.1); end
    if isfinite(localWindowBestCp(ii)), xline(localWindowBestCp(ii), 'm-.', 'LineWidth', 1.1); end
    grid on;
    ylabel(sprintf('%.0f Hz', freq(ii)));
    if ii == 1
        title('black residual | blue local minima | red solver | green nearest local | magenta tight-window best | gray global');
    end
    if ii == n, xlabel('Cp [m/s]'); end
end

comparison = table(freq, solverCp, solverResidual, nearestLocalCp, absDiffToLocal, relDiffToLocal, ...
    localWindowBestCp, absDiffToWindow, relDiffToWindow, localWindowBestAtEdge, solverResidualOverWindowBest, ...
    globalMinCp, globalMinResidual, globalMinMatchesTracker, numLocalMinima, localWindowNumPoints, scanSeconds, ...
    'VariableNames', {'Frequency_Hz','SolverCp','SolverResidual','NearestDiscreteLocalMinCp', ...
    'AbsDiffToDiscreteLocalMin','RelDiffToDiscreteLocalMin','TightWindowBestCp','AbsDiffToTightWindowBest', ...
    'RelDiffToTightWindowBest','TightWindowBestAtEdge','SolverResidualOverWindowBest', ...
    'GlobalMinCp','GlobalMinResidual','GlobalMinMatchesTracker','NumDiscreteLocalMinima', ...
    'TightWindowNumPoints','BruteForceSeconds'});

discreteMetrics = table(maxOrNaN(absDiffToLocal), medianOrNaN(absDiffToLocal), ...
    maxOrNaN(relDiffToLocal), medianOrNaN(relDiffToLocal), sum(~isfinite(nearestLocalCp)), ...
    'VariableNames', {'MaxAbsDiffToDiscreteLocalMin','MedianAbsDiffToDiscreteLocalMin', ...
    'MaxRelDiffToDiscreteLocalMin','MedianRelDiffToDiscreteLocalMin','MissingDiscreteLocalMinCount'});

tightUsable = isfinite(localWindowBestCp) & ~localWindowBestAtEdge;
tightMetrics = table(maxOrNaN(absDiffToWindow(tightUsable)), medianOrNaN(absDiffToWindow(tightUsable)), ...
    maxOrNaN(relDiffToWindow(tightUsable)), medianOrNaN(relDiffToWindow(tightUsable)), ...
    maxOrNaN(solverResidualOverWindowBest(tightUsable)), medianOrNaN(solverResidualOverWindowBest(tightUsable)), ...
    sum(~isfinite(localWindowBestCp)), sum(localWindowBestAtEdge), ...
    'VariableNames', {'MaxAbsDiffToTightWindowBestNonEdge','MedianAbsDiffToTightWindowBestNonEdge', ...
    'MaxRelDiffToTightWindowBestNonEdge','MedianRelDiffToTightWindowBestNonEdge', ...
    'MaxSolverResidualOverWindowBestNonEdge','MedianSolverResidualOverWindowBestNonEdge', ...
    'MissingTightWindowCount','TightWindowBestAtEdgeCount'});

globalMetrics = table(sum(~globalMinMatchesTracker), mean(~globalMinMatchesTracker), ...
    'VariableNames', {'GlobalMismatchCount','GlobalMismatchFraction'});

estimatedBruteFull = mean(scanSeconds,'omitnan') * numel(branch.frequency);
timingMetrics = table(solverTime, sum(scanSeconds,'omitnan'), estimatedBruteFull, estimatedBruteFull/solverTime, ...
    'VariableNames', {'CurrentSolverFullBranchSeconds','BruteForceSelectedSeconds', ...
    'EstimatedBruteForceFullBranchSeconds','EstimatedSpeedupVsBruteForce'});

disp(comparison);
fprintf('\nContinuity metrics for tracked branch\n'); disp(continuity.Table);
fprintf('\nMaximum jump location\n'); disp(continuity.JumpTable);
fprintf('\nDiscrete local-minimum diagnostics\n'); disp(discreteMetrics);
fprintf('\nTight local-window diagnostics around tracker Cp\n'); disp(tightMetrics);
fprintf('\nGlobal-minimum mismatch diagnostics\n'); disp(globalMetrics);
fprintf('\nTiming summary\n'); disp(timingMetrics);

fprintf('\nInterpretation:\n');
fprintf('  - Continuity metrics quantify whether the tracked branch has artificial jumps.\n');
fprintf('  - The maximum jump table identifies where to inspect any suspicious jump.\n');
fprintf('  - Global-minimum mismatches show why global-minimum or minimum-Cp tracking is unsafe.\n');
fprintf('  - Discrete local-minimum detection can miss shallow/narrow minima on a coarse scan.\n');
fprintf('  - Tight-window diagnostics ask whether a lower residual exists immediately around the tracker.\n');
fprintf('  - If tight-window best is at the edge, do not interpret it as a local modal minimum.\n');
fprintf('  - Brute-force scanning is useful diagnostically, but expensive as a full solver.\n');

function tf = isLocalMinimum(y)
tf = false(size(y));
for k = 2:numel(y)-1
    tf(k) = isfinite(y(k)) && y(k) < y(k-1) && y(k) < y(k+1);
end
end

function r = relativeDifference(a,b)
r = abs(a-b) / max(abs(b), eps);
end

function v = maxOrNaN(x)
x = x(isfinite(x));
if isempty(x), v = nan; else, v = max(x); end
end

function v = medianOrNaN(x)
x = x(isfinite(x));
if isempty(x), v = nan; else, v = median(x); end
end

function valid = getValidMask(branch)
if isfield(branch, 'validCp')
    valid = branch.validCp(:);
elseif isfield(branch, 'valid')
    valid = branch.valid(:);
else
    valid = isfinite(branch.Cp(:));
end
end

function continuity = computeContinuityMetrics(branch, validIndex)
f = branch.frequency(:);
cp = branch.Cp(:);
idx = validIndex(:);
continuity = struct();
continuity.MaxJumpIndexBefore = nan;
continuity.MaxJumpIndexAfter = nan;
if numel(idx) < 2
    continuity.Table = table(0, 0, nan, nan, nan, 1, 'VariableNames', ...
        {'ValidPoints','NumSegments','MaxRelativeCpJump','MedianRelativeCpJump','FrequencyAtMaxJump_Hz','ValidFraction'});
    continuity.JumpTable = table();
    return;
end
relJump = abs(diff(cp(idx))) ./ max(abs(cp(idx(1:end-1))), eps);
[maxJump, localPos] = max(relJump);
medianJump = median(relJump(isfinite(relJump)));
continuity.MaxJumpIndexBefore = idx(localPos);
continuity.MaxJumpIndexAfter = idx(localPos+1);
segments = 1 + sum(diff(idx) > 1);
continuity.Table = table(numel(idx), segments, maxJump, medianJump, f(idx(localPos)), numel(idx)/numel(cp), ...
    'VariableNames', {'ValidPoints','NumSegments','MaxRelativeCpJump','MedianRelativeCpJump','FrequencyAtMaxJump_Hz','ValidFraction'});
continuity.JumpTable = table(f(idx(localPos)), f(idx(localPos+1)), cp(idx(localPos)), cp(idx(localPos+1)), maxJump, ...
    'VariableNames', {'FrequencyBefore_Hz','FrequencyAfter_Hz','CpBefore','CpAfter','RelativeJump'});
end
% HISTORICAL. Not an active contract or maintained diagnostic.
% Superseded by the public mrlfeSolve production and characterization tests.
