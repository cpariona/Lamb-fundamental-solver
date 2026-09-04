function branch = mrlfeTrackBranchAdaptive(problem, seedMode, configuration, mrlfeParams, options)
%MRLFETRACKBRANCHADAPTIVE Track an mRLFE branch with local adaptive Cp windows.
%
% This tracker uses the supplied fast seed only to start the branch and define
% a physical fallback scale. After the first accepted points, each frequency is
% searched around the previous mRLFE point or a linear prediction from the last
% two accepted points. The local window expands only when no acceptable local
% minimum is found. Once a stable branch has been established, a tracking loss
% cuts the remaining tail instead of reinitializing from the seed and jumping to
% another branch.
%
% Optional valley fallback:
%   Some physical branches become shallow shoulders rather than strict local
%   minima. When enabled, the tracker adds a prediction-centered candidate from
%   a narrow trust region around the predicted Cp. This fallback is allowed only
%   after the branch has already been established by strict accepted points, so
%   it cannot initialize the branch on a low-Cp residual artifact.

name = configuration.branch;
material = problem.material;
geometry = problem.geometry;

frequency = seedMode.frequency(:);
omega = seedMode.omega(:);
seedCp = seedMode.Cp(:);
numFreq = numel(frequency);

tracker = buildAdaptiveOptions(options);

Cp = nan(numFreq,1);
kReal = nan(numFreq,1);
residual = nan(numFreq,1);
score = nan(numFreq,1);
validCp = false(numFreq,1);
validResidual = false(numFreq,1);
validReference = false(numFreq,1);
validSmooth = false(numFreq,1);
windowUsed = nan(numFreq,1);
candidateRank = nan(numFreq,1);
numCandidates = zeros(numFreq,1);
centerCp = nan(numFreq,1);
candidateType = strings(numFreq,1);
candidateType(:) = "none";
cutIndex = nan;
cutReason = "none";

validRunLength = 0;
branchEstablished = false;

for j = 1:numFreq
    center = chooseCenterCp(j, Cp, seedCp, branchEstablished, tracker);
    centerCp(j) = center;
    [best, usedWindow] = findAdaptiveCandidate(center, omega(j), material, geometry, mrlfeParams, tracker, branchEstablished);
    windowUsed(j) = usedWindow;
    numCandidates(j) = best.numCandidates;

    if ~best.valid
        if tracker.cutAfterEstablishedLoss && branchEstablished
            cutIndex = j;
            cutReason = "missing_candidate_after_established_branch";
            break;
        end
        validRunLength = 0;
        continue;
    end

    Cp(j) = best.cp;
    kReal(j) = omega(j) / best.cp;
    residual(j) = best.residual;
    candidateRank(j) = best.rank;
    candidateType(j) = best.type;
    score(j) = best.score;

    validResidual(j) = isfinite(best.residual) && best.residual <= tracker.residualTolerance;
    validReference(j) = isfinite(best.cp) && best.cp > 0;
    validSmooth(j) = isSmoothContinuation(j, Cp, tracker);
    validCp(j) = validResidual(j) && validReference(j) && validSmooth(j);

    if validCp(j)
        validRunLength = validRunLength + 1;
        branchEstablished = branchEstablished || validRunLength >= tracker.establishedMinValidRun;
    else
        Cp(j) = nan;
        kReal(j) = nan;
        residual(j) = nan;
        score(j) = nan;
        candidateRank(j) = nan;
        candidateType(j) = "none";
        validRunLength = 0;
        if tracker.cutAfterEstablishedLoss && branchEstablished
            cutIndex = j;
            if ~validResidual(j)
                cutReason = "residual_rejected_after_established_branch";
            elseif ~validSmooth(j)
                cutReason = "smoothness_rejected_after_established_branch";
            else
                cutReason = "invalid_candidate_after_established_branch";
            end
            break;
        end
    end
end

kImag = zeros(size(kReal));
k = kReal;
kThickness = kReal * geometry.thickness;
valid = validCp;

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
branch.seedCp = seedCp;
branch.seedK = omega ./ seedCp;
branch.validResidual = validResidual;
branch.validReference = validReference;
branch.validSmooth = validSmooth;
branch.validCp = validCp;
branch.valid = valid;
branch.candidateIndex = ones(numFreq,1);
branch.candidateIndex(~validCp) = nan;
branch.candidateRank = candidateRank;
branch.candidateType = candidateType;
branch.adaptiveWindowUsed = windowUsed;
branch.adaptiveCenterCp = centerCp;
branch.adaptiveCandidateCount = numCandidates;
branch.dpOptions = tracker;
branch.usedGuideBranch = false;
branch.adaptiveCut = struct( ...
    'PolicyName', "adaptiveContinuationCut", ...
    'CutAfterEstablishedLoss', tracker.cutAfterEstablishedLoss, ...
    'EstablishedMinValidRun', tracker.establishedMinValidRun, ...
    'FirstCutIndex', cutIndex, ...
    'FirstCutFrequency', getCutFrequency(frequency, cutIndex), ...
    'CutReason', cutReason, ...
    'ValidPointsAfterCut', nnz(validCp));
