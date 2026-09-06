function [Cp, residual] = rlSolveFundamentalBranch(frequency, residualFcn, options)
% Continuation solver for a single fundamental branch.

CpMinAbs = getOption(options, 'minCpAbsolute', 1e-4);
CpMin = max(CpMinAbs, getOption(options, 'minCpRelativeToCT', 1e-3) * options.CT);
CpGlobalMin = CpMin;
CpGlobalMax = max(getOption(options, 'maxCpFactorCT', 20) * options.CT, getOption(options, 'minCpGlobalMax', 1.0));
disallowPredictionFallback = logical(getOption(options, 'disallowPredictionFallback', false));

Cp = nan(size(frequency));
residual = nan(size(frequency));

% Initial broad scan, optionally narrowed by branch-specific physics.
f0 = frequency(1);
[CpInitialMin, CpInitialMax] = initialSearchLimits(CpGlobalMin, CpGlobalMax, options);
CpGrid = linspace(CpInitialMin, CpInitialMax, options.gridPointsInitial);
RGrid = arrayfun(@(x) residualFcn(x, f0), CpGrid);

valid = isfinite(RGrid) & CpGrid > CpMinAbs;
CpGridValid = CpGrid(valid);
RGridValid = RGrid(valid);

if numel(CpGridValid) < 5
    error('Not enough valid points in initial scan.');
end

candidateIdx = findLocalMinima(RGridValid);
bestCp = nan;
bestR = inf;
scoreBest = inf;

for idx = candidateIdx(:).'
    CpLeft = CpGridValid(max(idx - 2, 1));
    CpRight = CpGridValid(min(idx + 2, numel(CpGridValid)));
    if CpRight <= CpLeft, continue; end

    obj = @(x) residualFcn(x, f0);
    try
        CpCandidate = fminbnd(obj, CpLeft, CpRight);
        RCandidate = obj(CpCandidate);
        if CpCandidate > CpMinAbs
            score = localScore(CpCandidate, RCandidate, options, getInitialTarget(options), nan);
            if score < scoreBest
                bestCp = CpCandidate;
                bestR = RCandidate;
                scoreBest = score;
            end
        end
    catch
    end
end

if isnan(bestCp)
    error('Could not refine initial root.');
end

Cp(1) = bestCp;
residual(1) = bestR;

for i = 2:numel(frequency)
    fi = frequency(i);
    CpPrev = Cp(i - 1);
    if isnan(CpPrev), break; end

    CpPred = predictNextCp(Cp, frequency, i);
    searchFactors = getOption(options, 'searchFactors', [0.75, 1.25; 0.50, 1.60; 0.30, 2.20; 0.10, 4.00]);
    bestCp = nan;
    bestR = inf;
    scoreBest = inf;

    for s = 1:size(searchFactors, 1)
        CpLow = max(CpGlobalMin, searchFactors(s, 1) * CpPred);
        CpHigh = min(CpGlobalMax, searchFactors(s, 2) * CpPred);
        if CpHigh <= CpLow, continue; end

        CpGrid = linspace(CpLow, CpHigh, options.gridPointsTracking);
        RGrid = arrayfun(@(x) residualFcn(x, fi), CpGrid);

        valid = isfinite(RGrid) & CpGrid > CpMinAbs;
        CpGridValid = CpGrid(valid);
        RGridValid = RGrid(valid);
        if numel(CpGridValid) < 5, continue; end

        candidateIdx = findLocalMinima(RGridValid);
        for idx = candidateIdx(:).'
            CpLeft = CpGridValid(max(idx - 2, 1));
            CpRight = CpGridValid(min(idx + 2, numel(CpGridValid)));
            if CpRight <= CpLeft, continue; end

            obj = @(x) residualFcn(x, fi);
            try
                CpCandidate = fminbnd(obj, CpLeft, CpRight);
                RCandidate = obj(CpCandidate);
                relJump = abs(CpCandidate - CpPrev) / max(CpPrev, eps);
                relPrediction = abs(CpCandidate - CpPred) / max(CpPred, eps);
                if CpCandidate > CpMinAbs && relJump < options.jumpTol && relPrediction <= getOption(options, 'maxPredictionRelativeError', inf)
                    score = localScore(CpCandidate, RCandidate, options, CpPred, CpPrev);
                    if score < scoreBest
                        bestCp = CpCandidate;
                        bestR = RCandidate;
                        scoreBest = score;
                    end
                end
            catch
            end
        end

        if ~isnan(bestCp) && bestR < options.residualTolerance
            break;
        end
    end

    if isnan(bestCp)
        if disallowPredictionFallback
            break;
        end
        bestCp = CpPred;
        bestR = residualFcn(bestCp, fi);
    end

    Cp(i) = bestCp;
    residual(i) = bestR;
