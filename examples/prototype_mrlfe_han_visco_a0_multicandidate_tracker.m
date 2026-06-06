% Prototype multicandidate DP tracker for Han-style viscoelastic A0-like mRLFE.
%
% Purpose:
%   Diagnose whether A0-like branch switching in the Han real-k
%   viscoelastic model can be corrected by the same multicandidate dynamic
%   programming strategy used for the elastic A0-like branch.
%
% Model:
%   mRLFEHanViscoRealK
%   lambda real
%   muStar = mu + 1i*omega*etaS
%   k real
%
% Output files:
%   mRLFE_han_visco_A0_multicandidate_path_table.csv
%   mRLFE_han_visco_A0_multicandidate_summary.csv
%   mRLFE_han_visco_A0_multicandidate_all_candidates.csv
%
% Comparison:
%   1) Current Han solver A0-like branch
%   2) Minimum-residual local candidate at each frequency
%   3) DP multicandidate path seeded by the elastic A0-like branch

startup();

EValues = [50e3, 100e3, 300e3, 500e3]; % [Pa]
etaSValues = [0.05, 0.1, 0.3, 0.5, 1.0]; % [Pa*s]

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
optionsBase.computeMRLFEHanViscoRealK = true;
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
resultsByCase = cell(numel(EValues), numel(etaSValues));

fprintf('\nHan viscoelastic A0-like multicandidate tracker prototype\n');
fprintf('---------------------------------------------------------\n');
fprintf('Frequency range: %.0f to %.0f Hz, N = %d\n', ...
    paramsBase.fmin, paramsBase.fmax, paramsBase.numFrequencyPoints);
fprintf('E values: %.3g to %.3g kPa (%d cases)\n', ...
    min(EValues)/1e3, max(EValues)/1e3, numel(EValues));
fprintf('etaS values: %.3g to %.3g Pa*s (%d cases)\n', ...
    min(etaSValues), max(etaSValues), numel(etaSValues));
fprintf('Candidates per frequency: %d, Cp scan points: %d\n', maxCandidates, CpScanPoints);

for iE = 1:numel(EValues)
    params = paramsBase;
    params.E = EValues(iE);
    material = computeMaterial(params);
    fprintf('\nE = %.6g kPa, mu = %.6g kPa, CT = %.6g m/s\n', ...
        params.E/1e3, material.mu/1e3, material.CT);

    for iEta = 1:numel(etaSValues)
        etaS = etaSValues(iEta);
        options = optionsBase;
        options.mrlfeParams = struct('etaS', etaS, 'etaL', 0, 'useComplexLambda', false);
        fprintf('  etaS = %.6g Pa*s\n', etaS);

        results = computeFundamentalLambModes(params, options);
        resultsByCase{iE,iEta} = results;

        currentBranch = results.models.mRLFEHanViscoRealK.branches.A0Like;
        elasticBranch = results.models.mRLFEElasticRealK.branches.A0Like;
        frequency = results.grid.frequency(:);
        omega = results.grid.omega(:);

        mrlfeParams = defaultMRLFEParams();
        mrlfeParams.fluidDensity = 1000;
        mrlfeParams.fluidSoundSpeed = 1500;
        mrlfeParams.etaS = etaS;
        mrlfeParams.etaL = 0;
        mrlfeParams.useComplexLambda = false;
        mrlfeParams.solveComplexK = false;

        [candidateCp, candidateResidual, candidateRank, candidateRows] = extractCandidatesForCase( ...
            params, material, results.geometry, mrlfeParams, frequency, omega, elasticBranch, currentBranch, ...
            maxCandidates, CpScanPoints, edgeGuardPoints, CpMinFactor, CpMaxFactor, CpMinFloor, CpMaxCeiling, etaS);
        allCandidateRows = [allCandidateRows; candidateRows]; %#ok<AGROW>

        bestResidualPath = buildBestResidualPath(candidateCp, candidateResidual);
        dpPath = trackCandidatesDP(candidateCp, candidateResidual, elasticBranch.Cp(:), tracker);

        pathRows = buildPathRows(params, material, etaS, frequency, elasticBranch, currentBranch, candidateCp, candidateResidual, candidateRank, bestResidualPath, dpPath, tracker.largeJumpThreshold);
        allPathRows = [allPathRows; pathRows]; %#ok<AGROW>

        currentCp = currentBranch.Cp(:);
        currentValid = getValidCp(currentBranch);
        summaryRows = [summaryRows; summarizePath(params, material, etaS, "CurrentHanSolver", frequency, currentCp, currentBranch.residual(:), currentValid, tracker.largeJumpThreshold, currentCp, currentValid)]; %#ok<AGROW>
        summaryRows = [summaryRows; summarizePath(params, material, etaS, "BestResidual", frequency, bestResidualPath.Cp, bestResidualPath.Residual, isfinite(bestResidualPath.Cp), tracker.largeJumpThreshold, currentCp, currentValid)]; %#ok<AGROW>
        summaryRows = [summaryRows; summarizePath(params, material, etaS, "DPHanMulticandidate", frequency, dpPath.Cp, dpPath.Residual, isfinite(dpPath.Cp), tracker.largeJumpThreshold, currentCp, currentValid)]; %#ok<AGROW>

        printCaseSummary(params, etaS, frequency, currentBranch, bestResidualPath, dpPath, tracker.largeJumpThreshold);
    end
