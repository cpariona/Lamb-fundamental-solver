function branch = solveMRLFEBranch(name, seedMode, material, geometry, mrlfeParams, options)
% Track one mRLFE fundamental-like branch.
%
% The branch is seeded from a Rayleigh-Lamb mode and refined by minimizing
% the normalized singular-value residual sigma_min(M)/sigma_max(M).

frequency = seedMode.frequency;
omega = seedMode.omega;
seedK = seedMode.k;
solveComplexK = isfield(mrlfeParams, 'solveComplexK') && mrlfeParams.solveComplexK;

k = nan(size(frequency));
residual = nan(size(frequency));

for i = 1:numel(frequency)
    if ~isfinite(seedK(i)) || seedK(i) <= 0
        continue;
    end

    if i >= 2 && isfinite(real(k(i-1))) && real(k(i-1)) > 0
        kSeed = predictMRLFEK(k, frequency, i);
    else
        kSeed = seedK(i);
    end

    if solveComplexK
        [k(i), residual(i)] = refineMRLFEComplexKRoot(kSeed, omega(i), material, geometry, mrlfeParams, options);
    else
        [k(i), residual(i)] = refineMRLFERealKRoot(real(kSeed), omega(i), material, geometry, mrlfeParams, options);
    end
end

kReal = real(k);
kImag = imag(k);
Cp = omega ./ kReal;

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
branch.kThickness = kReal * geometry.thickness;
branch.residual = residual;
branch.valid = isfinite(kReal) & kReal > 0 & isfinite(Cp);
if solveComplexK
    branch.note = "mRLFE complex-k prototype seeded from Rayleigh-Lamb branch.";
else
    branch.note = "mRLFE real-k elastic prototype seeded from Rayleigh-Lamb branch.";
end
end

function kPred = predictMRLFEK(k, frequency, idx)
kPred = k(idx-1);
if idx >= 3 && isfinite(real(k(idx-2))) && isfinite(real(k(idx-1)))
    dfPrev = frequency(idx-1) - frequency(idx-2);
    dfNow = frequency(idx) - frequency(idx-1);
    if dfPrev > 0 && dfNow > 0
        slopeReal = (real(k(idx-1)) - real(k(idx-2))) / dfPrev;
        slopeImag = (imag(k(idx-1)) - imag(k(idx-2))) / dfPrev;
        candidate = k(idx-1) + (slopeReal + 1i * slopeImag) * dfNow;
        if isfinite(real(candidate)) && real(candidate) > 0
            kPred = candidate;
        end
    end
end
end