end

[Cp, residual] = suppressIsolatedSpikes(Cp, residual, options);
end

function [CpMin, CpMax] = initialSearchLimits(CpGlobalMin, CpGlobalMax, options)
CpMin = CpGlobalMin;
CpMax = CpGlobalMax;
if isfield(options, 'initialSearchRange') && numel(options.initialSearchRange) == 2 && ...
        all(isfinite(options.initialSearchRange)) && options.initialSearchRange(2) > options.initialSearchRange(1)
    CpMin = max(CpGlobalMin, options.initialSearchRange(1));
    CpMax = min(CpGlobalMax, options.initialSearchRange(2));
    if CpMax <= CpMin
        CpMin = CpGlobalMin;
        CpMax = CpGlobalMax;
    end
end
end

function target = getInitialTarget(options)
target = nan;
if isfield(options, 'initialCpGuess') && isfinite(options.initialCpGuess) && options.initialCpGuess > 0
    target = options.initialCpGuess;
end
end

function CpPred = predictNextCp(Cp, frequency, idx)
CpPred = Cp(idx - 1);
if idx >= 3 && isfinite(Cp(idx - 2)) && isfinite(Cp(idx - 1))
    dfPrev = frequency(idx - 1) - frequency(idx - 2);
    dfNow = frequency(idx) - frequency(idx - 1);
    if dfPrev > 0 && dfNow > 0
        slope = (Cp(idx - 1) - Cp(idx - 2)) / dfPrev;
        candidate = Cp(idx - 1) + slope * dfNow;
        if isfinite(candidate) && candidate > 0
            CpPred = candidate;
        end
    end
end
end

function score = localScore(CpCandidate, RCandidate, options, targetCp, previousCp)
score = RCandidate;
if nargin >= 4 && isfinite(targetCp) && targetCp > 0
    rel = abs(CpCandidate - targetCp) / targetCp;
    score = score * (1 + getOption(options, 'predictionWeight', 0.50) * rel);
end
if nargin >= 5 && isfinite(previousCp) && previousCp > 0
    relPrev = abs(CpCandidate - previousCp) / previousCp;
    score = score * (1 + getOption(options, 'preferPreviousRootWeight', 0.50) * relPrev);
end
if isfield(options, 'preferLowestCp') && options.preferLowestCp
    score = score * (1 + 0.01 * CpCandidate / max(options.CT, eps));
end
end

function [CpOut, residualOut] = suppressIsolatedSpikes(Cp, residual, options)
CpOut = Cp;
residualOut = residual;
threshold = getOption(options, 'maxSinglePointSpikeRelative', inf);
if ~isfinite(threshold)
    return;
end

for i = 2:numel(Cp)-1
    if ~isfinite(Cp(i-1)) || ~isfinite(Cp(i)) || ~isfinite(Cp(i+1))
        continue;
    end
    neighborMean = 0.5 * (Cp(i-1) + Cp(i+1));
    if neighborMean <= 0
        continue;
    end
    relSpike = abs(Cp(i) - neighborMean) / neighborMean;
    neighborSlopeSign = sign(Cp(i+1) - Cp(i-1));
    spikeSignLeft = sign(Cp(i) - Cp(i-1));
    spikeSignRight = sign(Cp(i) - Cp(i+1));
    isPeakOrDip = spikeSignLeft == spikeSignRight && spikeSignLeft ~= 0;
    if relSpike > threshold && isPeakOrDip && abs(neighborSlopeSign) <= 1
        CpOut(i) = neighborMean;
        residualOut(i) = max(residual(i-1), residual(i+1));
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

function idx = findLocalMinima(y)
idx = [];
if numel(y) < 3, return; end
for i = 2:numel(y)-1
    if isfinite(y(i)) && y(i) < y(i-1) && y(i) < y(i+1)
        idx(end+1) = i; %#ok<AGROW>
    end
end
if isempty(idx)
    [~, minIdx] = min(y);
    idx = minIdx;
end
end