end

mRLFEHanViscoA0MulticandidatePathTable = rowsToTable(allPathRows);
mRLFEHanViscoA0MulticandidateSummary = rowsToTable(summaryRows);
mRLFEHanViscoA0MulticandidateAllCandidates = rowsToTable(allCandidateRows);

writetable(mRLFEHanViscoA0MulticandidatePathTable, 'mRLFE_han_visco_A0_multicandidate_path_table.csv');
writetable(mRLFEHanViscoA0MulticandidateSummary, 'mRLFE_han_visco_A0_multicandidate_summary.csv');
writetable(mRLFEHanViscoA0MulticandidateAllCandidates, 'mRLFE_han_visco_A0_multicandidate_all_candidates.csv');

assignin('base', 'mRLFEHanViscoA0MulticandidatePathTable', mRLFEHanViscoA0MulticandidatePathTable);
assignin('base', 'mRLFEHanViscoA0MulticandidateSummary', mRLFEHanViscoA0MulticandidateSummary);
assignin('base', 'mRLFEHanViscoA0MulticandidateAllCandidates', mRLFEHanViscoA0MulticandidateAllCandidates);
assignin('base', 'mRLFEHanViscoA0MulticandidateResultsByCase', resultsByCase);
assignin('base', 'mRLFEHanViscoA0MulticandidateTrackerOptions', tracker);

fprintf('\nHan viscoelastic A0 multicandidate summary\n');
fprintf('------------------------------------------\n');
disp(mRLFEHanViscoA0MulticandidateSummary(:, {'PathName','E_kPa','EtaS_Pa_s','ValidPoints','TotalPoints','SafeFmax_Hz','MaxRelativeCpJump','FirstLargeJumpRelative','MaxRelativeDifferenceVsCurrent','MeanRelativeDifferenceVsCurrent','MaxResidual'}));

fprintf('\nWrote:\n');
fprintf('  mRLFE_han_visco_A0_multicandidate_path_table.csv\n');
fprintf('  mRLFE_han_visco_A0_multicandidate_summary.csv\n');
fprintf('  mRLFE_han_visco_A0_multicandidate_all_candidates.csv\n');

function [candidateCp, candidateResidual, candidateRank, rows] = extractCandidatesForCase(params, material, geometry, mrlfeParams, frequency, omega, elasticBranch, currentBranch, maxCandidates, CpScanPoints, edgeGuardPoints, CpMinFactor, CpMaxFactor, CpMinFloor, CpMaxCeiling, etaS)
candidateCp = nan(maxCandidates, numel(frequency));
candidateResidual = nan(maxCandidates, numel(frequency));
candidateRank = nan(maxCandidates, numel(frequency));
rows = [];

elasticCp = elasticBranch.Cp(:);
currentCp = currentBranch.Cp(:);
validElastic = getValidCp(elasticBranch);
validCurrent = getValidCp(currentBranch);
validCpPool = [elasticCp(validElastic); currentCp(validCurrent)];
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
        rows = [rows; makeCandidateRow(params, material, etaS, frequency(j), c, candidates.cp(c), candidates.residual(c), elasticCp(j))]; %#ok<AGROW>
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

function path = trackCandidatesDP(candidateCp, candidateResidual, seedCp, tracker)
[numCandidates, numFreq] = size(candidateCp);
nodeCount = numCandidates + 1;
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
            unary = tracker.missingPenalty;
        else
            if ~isfinite(candidateCp(c,j))
                continue;
            end
            unary = unaryCost(candidateCp(c,j), candidateResidual(c,j), seedCp(j), tracker);
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
    cpPrev2 = nan;
    if p <= size(candidateCp,1)
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

function rows = buildPathRows(params, material, etaS, frequency, elasticBranch, currentBranch, candidateCp, candidateResidual, candidateRank, bestResidualPath, dpPath, largeJumpThreshold)
rows = [];
validCurrent = getValidCp(currentBranch);
currentCp = currentBranch.Cp(:);
currentResidual = currentBranch.residual(:);
seedCp = elasticBranch.Cp(:);
for j = 1:numel(frequency)
    rows = [rows; makePathRow(params, material, etaS, "CurrentHanSolver", frequency(j), seedCp(j), currentCp(j), getValue(currentResidual,j), nan, nan, validCurrent(j), nan, largeJumpThreshold)]; %#ok<AGROW>
    rows = [rows; makePathRow(params, material, etaS, "BestResidual", frequency(j), seedCp(j), bestResidualPath.Cp(j), bestResidualPath.Residual(j), bestResidualPath.CandidateIndex(j), bestResidualPath.PathCost(j), isfinite(bestResidualPath.Cp(j)), candidateRankValue(candidateRank, bestResidualPath.CandidateIndex(j), j), largeJumpThreshold)]; %#ok<AGROW>
    rows = [rows; makePathRow(params, material, etaS, "DPHanMulticandidate", frequency(j), seedCp(j), dpPath.Cp(j), dpPath.Residual(j), dpPath.CandidateIndex(j), dpPath.PathCost(j), isfinite(dpPath.Cp(j)), candidateRankValue(candidateRank, dpPath.CandidateIndex(j), j), largeJumpThreshold)]; %#ok<AGROW>
