function mrlfeResults = computeMRLFE(frequency, material, geometry, rlModes, mrlfeParams, options)
% Compute real-k elastic mRLFE fundamental-like branches.
%
% This prototype uses Rayleigh-Lamb A0/S0 branches as seeds and tracks the
% corresponding mRLFE minima of sigma_min(M)/sigma_max(M) in real k.

if nargin < 6
    options = struct();
end

omega = 2 * pi * frequency;

mrlfeResults = struct();
mrlfeResults.modelName = "mRLFE";
mrlfeResults.description = "Real-k elastic modified Rayleigh-Lamb fluid-loaded prototype.";
mrlfeResults.parameters = mrlfeParams;
mrlfeResults.branches = struct();

if isfield(rlModes, 'A0')
    mrlfeResults.branches.A0Like = computeMRLFEBranch("A0Like", rlModes.A0, omega, material, geometry, mrlfeParams, options);
end

if isfield(rlModes, 'S0')
    mrlfeResults.branches.S0Like = computeMRLFEBranch("S0Like", rlModes.S0, omega, material, geometry, mrlfeParams, options);
end
end

function branch = computeMRLFEBranch(name, seedMode, omega, material, geometry, mrlfeParams, options)
frequency = seedMode.frequency;
seedK = seedMode.k;

k = nan(size(frequency));
residual = nan(size(frequency));

for i = 1:numel(frequency)
    if ~isfinite(seedK(i)) || seedK(i) <= 0
        continue;
    end

    if i >= 2 && isfinite(k(i-1)) && k(i-1) > 0
        kSeed = predictNextK(k, frequency, i);
    else
        kSeed = seedK(i);
    end

    [k(i), residual(i)] = refineRealKRoot(kSeed, omega(i), material, geometry, mrlfeParams, options);
end

Cp = omega ./ k;

branch = struct();
branch.name = name;
branch.family = string(name);
branch.frequency = frequency;
branch.omega = omega;
branch.k = k;
branch.Cp = Cp;
branch.kThickness = k * geometry.thickness;
branch.residual = residual;
branch.valid = isfinite(k) & k > 0 & isfinite(Cp);
branch.note = "mRLFE real-k elastic prototype seeded from Rayleigh-Lamb branch.";
end

function [bestK, bestResidual] = refineRealKRoot(kSeed, omega, material, geometry, mrlfeParams, options)
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

function kPred = predictNextK(k, frequency, idx)
kPred = k(idx-1);
if idx >= 3 && isfinite(k(idx-2)) && isfinite(k(idx-1))
    dfPrev = frequency(idx-1) - frequency(idx-2);
    dfNow = frequency(idx) - frequency(idx-1);
    if dfPrev > 0 && dfNow > 0
        slope = (k(idx-1) - k(idx-2)) / dfPrev;
        candidate = k(idx-1) + slope * dfNow;
        if isfinite(candidate) && candidate > 0
            kPred = candidate;
        end
    end
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
