% Prototype multimodal candidate tracker for mRLFE elastic A0-like branch.
%
% Purpose:
%   The current pointwise tracker can still show A0-like branch switching for
%   soft materials at high frequency. This prototype does not replace the
%   production solver. It builds multiple local residual candidates per
%   frequency and then finds a globally smooth path through those candidates.
%
% Model:
%   mRLFE elastic real-k, etaS = 0
%   lambda real, mu real, k real
%
% Output files:
%   mRLFE_A0_multicandidate_path_table.csv
%   mRLFE_A0_multicandidate_summary.csv
%   mRLFE_A0_multicandidate_all_candidates.csv
%
% Main comparison:
%   1) current solver A0-like branch
%   2) minimum-residual local candidate at each frequency
%   3) dynamic-programming multimodal candidate path

startup();

EValues = [50e3, 75e3, 100e3, 150e3, 225e3]; % [Pa]

paramsBase = defaultParams();
paramsBase.fmin = 500;
paramsBase.fmax = 16000;
paramsBase.numFrequencyPoints = 160;
paramsBase.frequencySpacing = "hybrid";
paramsBase.thickness = 0.5e-3;
paramsBase.nu = 0.4999;
paramsBase.CL = 1500;

optionsBase = defaultOptions("Fast");
optionsBase.computeA0 = true;
optionsBase.computeS0 = true;
optionsBase.computeMRLFERealK = true;
optionsBase.computeMRLFEHanViscoRealK = false;
optionsBase.computeMRLFEComplexK = false;

% Candidate extraction controls.
maxCandidates = 8;
CpScanPoints = 2200;
edgeGuardPoints = 8;
CpMinFactor = 0.25;
CpMaxFactor = 2.20;
CpMinFloor = 0.25;
CpMaxCeiling = 80;

% Dynamic-programming path cost controls.
tracker = struct();
tracker.residualFloor = 1e-14;
tracker.residualWeight = 0.35;
tracker.jumpWeight = 18.0;
tracker.curvatureWeight = 12.0;
tracker.seedWeight = 0.20;
tracker.maxJumpSoft = 0.30;
tracker.largeJumpThreshold = 0.15;
tracker.missingPenalty = 20.0;
tracker.allowMissing = true;

allPathRows = [];
allCandidateRows = [];
summaryRows = [];
resultsByE = cell(size(EValues));

fprintf('\nmRLFE A0-like multimodal candidate tracker prototype\n');
fprintf('----------------------------------------------------\n');
fprintf('Frequency range: %.0f to %.0f Hz, N = %d\n', ...
    paramsBase.fmin, paramsBase.fmax, paramsBase.numFrequencyPoints);
fprintf('E values: %.3g to %.3g kPa (%d cases)\n', ...
    min(EValues)/1e3, max(EValues)/1e3, numel(EValues));
fprintf('Candidates per frequency: %d, Cp scan points: %d\n', maxCandidates, CpScanPoints);