end
end

function value = candidateRankValue(candidateRank, candidateIndex, j)
value = nan;
if isfinite(candidateIndex) && candidateIndex >= 1 && candidateIndex <= size(candidateRank,1)
    value = candidateRank(candidateIndex,j);
end
end

function row = makePathRow(params, material, etaS, pathName, frequency, seedCp, cp, residual, candidateIndex, pathCost, valid, candidateRank, largeJumpThreshold)
row = struct();
row.PathName = string(pathName);
row.E_kPa = params.E/1e3;
row.Mu_kPa = material.mu/1e3;
row.CT_m_per_s = material.CT;
row.EtaS_Pa_s = etaS;
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

function row = makeCandidateRow(params, material, etaS, frequency, rank, cp, residual, seedCp)
row = struct();
row.E_kPa = params.E/1e3;
row.Mu_kPa = material.mu/1e3;
row.CT_m_per_s = material.CT;
row.EtaS_Pa_s = etaS;
row.Frequency_Hz = frequency;
row.CandidateRank = rank;
row.Cp = cp;
row.Residual = residual;
row.RelativeSeedDistance = abs(cp - seedCp) / max(abs(seedCp), eps);
end

function row = summarizePath(params, material, etaS, pathName, frequency, cp, residual, valid, largeJumpThreshold, currentCp, currentValid)
valid = valid(:) & isfinite(cp(:));
row = struct();
row.PathName = string(pathName);
row.E_kPa = params.E/1e3;
row.Mu_kPa = material.mu/1e3;
row.CT_m_per_s = material.CT;
row.EtaS_Pa_s = etaS;
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
row.MaxRelativeDifferenceVsCurrent = nan;
row.MeanRelativeDifferenceVsCurrent = nan;
row.CommonValidPointsVsCurrent = 0;
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
if nargin >= 10
    diffMask = valid(:) & currentValid(:) & isfinite(cp(:)) & isfinite(currentCp(:)) & abs(currentCp(:)) > eps;
    row.CommonValidPointsVsCurrent = sum(diffMask);
    if any(diffMask)
        relDiff = abs(cp(diffMask) - currentCp(diffMask)) ./ abs(currentCp(diffMask));
        row.MaxRelativeDifferenceVsCurrent = max(relDiff);
        row.MeanRelativeDifferenceVsCurrent = mean(relDiff);
    end
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

function printCaseSummary(params, etaS, frequency, currentBranch, bestResidualPath, dpPath, largeJumpThreshold)
material = computeMaterial(params);
currentCp = currentBranch.Cp(:);
currentValid = getValidCp(currentBranch);
currentSummary = summarizePath(params, material, etaS, "CurrentHanSolver", frequency, currentCp, currentBranch.residual(:), currentValid, largeJumpThreshold, currentCp, currentValid);
bestSummary = summarizePath(params, material, etaS, "BestResidual", frequency, bestResidualPath.Cp, bestResidualPath.Residual, isfinite(bestResidualPath.Cp), largeJumpThreshold, currentCp, currentValid);
dpSummary = summarizePath(params, material, etaS, "DPHanMulticandidate", frequency, dpPath.Cp, dpPath.Residual, isfinite(dpPath.Cp), largeJumpThreshold, currentCp, currentValid);
fprintf('    Current Han: valid %d/%d, safe fmax %.6g Hz, max jump %.3g\n', ...
    currentSummary.ValidPoints, currentSummary.TotalPoints, currentSummary.SafeFmax_Hz, currentSummary.MaxRelativeCpJump);
fprintf('    Best residual: valid %d/%d, safe fmax %.6g Hz, max jump %.3g, max diff vs current %.3g\n', ...
    bestSummary.ValidPoints, bestSummary.TotalPoints, bestSummary.SafeFmax_Hz, bestSummary.MaxRelativeCpJump, bestSummary.MaxRelativeDifferenceVsCurrent);
fprintf('    DP Han: valid %d/%d, safe fmax %.6g Hz, max jump %.3g, max diff vs current %.3g\n', ...
    dpSummary.ValidPoints, dpSummary.TotalPoints, dpSummary.SafeFmax_Hz, dpSummary.MaxRelativeCpJump, dpSummary.MaxRelativeDifferenceVsCurrent);
end

function value = getValue(x, idx)
x = x(:);
if idx <= numel(x)
    value = x(idx);
else
    value = nan;
end
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
