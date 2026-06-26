function branch = solveMRLFEBranchDP(name, seedMode, material, geometry, mrlfeParams, options, guideBranch)
% Track one real-k mRLFE branch using multiple local candidates and a global
% dynamic-programming path selection.
%
% This solver extracts several local residual minima at each frequency, then
% selects a globally smooth branch. It avoids pointwise branch switching when
% only the lowest residual valley is selected.
%
% guideBranch is optional. When provided, it is used only to define a safer
% Cp scan range. This reproduces the prototype behavior that used both the
% Rayleigh-Lamb seed and a preliminary local/modal mRLFE branch to avoid
% missing high-Cp A0-like candidate valleys.

if nargin < 7
    guideBranch = [];
end

frequency = seedMode.frequency(:);
omega = seedMode.omega(:);
if isfield(seedMode, 'kReal')
    seedK = seedMode.kReal(:);
else
    seedK = real(seedMode.k(:));
end
seedCp = omega ./ seedK;

tracker = buildTrackerOptions(options);
[candidateCp, candidateResidual, candidateRank] = extractCandidates(seedMode, guideBranch, material, geometry, mrlfeParams, tracker);
path = trackCandidatesDP(candidateCp, candidateResidual, seedCp, tracker);

Cp = path.Cp;
kReal = omega ./ Cp;
kReal(~isfinite(Cp) | Cp <= 0) = nan;
kImag = zeros(size(kReal));
k = kReal;
residual = path.Residual;
score = path.PathCost;
kThickness = kReal * geometry.thickness;

[validResidual, validReference, validSmooth, validCp] = computeRealKValidity(Cp, kReal, residual, seedCp, seedK, options);
validAttenuation = false(size(validCp));

branch = struct();
branch.name = name;
branch.family = string(name);
branch.frequency = frequency;
branch.omega = omega;
branch.k = k;
branch.kReal = kReal;
branch.kImag = kImag;
branch.attenuation = kImag;
branch.Cp = Cp;
branch.kThickness = kThickness;
branch.residual = residual;
branch.score = score;
branch.seedK = seedK;
branch.seedCp = seedCp;
branch.validResidual = validResidual;
branch.validReference = validReference;
branch.validSmooth = validSmooth;
branch.validCp = validCp;
branch.validAttenuation = validAttenuation;
branch.valid = validCp;
branch.candidateIndex = path.CandidateIndex;
branch.candidateRank = getCandidateRanks(candidateRank, path.CandidateIndex);
branch.dpPathCost = path.PathCost;
branch.dpOptions = tracker;
branch.usedGuideBranch = ~isempty(guideBranch);
branch.note = "mRLFE real-k branch tracked with multicandidate dynamic programming.";
end

function tracker = buildTrackerOptions(options)
tracker = struct();
tracker.maxCandidates = getOption(options, 'mrlfeA0DPCandidates', 8);
tracker.cpScanPoints = getOption(options, 'mrlfeA0DPCpScanPoints', 2200);
tracker.edgeGuardPoints = getOption(options, 'mrlfeA0DPEdgeGuardPoints', 8);
tracker.cpMinFactor = getOption(options, 'mrlfeA0DPCpMinFactor', 0.25);
tracker.cpMaxFactor = getOption(options, 'mrlfeA0DPCpMaxFactor', 2.20);
tracker.cpMinFloor = getOption(options, 'mrlfeA0DPCpMinFloor', 0.25);
tracker.cpMaxCeiling = getOption(options, 'mrlfeA0DPCpMaxCeiling', 80);
tracker.residualFloor = getOption(options, 'mrlfeRealKResidualFloor', 1e-14);
tracker.residualWeight = getOption(options, 'mrlfeA0DPResidualWeight', 0.35);
tracker.jumpWeight = getOption(options, 'mrlfeA0DPJumpWeight', 18.0);
tracker.curvatureWeight = getOption(options, 'mrlfeA0DPCurvatureWeight', 12.0);
tracker.seedWeight = getOption(options, 'mrlfeA0DPSeedWeight', 0.20);
tracker.maxJumpSoft = getOption(options, 'mrlfeA0DPMaxJumpSoft', 0.30);
tracker.missingPenalty = getOption(options, 'mrlfeA0DPMissingPenalty', 20.0);
tracker.allowMissing = getOption(options, 'mrlfeA0DPAllowMissing', true);
tracker.refineCandidates = getOption(options, 'mrlfeA0DPRefineCandidates', false);
tracker.refineTolX = getOption(options, 'mrlfeA0DPRefineTolX', 1e-6);
tracker.refineMaxIter = getOption(options, 'mrlfeA0DPRefineMaxIter', 24);
tracker.refineMaxFunEvals = getOption(options, 'mrlfeA0DPRefineMaxFunEvals', 60);
end