for iE = 1:numel(EValues)
    params = paramsBase;
    params.E = EValues(iE);
    material = computeMaterial(params);

    fprintf('\nE = %.6g kPa, mu = %.6g kPa, CT = %.6g m/s\n', ...
        params.E/1e3, material.mu/1e3, material.CT);

    results = computeFundamentalLambModes(params, optionsBase);
    resultsByE{iE} = results;
    currentBranch = results.models.mRLFEElasticRealK.branches.A0Like;
    seedBranch = results.modes.A0;
    frequency = results.grid.frequency(:);
    omega = results.grid.omega(:);

    mrlfeParams = defaultMRLFEParams();
    mrlfeParams.fluidDensity = 1000;
    mrlfeParams.fluidSoundSpeed = 1500;
    mrlfeParams.etaS = 0;
    mrlfeParams.etaL = 0;
    mrlfeParams.useComplexLambda = false;

    [candidateCp, candidateResidual, candidateRank, candidateRows] = extractCandidatesForE( ...
        params, material, results.geometry, mrlfeParams, frequency, omega, seedBranch, currentBranch, ...
        maxCandidates, CpScanPoints, edgeGuardPoints, CpMinFactor, CpMaxFactor, CpMinFloor, CpMaxCeiling);
    allCandidateRows = [allCandidateRows; candidateRows]; %#ok<AGROW>

    bestResidualPath = buildBestResidualPath(candidateCp, candidateResidual);
    dpPath = trackA0CandidatesDP(candidateCp, candidateResidual, seedBranch.Cp(:), tracker);

    pathRows = buildPathRows(params, material, frequency, seedBranch, currentBranch, candidateCp, candidateResidual, candidateRank, bestResidualPath, dpPath, tracker.largeJumpThreshold);
    allPathRows = [allPathRows; pathRows]; %#ok<AGROW>

    summaryRows = [summaryRows; summarizePath(params, material, "CurrentSolver", frequency, currentBranch.Cp(:), currentBranch.residual(:), getValidCp(currentBranch), tracker.largeJumpThreshold)]; %#ok<AGROW>
    summaryRows = [summaryRows; summarizePath(params, material, "BestResidual", frequency, bestResidualPath.Cp, bestResidualPath.Residual, isfinite(bestResidualPath.Cp), tracker.largeJumpThreshold)]; %#ok<AGROW>
    summaryRows = [summaryRows; summarizePath(params, material, "DPMulticandidate", frequency, dpPath.Cp, dpPath.Residual, isfinite(dpPath.Cp), tracker.largeJumpThreshold)]; %#ok<AGROW>

    printCaseSummary(params, frequency, currentBranch, bestResidualPath, dpPath, tracker.largeJumpThreshold);

    figure;
    hold on;
    validCurrent = getValidCp(currentBranch);
    plot(frequency, maskedVector(currentBranch.Cp(:), validCurrent), 'LineWidth', 1.5, 'DisplayName', 'current solver');
    plot(frequency, bestResidualPath.Cp, '--', 'LineWidth', 1.2, 'DisplayName', 'best residual');
    plot(frequency, dpPath.Cp, '-.', 'LineWidth', 1.7, 'DisplayName', 'DP multimodal');
    plot(frequency, seedBranch.Cp(:), ':', 'LineWidth', 1.2, 'DisplayName', 'RL A0 seed');
    grid on;
    xlabel('frequency [Hz]');
    ylabel('Phase velocity Cp [m/s]');
    title(sprintf('A0-like multimodal tracker prototype, E = %.0f kPa', params.E/1e3));
    legend('Location', 'best');
    hold off;
end

mRLFE_A0MulticandidatePathTable = rowsToTable(allPathRows);
mRLFE_A0MulticandidateSummary = rowsToTable(summaryRows);
mRLFE_A0MulticandidateAllCandidates = rowsToTable(allCandidateRows);

writetable(mRLFE_A0MulticandidatePathTable, 'mRLFE_A0_multicandidate_path_table.csv');
writetable(mRLFE_A0MulticandidateSummary, 'mRLFE_A0_multicandidate_summary.csv');
writetable(mRLFE_A0MulticandidateAllCandidates, 'mRLFE_A0_multicandidate_all_candidates.csv');

assignin('base', 'mRLFE_A0MulticandidatePathTable', mRLFE_A0MulticandidatePathTable);
assignin('base', 'mRLFE_A0MulticandidateSummary', mRLFE_A0MulticandidateSummary);
assignin('base', 'mRLFE_A0MulticandidateAllCandidates', mRLFE_A0MulticandidateAllCandidates);
assignin('base', 'mRLFE_A0MulticandidateResultsByE', resultsByE);
assignin('base', 'mRLFE_A0MulticandidateTrackerOptions', tracker);

fprintf('\nA0 multimodal candidate summary\n');
fprintf('-------------------------------\n');
disp(mRLFE_A0MulticandidateSummary(:, {'PathName','E_kPa','ValidPoints','TotalPoints','SafeFmax_Hz','MaxRelativeCpJump','FirstLargeJumpRelative','MaxResidual'}));

fprintf('\nWrote:\n');
fprintf('  mRLFE_A0_multicandidate_path_table.csv\n');
fprintf('  mRLFE_A0_multicandidate_summary.csv\n');
fprintf('  mRLFE_A0_multicandidate_all_candidates.csv\n');

