function branch = solveMRLFEBranch(name, seedMode, material, geometry, mrlfeParams, options)
% Track one mRLFE fundamental-like branch.
%
% The branch is seeded from either a Rayleigh-Lamb mode or a real-k mRLFE
% mode and refined by minimizing sigma_min(M)/sigma_max(M).

frequency = seedMode.frequency;
omega = seedMode.omega;
if isfield(seedMode, 'kReal')
    seedK = seedMode.kReal;
else
    seedK = real(seedMode.k);
end
solveComplexK = isfield(mrlfeParams, 'solveComplexK') && mrlfeParams.solveComplexK;

k = nan(size(frequency));
residual = nan(size(frequency));
seedCp = omega ./ seedK;

for i = 1:numel(frequency)
    if ~isfinite(seedK(i)) || seedK(i) <= 0
        continue;
    end

    if i >= 2 && isfinite(real(k(i-1))) && real(k(i-1)) > 0
        kPred = predictMRLFEK(k, frequency, i);
    else
        kPred = seedK(i);
    end

    if solveComplexK
        physicalReference = struct();
        physicalReference.k = seedK(i);
        physicalReference.Cp = seedCp(i);
        [k(i), residual(i)] = refineMRLFEComplexKRoot(kPred, omega(i), material, geometry, mrlfeParams, options, physicalReference);
    else
        [k(i), residual(i)] = refineMRLFERealKRoot(real(kPred), omega(i), material, geometry, mrlfeParams, options);
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
branch.seedK = seedK;
branch.seedCp = seedCp;
branch.valid = isfinite(kReal) & kReal > 0 & isfinite(Cp);
if solveComplexK
    branch.note = "mRLFE complex-k prototype seeded from real-k reference when available.";
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
