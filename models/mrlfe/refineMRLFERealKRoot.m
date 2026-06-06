function [bestK, bestResidual, bestScore] = refineMRLFERealKRoot(kSeed, omega, material, geometry, mrlfeParams, options)
% Refine a real-k mRLFE root candidate around a predicted/reference wavenumber.
%
% The raw residual is sigma_min(M)/sigma_max(M). Candidate selection can be
% residual-driven or modal-tracking driven. Modal scoring penalizes distance
% from the seed/predicted branch so the solver does not automatically switch
% to a lower-residual valley that belongs to another modal family.
%
% If mrlfeRealKRequireLocalMinimum is true, this function does not fall back
% to kSeed when no local residual minimum is found. It returns NaN/Inf so the
% branch is cut instead of silently plotting the reference curve as a solution.
%
% Optional Cp-domain modal windows can be enabled through
% mrlfeRealKUseModalCpWindow.  This is intended for Han real-k tracking, where
% the global residual minimum may sit on a non-modal low-Cp edge valley.

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
useModalCpWindow = getFieldOrDefault(options, 'mrlfeRealKUseModalCpWindow', false);
modalCpLowerFactor = getFieldOrDefault(options, 'mrlfeRealKModalCpLowerFactor', 0.35);
modalCpUpperFactor = getFieldOrDefault(options, 'mrlfeRealKModalCpUpperFactor', 2.50);

if ~isfinite(predictionWeight)
    predictionWeight = 0;
end
if ~isfinite(referenceWeight)
    referenceWeight = 0;
end
if ~isfinite(residualFloor) || residualFloor <= 0
    residualFloor = 1e-14;
end

seedCp = omega / kSeed;
if useModalCpWindow && (~isfinite(seedCp) || seedCp <= 0 || ...
        ~isfinite(modalCpLowerFactor) || ~isfinite(modalCpUpperFactor) || ...
        modalCpLowerFactor <= 0 || modalCpUpperFactor <= modalCpLowerFactor)
    bestK = nan;
    bestResidual = inf;
    bestScore = inf;
    return;
end

bestK = nan;
bestResidual = inf;
bestScore = inf;
foundCandidate = false;

for s = 1:size(searchFactors, 1)
    kLow = max(eps, searchFactors(s,1) * kSeed);
    kHigh = max(kLow * 1.001, searchFactors(s,2) * kSeed);

    if useModalCpWindow
        cpLow = modalCpLowerFactor * seedCp;
        cpHigh = modalCpUpperFactor * seedCp;
        kFromCpHigh = omega / cpHigh;
        kFromCpLow = omega / cpLow;
        kLow = max(kLow, min(kFromCpHigh, kFromCpLow));
        kHigh = min(kHigh, max(kFromCpHigh, kFromCpLow));
    end

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

    if kHigh <= kLow
        continue;
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
            cpCandidate = omega / kCandidate;
            if useModalCpWindow && ~isInsideModalCpWindow(cpCandidate, seedCp, modalCpLowerFactor, modalCpUpperFactor)
                continue;
            end
            relSeed = abs(kCandidate - kSeed) / max(kSeed, eps);
            if isfinite(maxRelativeDrift) && relSeed > maxRelativeDrift
                continue;
            end
            foundCandidate = true;
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
    if requireLocalMinimum && ~foundCandidate
        bestK = nan;
        bestResidual = inf;
        bestScore = inf;
        return;
    end
    bestK = kSeed;
    bestResidual = mrlfeResidual(bestK, omega, material, geometry, mrlfeParams);
    relSeed = 0;
    bestScore = computeScore(bestResidual, relSeed, referenceWeight, predictionWeight, residualFloor, scoreMode);
end
end

function tf = isInsideModalCpWindow(cpCandidate, seedCp, lowerFactor, upperFactor)
cpLow = lowerFactor * seedCp;
cpHigh = upperFactor * seedCp;
tf = isfinite(cpCandidate) && cpCandidate >= cpLow && cpCandidate <= cpHigh;
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