function [candidateCp, candidateResidual, candidateRank, rows] = extractCandidatesForE(params, material, geometry, mrlfeParams, frequency, omega, seedBranch, currentBranch, maxCandidates, CpScanPoints, edgeGuardPoints, CpMinFactor, CpMaxFactor, CpMinFloor, CpMaxCeiling)
candidateCp = nan(maxCandidates, numel(frequency));
candidateResidual = nan(maxCandidates, numel(frequency));
candidateRank = nan(maxCandidates, numel(frequency));
rows = [];

seedCp = seedBranch.Cp(:);
currentCp = currentBranch.Cp(:);
validCurrent = getValidCp(currentBranch);
validCpPool = [seedCp(isfinite(seedCp)); currentCp(validCurrent)];
if isempty(validCpPool)
    cpGlobalMin = CpMinFloor;
    cpGlobalMax = CpMaxCeiling;
else
    cpGlobalMin = max(CpMinFloor, min(validCpPool) * CpMinFactor);
    cpGlobalMax = min(CpMaxCeiling, max(validCpPool) * CpMaxFactor);
end
if cpGlobalMax <= cpGlobalMin
    cpGlobalMax = cpGlobalMin + 10;
end
CpScan = linspace(cpGlobalMin, cpGlobalMax, CpScanPoints);

for j = 1:numel(frequency)
    residual = computeResidualVsCp(CpScan, omega(j), material, geometry, mrlfeParams);
    candidates = findResidualCandidates(CpScan, residual, maxCandidates, edgeGuardPoints);
    n = numel(candidates.cp);
    candidateCp(1:n,j) = candidates.cp(:);
    candidateResidual(1:n,j) = candidates.residual(:);
    candidateRank(1:n,j) = 1:n;
    for c = 1:n
        rows = [rows; makeCandidateRow(params, material, frequency(j), c, candidates.cp(c), candidates.residual(c), seedCp(j))]; %#ok<AGROW>
    end
end
end

function residual = computeResidualVsCp(CpScan, omega, material, geometry, mrlfeParams)
residual = nan(size(CpScan));
for i = 1:numel(CpScan)
    k = omega / CpScan(i);
    residual(i) = mrlfeResidual(k, omega, material, geometry, mrlfeParams);
end
end

function candidates = findResidualCandidates(CpScan, residual, maxCandidates, edgeGuardPoints)
idx = [];
firstAllowed = 1 + edgeGuardPoints;
lastAllowed = numel(residual) - edgeGuardPoints;
for i = max(2, firstAllowed):min(numel(residual)-1, lastAllowed)
    if isfinite(residual(i)) && residual(i) < residual(i-1) && residual(i) < residual(i+1)
        idx(end+1) = i; %#ok<AGROW>
    end
end
idx = unique(round(idx(isfinite(idx) & idx >= 1 & idx <= numel(residual))));
if isempty(idx)
    candidates.cp = [];
    candidates.residual = [];
    return;
end
[~, order] = sort(residual(idx), 'ascend');
idx = idx(order);
idx = idx(1:min(maxCandidates, numel(idx)));
candidates.cp = CpScan(idx);
candidates.residual = residual(idx);
end

function path = buildBestResidualPath(candidateCp, candidateResidual)
numFreq = size(candidateCp, 2);
path.Cp = nan(numFreq, 1);
path.Residual = nan(numFreq, 1);
path.CandidateIndex = nan(numFreq, 1);
path.PathCost = nan(numFreq, 1);
for j = 1:numFreq
    valid = find(isfinite(candidateCp(:,j)) & isfinite(candidateResidual(:,j)));
    if isempty(valid)
        continue;
    end
    [~, local] = min(candidateResidual(valid,j));
    idx = valid(local);
    path.Cp(j) = candidateCp(idx,j);
    path.Residual(j) = candidateResidual(idx,j);
    path.CandidateIndex(j) = idx;
    path.PathCost(j) = candidateResidual(idx,j);
end
end

function path = trackA0CandidatesDP(candidateCp, candidateResidual, seedCp, tracker)
[numCandidates, numFreq] = size(candidateCp);
nodeCount = numCandidates + 1; % last node is missing/skip state
missingNode = nodeCount;

cost = inf(nodeCount, numFreq);
prev = nan(nodeCount, numFreq);