function [candidateCp, candidateResidual, candidateRank] = extractCandidates(seedMode, guideBranch, material, geometry, mrlfeParams, tracker)
frequency = seedMode.frequency(:);
omega = seedMode.omega(:);
seedCp = seedMode.Cp(:);

candidateCp = nan(tracker.maxCandidates, numel(frequency));
candidateResidual = nan(tracker.maxCandidates, numel(frequency));
candidateRank = nan(tracker.maxCandidates, numel(frequency));

validSeed = isfinite(seedCp) & seedCp > 0;
validCpPool = seedCp(validSeed);
if ~isempty(guideBranch) && isfield(guideBranch, 'Cp')
    guideCp = guideBranch.Cp(:);
    if isfield(guideBranch, 'validCp')
        validGuide = guideBranch.validCp(:) & isfinite(guideCp) & guideCp > 0;
    elseif isfield(guideBranch, 'valid')
        validGuide = guideBranch.valid(:) & isfinite(guideCp) & guideCp > 0;
    else
        validGuide = isfinite(guideCp) & guideCp > 0;
    end
    validCpPool = [validCpPool; guideCp(validGuide)]; %#ok<AGROW>
end

if isempty(validCpPool)
    cpGlobalMin = tracker.cpMinFloor;
    cpGlobalMax = tracker.cpMaxCeiling;
else
    cpGlobalMin = max(tracker.cpMinFloor, min(validCpPool) * tracker.cpMinFactor);
    cpGlobalMax = min(tracker.cpMaxCeiling, max(validCpPool) * tracker.cpMaxFactor);
end
if cpGlobalMax <= cpGlobalMin
    cpGlobalMax = cpGlobalMin + 10;
end
CpScan = linspace(cpGlobalMin, cpGlobalMax, tracker.cpScanPoints);

for j = 1:numel(frequency)
    residual = computeResidualVsCp(CpScan, omega(j), material, geometry, mrlfeParams);
    candidates = findResidualCandidates(CpScan, residual, omega(j), material, geometry, mrlfeParams, tracker);
    n = numel(candidates.cp);
    candidateCp(1:n,j) = candidates.cp(:);
    candidateResidual(1:n,j) = candidates.residual(:);
    candidateRank(1:n,j) = 1:n;
end
end

function residual = computeResidualVsCp(CpScan, omega, material, geometry, mrlfeParams)
residual = nan(size(CpScan));
for i = 1:numel(CpScan)
    residual(i) = residualAtCp(CpScan(i), omega, material, geometry, mrlfeParams);
end
end

function value = residualAtCp(cp, omega, material, geometry, mrlfeParams)
if ~isfinite(cp) || cp <= 0
    value = inf;
    return;
end
k = omega / cp;
value = mrlfeResidual(k, omega, material, geometry, mrlfeParams);
end

function candidates = findResidualCandidates(CpScan, residual, omega, material, geometry, mrlfeParams, tracker)
idx = [];
firstAllowed = 1 + tracker.edgeGuardPoints;
lastAllowed = numel(residual) - tracker.edgeGuardPoints;
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
idx = idx(1:min(tracker.maxCandidates, numel(idx)));

cp = CpScan(idx);
res = residual(idx);
if tracker.refineCandidates
    [cp, res] = refineResidualCandidates(CpScan, residual, idx, omega, material, geometry, mrlfeParams, tracker);
    [~, refinedOrder] = sort(res, 'ascend');
    cp = cp(refinedOrder);
    res = res(refinedOrder);
end
candidates.cp = cp;
candidates.residual = res;
end