branch.note = "mRLFE branch tracked with adaptive local Cp windows.";
end

function tracker = buildAdaptiveOptions(options)
tracker = struct();
tracker.cpScanPoints = getOption(options, 'trackerCpScanPoints', 900);
tracker.edgeGuardPoints = getOption(options, 'trackerEdgeGuardPoints', 4);
tracker.windows = getOption(options, 'trackerWindows', [0.12 0.20 0.35 0.50]);
tracker.cpMinFloor = getOption(options, 'trackerCpMinFloor', 0.05);
tracker.cpMaxCeiling = getOption(options, 'trackerCpMaxCeiling', 80);
tracker.residualTolerance = getOption(options, 'residualTolerance', 1e-3);
tracker.residualFloor = getOption(options, 'residualFloor', 1e-14);
tracker.residualWeight = getOption(options, 'trackerResidualWeight', 0.35);
tracker.predictionWeight = getOption(options, 'trackerPredictionWeight', 55.0);
tracker.maxJumpRelative = getOption(options, 'trackerMaxJumpRelative', 0.18);
tracker.maxPredictionError = getOption(options, 'trackerMaxPredictionError', 0.18);
tracker.refineCandidates = getOption(options, 'trackerRefineCandidates', true);
tracker.refineTolX = getOption(options, 'trackerRefinementTolerance', 1e-6);
tracker.refineMaxIter = getOption(options, 'trackerRefinementMaxIterations', 24);
tracker.refineMaxFunEvals = getOption(options, 'trackerRefinementMaxEvaluations', 60);
tracker.cutAfterEstablishedLoss = getOption(options, 'trackerCutAfterEstablishedLoss', true);
tracker.establishedMinValidRun = getOption(options, 'trackerEstablishedMinValidRun', 8);
tracker.allowValleyFallback = getOption(options, 'trackerAllowValleyFallback', false);
tracker.valleyFallbackRelativeWindow = getOption(options, 'trackerValleyFallbackRelativeWindow', 0.08);
tracker.valleyFallbackResidualTolerance = getOption(options, 'trackerValleyFallbackResidualTolerance', tracker.residualTolerance);
tracker.valleyFallbackPredictionWeight = getOption(options, 'trackerValleyFallbackPredictionWeight', tracker.predictionWeight);
tracker.valleyFallbackResidualWeight = getOption(options, 'trackerValleyFallbackResidualWeight', tracker.residualWeight);
end

function center = chooseCenterCp(j, Cp, seedCp, branchEstablished, tracker)
if j >= 3 && isfinite(Cp(j-1)) && isfinite(Cp(j-2))
    center = Cp(j-1) + (Cp(j-1) - Cp(j-2));
elseif j >= 2 && isfinite(Cp(j-1))
    center = Cp(j-1);
elseif ~branchEstablished && isfinite(seedCp(j)) && seedCp(j) > 0
    center = seedCp(j);
else
    if branchEstablished && tracker.cutAfterEstablishedLoss
        center = nan;
        return;
    end
    validSeed = seedCp(isfinite(seedCp) & seedCp > 0);
    if isempty(validSeed)
        center = 1;
    else
        center = median(validSeed);
    end
end
center = max(center, eps);
end

function [best, usedWindow] = findAdaptiveCandidate(center, omega, material, geometry, mrlfeParams, tracker, branchEstablished)
best = emptyCandidate();
usedWindow = nan;
if ~isfinite(center) || center <= 0
    return;
end
for i = 1:numel(tracker.windows)
    width = tracker.windows(i);
    cpMin = max(tracker.cpMinFloor, center * (1 - width));
    cpMax = min(tracker.cpMaxCeiling, center * (1 + width));
    if cpMax <= cpMin
        continue;
    end
    CpScan = linspace(cpMin, cpMax, tracker.cpScanPoints);
    residual = computeResidualVsCp(CpScan, omega, material, geometry, mrlfeParams);
    candidates = findCandidates(CpScan, residual, omega, material, geometry, mrlfeParams, tracker);
    if tracker.allowValleyFallback && branchEstablished
        candidates = appendValleyFallbackCandidate(candidates, CpScan, residual, center, tracker);
    end
    if isempty(candidates.cp)
        continue;
    end
    best = chooseBestCandidate(candidates, center, tracker);
    best.numCandidates = numel(candidates.cp);
    usedWindow = width;
    return;
end
end

function residual = computeResidualVsCp(CpScan, omega, material, geometry, mrlfeParams)
residual = nan(size(CpScan));
for i = 1:numel(CpScan)
    cp = CpScan(i);
    if isfinite(cp) && cp > 0
        residual(i) = mrlfeResidual(omega / cp, omega, material, geometry, mrlfeParams);
    end
end
end

function candidates = findCandidates(CpScan, residual, omega, material, geometry, mrlfeParams, tracker)
idx = [];
firstAllowed = 1 + tracker.edgeGuardPoints;
lastAllowed = numel(residual) - tracker.edgeGuardPoints;
for i = max(2, firstAllowed):min(numel(residual)-1, lastAllowed)
    if isfinite(residual(i)) && residual(i) < residual(i-1) && residual(i) < residual(i+1)
        idx(end+1) = i; %#ok<AGROW>
    end