for c = 1:numCandidates
    if isfinite(candidateCp(c,1))
        cost(c,1) = unaryCost(candidateCp(c,1), candidateResidual(c,1), seedCp(1), tracker);
    end
end
if tracker.allowMissing
    cost(missingNode,1) = tracker.missingPenalty;
end

for j = 2:numFreq
    for c = 1:nodeCount
        if c == missingNode
            if ~tracker.allowMissing
                continue;
            end
            cpNow = nan;
            unary = tracker.missingPenalty;
        else
            cpNow = candidateCp(c,j);
            if ~isfinite(cpNow)
                continue;
            end
            unary = unaryCost(cpNow, candidateResidual(c,j), seedCp(j), tracker);
        end

        bestCost = inf;
        bestPrev = nan;
        for p = 1:nodeCount
            if ~isfinite(cost(p,j-1))
                continue;
            end
            transition = transitionCost(candidateCp, p, c, j, missingNode, tracker);
            total = cost(p,j-1) + unary + transition;
            if total < bestCost
                bestCost = total;
                bestPrev = p;
            end
        end
        cost(c,j) = bestCost;
        prev(c,j) = bestPrev;
    end
end

[~, lastNode] = min(cost(:,numFreq));
nodePath = nan(numFreq,1);
nodePath(numFreq) = lastNode;
for j = numFreq:-1:2
    nodePath(j-1) = prev(nodePath(j),j);
    if ~isfinite(nodePath(j-1))
        break;
    end
end

path.Cp = nan(numFreq,1);
path.Residual = nan(numFreq,1);
path.CandidateIndex = nan(numFreq,1);
path.PathCost = nan(numFreq,1);
for j = 1:numFreq
    c = nodePath(j);
    if isfinite(c) && c ~= missingNode && c >= 1 && c <= numCandidates
        path.Cp(j) = candidateCp(c,j);
        path.Residual(j) = candidateResidual(c,j);
        path.CandidateIndex(j) = c;
    end
    if isfinite(c)
        path.PathCost(j) = cost(c,j);
    end
end
end

function value = unaryCost(cp, residual, seedCp, tracker)
if ~isfinite(cp) || ~isfinite(residual)
    value = inf;
    return;
end
rTerm = log10(max(residual, tracker.residualFloor));
seedTerm = abs(cp - seedCp) / max(abs(seedCp), eps);
value = tracker.residualWeight * rTerm + tracker.seedWeight * seedTerm.^2;
end

function value = transitionCost(candidateCp, p, c, j, missingNode, tracker)
if p == missingNode || c == missingNode
    value = 0.5 * tracker.missingPenalty;
    return;
end
cpPrev = candidateCp(p,j-1);
cpNow = candidateCp(c,j);
if ~isfinite(cpPrev) || ~isfinite(cpNow)
    value = inf;
    return;
end
jump = abs(cpNow - cpPrev) / max(abs(cpPrev), eps);
value = tracker.jumpWeight * jump.^2;
if jump > tracker.maxJumpSoft
    value = value + tracker.jumpWeight * (jump - tracker.maxJumpSoft).^2 * 20;
end

if j >= 3
    % Add a light curvature penalty when the previous path has a finite
    % candidate at j-2. This is local and approximate, but helps discourage
    % zig-zag paths without making the prototype too complex.
    cpPrev2 = nan;
    if p <= size(candidateCp,1)
        % choose the nearest finite candidate at j-2 to cpPrev as proxy
        prevCandidates = candidateCp(:,j-2);
        valid = isfinite(prevCandidates);
        if any(valid)
            [~, idx] = min(abs(prevCandidates(valid) - cpPrev));
            validIdx = find(valid);
            cpPrev2 = prevCandidates(validIdx(idx));
        end
    end
    if isfinite(cpPrev2)
        pred = cpPrev + (cpPrev - cpPrev2);
        curvature = abs(cpNow - pred) / max(abs(pred), eps);
        value = value + tracker.curvatureWeight * curvature.^2;
    end
end
end

