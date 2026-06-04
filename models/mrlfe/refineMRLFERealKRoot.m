function [bestK, bestResidual] = refineMRLFERealKRoot(kSeed, omega, material, geometry, mrlfeParams, options)
% Refine a real-k mRLFE root candidate around a predicted wavenumber.

searchFactors = getFieldOrDefault(options, 'mrlfeSearchFactors', [0.80 1.25; 0.60 1.60; 0.35 2.50]);
gridPoints = getFieldOrDefault(options, 'mrlfeGridPoints', 500);
resTol = getFieldOrDefault(options, 'mrlfeResidualTolerance', 1e-4);

bestK = nan;
bestResidual = inf;
bestScore = inf;

for s = 1:size(searchFactors, 1)
    kLow = max(eps, searchFactors(s,1) * kSeed);
    kHigh = max(kLow * 1.001, searchFactors(s,2) * kSeed);

    kGrid = linspace(kLow, kHigh, gridPoints);
    rGrid = arrayfun(@(x) mrlfeResidual(x, omega, material, geometry, mrlfeParams), kGrid);
    valid = isfinite(rGrid);
    kGrid = kGrid(valid);
    rGrid = rGrid(valid);
    if numel(kGrid) < 5
        continue;
    end

    candidates = findLocalMinima(rGrid);
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
            relSeed = abs(kCandidate - kSeed) / max(kSeed, eps);
            score = rCandidate * (1 + 0.75 * relSeed);
            if score < bestScore
                bestK = kCandidate;
                bestResidual = rCandidate;
                bestScore = score;
            end
        catch
        end
    end

    if isfinite(bestResidual) && bestResidual < resTol
        break;
    end
end

if isnan(bestK)
    bestK = kSeed;
    bestResidual = mrlfeResidual(bestK, omega, material, geometry, mrlfeParams);
end
end

function idx = findLocalMinima(y)
idx = [];
if numel(y) < 3
    return;
end
for i = 2:numel(y)-1
    if isfinite(y(i)) && y(i) < y(i-1) && y(i) < y(i+1)
        idx(end+1) = i; %#ok<AGROW>
    end
end
if isempty(idx)
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