end
if isempty(idx)
    candidates = emptyCandidates();
    return;
end
[~, order] = sort(residual(idx), 'ascend');
idx = idx(order);
cp = CpScan(idx);
res = residual(idx);
if tracker.refineCandidates
    [cp, res] = refineCandidates(CpScan, idx, omega, material, geometry, mrlfeParams, tracker);
    [~, order] = sort(res, 'ascend');
    cp = cp(order);
    res = res(order);
end
candidates.cp = cp(:);
candidates.residual = res(:);
candidates.type = repmat("localMinimum", numel(candidates.cp), 1);
end

function candidates = appendValleyFallbackCandidate(candidates, CpScan, residual, center, tracker)
mask = isfinite(residual) & residual > 0 & residual <= tracker.valleyFallbackResidualTolerance;
trust = abs(CpScan - center) ./ max(abs(center), eps) <= tracker.valleyFallbackRelativeWindow;
idx = find(mask & trust);
if isempty(idx)
    return;
end
score = nan(size(idx));
for n = 1:numel(idx)
    cp = CpScan(idx(n));
    predTerm = abs(cp - center) / max(abs(center), eps);
    resTerm = log10(max(residual(idx(n)), tracker.residualFloor));
    score(n) = tracker.valleyFallbackResidualWeight * resTerm + tracker.valleyFallbackPredictionWeight * predTerm.^2;
end
[~, bestLocal] = min(score);
bestIdx = idx(bestLocal);

cpCandidate = CpScan(bestIdx);
resCandidate = residual(bestIdx);
if isempty(candidates.cp)
    candidates.cp = cpCandidate;
    candidates.residual = resCandidate;
    candidates.type = "valleyFallback";
else
    candidates.cp(end+1,1) = cpCandidate;
    candidates.residual(end+1,1) = resCandidate;
    candidates.type(end+1,1) = "valleyFallback";
end
end

function [cpRefined, residualRefined] = refineCandidates(CpScan, idx, omega, material, geometry, mrlfeParams, tracker)
cpRefined = CpScan(idx);
residualRefined = nan(size(cpRefined));
opt = optimset('Display', 'off', 'TolX', tracker.refineTolX, ...
    'MaxIter', tracker.refineMaxIter, 'MaxFunEvals', tracker.refineMaxFunEvals);
for n = 1:numel(idx)
    i = idx(n);
    lower = CpScan(max(i-1,1));
    upper = CpScan(min(i+1,numel(CpScan)));
    objective = @(cp) mrlfeResidual(omega / cp, omega, material, geometry, mrlfeParams);
    try
        [cpBest, residualBest] = fminbnd(objective, lower, upper, opt);
        cpRefined(n) = cpBest;
        residualRefined(n) = residualBest;
    catch
        cpRefined(n) = CpScan(i);
        residualRefined(n) = objective(cpRefined(n));
    end
end
end

function best = chooseBestCandidate(candidates, center, tracker)
best = emptyCandidate();
score = nan(size(candidates.cp));
for i = 1:numel(candidates.cp)
    predTerm = abs(candidates.cp(i) - center) / max(abs(center), eps);
    resTerm = log10(max(candidates.residual(i), tracker.residualFloor));
    score(i) = tracker.residualWeight * resTerm + tracker.predictionWeight * predTerm.^2;
end
[bestScore, idx] = min(score);
best.valid = isfinite(bestScore);
if best.valid
    best.cp = candidates.cp(idx);
    best.residual = candidates.residual(idx);
    best.rank = idx;
    best.score = bestScore;
    best.type = candidates.type(idx);
end
end

function tf = isSmoothContinuation(j, Cp, tracker)
tf = isfinite(Cp(j)) && Cp(j) > 0;
if ~tf || j < 2 || ~isfinite(Cp(j-1))
    return;
end
jump = abs(Cp(j) - Cp(j-1)) / max(abs(Cp(j-1)), eps);
if jump > tracker.maxJumpRelative
    tf = false;
    return;
end
if j >= 3 && isfinite(Cp(j-2))
    pred = Cp(j-1) + (Cp(j-1) - Cp(j-2));
    predErr = abs(Cp(j) - pred) / max(abs(pred), eps);
    if predErr > tracker.maxPredictionError
        tf = false;
    end
end
end

function f = getCutFrequency(frequency, cutIndex)
if isfinite(cutIndex) && cutIndex >= 1 && cutIndex <= numel(frequency)
    f = frequency(cutIndex);
else
    f = nan;
end
end

function c = emptyCandidate()
c = struct('valid', false, 'cp', nan, 'residual', nan, 'rank', nan, 'score', nan, 'numCandidates', 0, 'type', "none");
end

function candidates = emptyCandidates()
candidates = struct();
candidates.cp = [];
candidates.residual = [];
candidates.type = strings(0,1);
end

function value = getOption(options, fieldName, defaultValue)
if isstruct(options) && isfield(options, fieldName) && ~isempty(options.(fieldName))
    value = options.(fieldName);
else
    value = defaultValue;
end
end