function rows = buildPathRows(params, material, frequency, seedBranch, currentBranch, candidateCp, candidateResidual, candidateRank, bestResidualPath, dpPath, largeJumpThreshold)
rows = [];
validCurrent = getValidCp(currentBranch);
currentCp = currentBranch.Cp(:);
currentResidual = currentBranch.residual(:);
seedCp = seedBranch.Cp(:);
for j = 1:numel(frequency)
    rows = [rows; makePathRow(params, material, "CurrentSolver", frequency(j), seedCp(j), currentCp(j), getValue(currentResidual,j), nan, nan, validCurrent(j), nan, largeJumpThreshold)]; %#ok<AGROW>
    rows = [rows; makePathRow(params, material, "BestResidual", frequency(j), seedCp(j), bestResidualPath.Cp(j), bestResidualPath.Residual(j), bestResidualPath.CandidateIndex(j), bestResidualPath.PathCost(j), isfinite(bestResidualPath.Cp(j)), candidateRankValue(candidateRank, bestResidualPath.CandidateIndex(j), j), largeJumpThreshold)]; %#ok<AGROW>
    rows = [rows; makePathRow(params, material, "DPMulticandidate", frequency(j), seedCp(j), dpPath.Cp(j), dpPath.Residual(j), dpPath.CandidateIndex(j), dpPath.PathCost(j), isfinite(dpPath.Cp(j)), candidateRankValue(candidateRank, dpPath.CandidateIndex(j), j), largeJumpThreshold)]; %#ok<AGROW>
end
end

function value = candidateRankValue(candidateRank, candidateIndex, j)
value = nan;
if isfinite(candidateIndex) && candidateIndex >= 1 && candidateIndex <= size(candidateRank,1)
    value = candidateRank(candidateIndex,j);
end
end

function row = makePathRow(params, material, pathName, frequency, seedCp, cp, residual, candidateIndex, pathCost, valid, candidateRank, largeJumpThreshold)
row = struct();
row.PathName = string(pathName);
row.E_kPa = params.E/1e3;
row.Mu_kPa = material.mu/1e3;
row.CT_m_per_s = material.CT;
row.Frequency_Hz = frequency;
row.SeedCp = seedCp;
row.Cp = cp;
row.Residual = residual;
row.CandidateIndex = candidateIndex;
row.CandidateRank = candidateRank;
row.PathCost = pathCost;
row.Valid = logical(valid);
row.LargeJumpThreshold = largeJumpThreshold;
end

function row = makeCandidateRow(params, material, frequency, rank, cp, residual, seedCp)
row = struct();
row.E_kPa = params.E/1e3;
row.Mu_kPa = material.mu/1e3;
row.CT_m_per_s = material.CT;
row.Frequency_Hz = frequency;
row.CandidateRank = rank;
row.Cp = cp;
row.Residual = residual;
row.RelativeSeedDistance = abs(cp - seedCp) / max(abs(seedCp), eps);
end

function row = summarizePath(params, material, pathName, frequency, cp, residual, valid, largeJumpThreshold)
valid = valid(:) & isfinite(cp(:));
row = struct();
row.PathName = string(pathName);
row.E_kPa = params.E/1e3;
row.Mu_kPa = material.mu/1e3;
row.CT_m_per_s = material.CT;
row.ValidPoints = sum(valid);
row.TotalPoints = numel(cp);
row.ValidFraction = row.ValidPoints / max(row.TotalPoints, 1);
row.ValidFmin_Hz = nan;
row.ValidFmax_Hz = nan;
row.SafeFmax_Hz = nan;
row.MinCp = nan;
row.MaxCp = nan;
row.MaxResidual = nan;
row.MaxRelativeCpJump = nan;
row.FirstLargeJumpRelative = nan;
row.FrequencyBeforeFirstLargeJump_Hz = nan;
row.FrequencyAfterFirstLargeJump_Hz = nan;
if any(valid)
    fValid = frequency(valid);
    cpValid = cp(valid);
    row.ValidFmin_Hz = min(fValid);
    row.ValidFmax_Hz = max(fValid);
    row.SafeFmax_Hz = fValid(end);
    row.MinCp = min(cpValid);
    row.MaxCp = max(cpValid);
    if any(isfinite(residual(valid)))
        row.MaxResidual = max(residual(valid & isfinite(residual(:))));
    end
    jumpInfo = computeJumpDiagnostics(frequency, cp, valid, largeJumpThreshold);
    row.MaxRelativeCpJump = jumpInfo.MaxRelativeCpJump;
    row.FirstLargeJumpRelative = jumpInfo.FirstLargeJumpRelative;
    row.FrequencyBeforeFirstLargeJump_Hz = jumpInfo.FrequencyBeforeFirstLargeJump_Hz;
    row.FrequencyAfterFirstLargeJump_Hz = jumpInfo.FrequencyAfterFirstLargeJump_Hz;
    row.SafeFmax_Hz = jumpInfo.SafeFmax_Hz;