function [cpRefined, residualRefined] = refineResidualCandidates(CpScan, residual, idx, omega, material, geometry, mrlfeParams, tracker)
cpRefined = CpScan(idx);
residualRefined = residual(idx);
opt = optimset('Display', 'off', 'TolX', tracker.refineTolX, ...
    'MaxIter', tracker.refineMaxIter, 'MaxFunEvals', tracker.refineMaxFunEvals);
for n = 1:numel(idx)
    i = idx(n);
    if i <= 1 || i >= numel(CpScan)
        continue;
    end
    lower = CpScan(i-1);
    upper = CpScan(i+1);
    if ~(isfinite(lower) && isfinite(upper) && upper > lower)
        continue;
    end
    try
        objective = @(cp) residualAtCp(cp, omega, material, geometry, mrlfeParams);
        [cpBest, residualBest] = fminbnd(objective, lower, upper, opt);
        if isfinite(cpBest) && isfinite(residualBest) && residualBest <= residualRefined(n)
            cpRefined(n) = cpBest;
            residualRefined(n) = residualBest;
        end
    catch
        % Keep the grid candidate if the local refinement fails.
    end
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

function [validResidual, validReference, validSmooth, validCp] = computeRealKValidity(Cp, kReal, residual, seedCp, seedK, options)
base = isfinite(kReal) & kReal > 0 & isfinite(Cp) & isfinite(residual);
cpResidualTol = getOption(options, 'mrlfeResidualTolerance', 1e-4);

% DP already uses the seed branch as a soft path-cost term. Hard reference
% and smoothness gates must therefore be DP-specific; otherwise the generic
% real-k validation can invalidate a continuous DP-selected path and recreate
% apparent branch switches through gaps.
maxRelK = getOption(options, 'mrlfeA0DPValidationMaxRelativeKDrift', inf);
maxRelCp = getOption(options, 'mrlfeA0DPValidationMaxRelativeCpDrift', inf);

relK = abs(kReal - seedK) ./ max(seedK, eps);
relCp = abs(Cp - seedCp) ./ max(seedCp, eps);
validResidual = base & residual <= cpResidualTol;
validReference = base & relK <= maxRelK & relCp <= maxRelCp;
validSmooth = computeDPSmoothMask(Cp, base, options);
validCp = validResidual & validReference & validSmooth;
end

function validSmooth = computeDPSmoothMask(Cp, base, options)
validSmooth = base & isfinite(Cp);
maxJump = getOption(options, 'mrlfeA0DPValidationMaxCpJumpRelative', inf);
maxPredictionError = getOption(options, 'mrlfeA0DPValidationMaxCpPredictionError', inf);
minPointsForPrediction = getOption(options, 'mrlfeA0DPValidationMinPointsForPrediction', 3);
if ~isfinite(maxJump) && ~isfinite(maxPredictionError)
    return;
end
for i = 2:numel(Cp)
    if ~validSmooth(i) || ~validSmooth(i-1)
        continue;
    end
    relJump = abs(Cp(i) - Cp(i-1)) / max(abs(Cp(i-1)), eps);
    if isfinite(maxJump) && relJump > maxJump
        validSmooth(i) = false;
        continue;
    end
    if isfinite(maxPredictionError) && i >= minPointsForPrediction
        previous = find(validSmooth(1:i-1));
        if numel(previous) >= 2
            p1 = previous(end-1);
            p2 = previous(end);
            step = i - p2;
            prevStep = max(p2 - p1, 1);
            cpPred = Cp(p2) + (Cp(p2) - Cp(p1)) * step / prevStep;
            relPred = abs(Cp(i) - cpPred) / max(abs(cpPred), eps);
            if relPred > maxPredictionError
                validSmooth(i) = false;
            end
        end
    end
end
end

function ranks = getCandidateRanks(candidateRank, candidateIndex)
ranks = nan(size(candidateIndex));
for j = 1:numel(candidateIndex)
    idx = candidateIndex(j);
    if isfinite(idx) && idx >= 1 && idx <= size(candidateRank,1)
        ranks(j) = candidateRank(idx,j);
    end
end
end

function value = getOption(options, fieldName, defaultValue)
if isfield(options, fieldName)
    value = options.(fieldName);
else
    value = defaultValue;
end
end
