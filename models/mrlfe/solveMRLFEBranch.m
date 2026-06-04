function branch = solveMRLFEBranch(name, seedMode, material, geometry, mrlfeParams, options)
% Track one real-k elastic mRLFE fundamental-like branch.
%
% The branch is seeded from a Rayleigh-Lamb mode and refined by minimizing
% the normalized singular-value residual sigma_min(M)/sigma_max(M).

frequency = seedMode.frequency;
omega = seedMode.omega;
seedK = seedMode.k;

k = nan(size(frequency));
residual = nan(size(frequency));

for i = 1:numel(frequency)
    if ~isfinite(seedK(i)) || seedK(i) <= 0
        continue;
    end

    if i >= 2 && isfinite(k(i-1)) && k(i-1) > 0
        kSeed = predictMRLFEK(k, frequency, i);
    else
        kSeed = seedK(i);
    end

    [k(i), residual(i)] = refineMRLFERealKRoot(kSeed, omega(i), material, geometry, mrlfeParams, options);
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

function kPred = predictMRLFEK(k, frequency, idx)
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