end
end

function jumpInfo = computeJumpDiagnostics(frequency, cp, valid, largeJumpThreshold)
f = frequency(:);
cp = cp(:);
idx = find(valid(:) & isfinite(cp) & isfinite(f));
jumpInfo = struct();
jumpInfo.MaxRelativeCpJump = 0;
jumpInfo.FirstLargeJumpRelative = nan;
jumpInfo.FrequencyBeforeFirstLargeJump_Hz = nan;
jumpInfo.FrequencyAfterFirstLargeJump_Hz = nan;
jumpInfo.SafeFmax_Hz = nan;
if isempty(idx)
    return;
end
jumpInfo.SafeFmax_Hz = f(idx(end));
if numel(idx) < 2
    return;
end
relJump = abs(diff(cp(idx))) ./ max(abs(cp(idx(1:end-1))), eps);
jumpInfo.MaxRelativeCpJump = max(relJump);
firstLarge = find(relJump > largeJumpThreshold, 1, 'first');
if ~isempty(firstLarge)
    iBefore = idx(firstLarge);
    iAfter = idx(firstLarge+1);
    jumpInfo.FirstLargeJumpRelative = relJump(firstLarge);
    jumpInfo.FrequencyBeforeFirstLargeJump_Hz = f(iBefore);
    jumpInfo.FrequencyAfterFirstLargeJump_Hz = f(iAfter);
    jumpInfo.SafeFmax_Hz = f(iBefore);
end
end

function printCaseSummary(params, frequency, currentBranch, bestResidualPath, dpPath, largeJumpThreshold)
currentSummary = summarizePath(params, computeMaterial(params), "CurrentSolver", frequency, currentBranch.Cp(:), currentBranch.residual(:), getValidCp(currentBranch), largeJumpThreshold);
bestSummary = summarizePath(params, computeMaterial(params), "BestResidual", frequency, bestResidualPath.Cp, bestResidualPath.Residual, isfinite(bestResidualPath.Cp), largeJumpThreshold);
dpSummary = summarizePath(params, computeMaterial(params), "DPMulticandidate", frequency, dpPath.Cp, dpPath.Residual, isfinite(dpPath.Cp), largeJumpThreshold);
fprintf('  Current solver: valid %d/%d, safe fmax %.6g Hz, max jump %.3g\n', ...
    currentSummary.ValidPoints, currentSummary.TotalPoints, currentSummary.SafeFmax_Hz, currentSummary.MaxRelativeCpJump);
fprintf('  Best residual:  valid %d/%d, safe fmax %.6g Hz, max jump %.3g\n', ...
    bestSummary.ValidPoints, bestSummary.TotalPoints, bestSummary.SafeFmax_Hz, bestSummary.MaxRelativeCpJump);
fprintf('  DP multimodal:  valid %d/%d, safe fmax %.6g Hz, max jump %.3g\n', ...
    dpSummary.ValidPoints, dpSummary.TotalPoints, dpSummary.SafeFmax_Hz, dpSummary.MaxRelativeCpJump);
end

function value = getValue(x, idx)
x = x(:);
if idx <= numel(x)
    value = x(idx);
else
    value = nan;
end
end

function y = maskedVector(x, valid)
y = x(:);
y(~valid(:)) = nan;
end

function valid = getValidCp(branch)
if isfield(branch, 'validCp')
    valid = branch.validCp;
else
    valid = branch.valid;
end
valid = valid(:) & isfinite(branch.Cp(:));
end

function T = rowsToTable(rows)
if isempty(rows)
    T = table();
else
    T = struct2table(rows);
end
end
