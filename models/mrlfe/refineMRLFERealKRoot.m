function [bestK, bestResidual, bestScore] = refineMRLFERealKRoot(kSeed, omega, material, geometry, mrlfeParams, options)
% Refine a real-k mRLFE root candidate around a predicted/reference wavenumber.
%
% The raw residual is sigma_min(M)/sigma_max(M). Candidate selection can be
% residual-driven or modal-tracking driven. Modal scoring penalizes distance
% from the seed/predicted branch so the solver does not automatically switch
% to a lower-residual valley that belongs to another modal family.

searchFactors = getFieldOrDefault(options, 'mrlfeSearchFactors', [0.80 1.25; 0.60 1.60; 0.35 2.50]);
gridPoints = getFieldOrDefault(options, 'mrlfeGridPoints', 500);
resTol = getFieldOrDefault(options, 'mrlfeResidualTolerance', 1e-4);
referenceWeight = getFieldOrDefault(options, 'mrlfeRealKReferenceWeight', 0.75);
predictionWeight = getFieldOrDefault(options, 'mrlfeRealKPredictionWeight', 0.0);
residualFloor = getFieldOrDefault(options, 'mrlfeRealKResidualFloor', 1e-14);
scoreMode = lower(string(getFieldOrDefault(options, 'mrlfeRealKScoreMode', "residual")));
requireLocalMinimum = getFieldOrDefault(options, 'mrlfeRealKRequireLocalMinimum', false);
maxRelativeDrift = getFieldOrDefault(options, 'mrlfeRealKMaxRelativeKDrift', inf);
hardWindow = getFieldOrDefault(options, 'mrlfeRealKHardReferenceWindow', false);

if ~isfinite(predictionWeight)
    predictionWeight = 0;
end
if ~isfinite(referenceWeight)
    referenceWeight = 0;
end
if ~isfinite(residualFloor) || residualFloor <= 0
    residualFloor = 1e-14;
end

bestK = nan;
bestResidual = inf;
bestScore = inf;

for s = 1:size(searchFactors, 1)
    kLow = max(eps, searchFactors(s,1) * kSeed);
    kHigh = max(kLow * 1.001, searchFactors(s,2) * kSeed);

    if isfinite(maxRelativeDrift)
        refLow = max(eps, (1 - maxRelativeDrift) * kSeed);
        refHigh = (1 + maxRelativeDrift) * kSeed;
        if hardWindow
            kLow = max(kLow, refLow);
            kHigh = min(kHigh, refHigh);
        end
        if kHigh <= kLow
            continue;
        end
    end

    kGrid = linspace(kLow, kHigh, gridPoints);
    rGrid = arrayfun(@(x) mrlfeResidual(x, omega, material, geometry, mrlfeParams), kGrid);
    valid = isfinite(rGrid);
    kGrid = kGrid(valid);
    rGrid = rGrid(valid);
    if numel(kGrid) < 5
        continue;
    end

    candidates = findLocalMinima(rGrid, requireLocalMinimum);
    for idx = candidates(:).'
        kLeft = kGrid(max(1, idx-2));
        kRight = kGrid(min(numel(kGrid), idx+2));
        if kRight <= kLeft
            continue;
        end
        obj = @(x) mrlfeResidual(x, omega, material, geometry, mrlfeParams);
        try
            kCandidate = fminbnd(obj, kLeft, kRight);
            rCandidate = obj(kCandidate);
            if ~isfinite(rCandidate)
                continue;
            end
            relSeed = abs(kCandidate - kSeed) / max(kSeed, eps);
            if isfinite(maxRelativeDrift) && relSeed > maxRelativeDrift
                continue;
            end
            score = computeScore(rCandidate, relSeed, referenceWeight, predictionWeight, residualFloor, scoreMode);
            if score < bestScore
                bestK = kCandidate;
                bestResidual = rCandidate;
                bestScore = score;
            end
        catch
        end
    end

    if isfinite(bestResidual) && bestResidual < resTol && scoreMode == "residual"
        break;
    end
end

if isnan(bestK)
    bestK = kSeed;
    bestResidual = mrlfeResidual(bestK, omega, material, geometry, mrlfeParams);
    relSeed = 0;
    bestScore = computeScore(bestResidual, relSeed, referenceWeight, predictionWeight, residualFloor, scoreMode);
end
end

function score = computeScore(residual, relSeed, referenceWeight, predictionWeight, residualFloor, scoreMode)
penalty = referenceWeight * relSeed.^2 + predictionWeight * relSeed;
switch scoreMode
    case "modal"
        score = log10(max(residual, residualFloor)) + penalty;
    otherwise
        score = residual * (1 + penalty);
end
end

function idx = findLocalMinima(y, requireLocalMinimum)
idx = [];
if numel(y) < 3
    return;
end
for i = 2:numel(y)-1
    if isfinite(y(i)) && y(i) < y(i-1) && y(i) < y(i+1)
        idx(end+1) = i; %#ok<AGROW>
    end
end
if isempty(idx) && ~requireLocalMinimum
    [~, idx] = min(y);
end
end

function value = getFieldOrDefault(s, name, defaultValue)
if isfield(s, name)
    value = s.(name);
else
    value = defaultValue;
end
end
