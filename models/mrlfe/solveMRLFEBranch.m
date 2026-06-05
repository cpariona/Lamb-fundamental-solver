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
score = nan(size(frequency));
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
        physicalReference.kImagPred = max(imag(kPred), 0);
        [k(i), residual(i), score(i)] = refineMRLFEComplexKRoot(kPred, omega(i), material, geometry, mrlfeParams, options, physicalReference);
    else
        [k(i), residual(i)] = refineMRLFERealKRoot(real(kPred), omega(i), material, geometry, mrlfeParams, options);
        score(i) = residual(i);
    end
end

kReal = real(k);
kImag = imag(k);
Cp = omega ./ kReal;
kThickness = kReal * geometry.thickness;

[validCp, validAttenuation] = computeBranchValidity(Cp, kReal, kImag, residual, seedCp, seedK, solveComplexK, options);

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
branch.validCp = validCp;
branch.validAttenuation = validAttenuation;
branch.valid = validCp;
if solveComplexK
    branch.note = "mRLFE complex-k prototype seeded from real-k reference when available.";
else
    branch.note = "mRLFE real-k elastic prototype seeded from Rayleigh-Lamb branch.";
end
end

function [validCp, validAttenuation] = computeBranchValidity(Cp, kReal, kImag, residual, seedCp, seedK, solveComplexK, options)
base = isfinite(kReal) & kReal > 0 & isfinite(Cp) & isfinite(residual);

if solveComplexK
    cpResidualTol = getOption(options, 'mrlfeComplexCpResidualTolerance', 1e-4);
    maxRelK = getOption(options, 'mrlfeComplexMaxRelativeKDrift', 0.25);
    maxRelCp = getOption(options, 'mrlfeComplexMaxRelativeCpDrift', 0.30);
else
    cpResidualTol = getOption(options, 'mrlfeResidualTolerance', 1e-4);
    maxRelK = inf;
    maxRelCp = inf;
end

relK = abs(kReal - seedK) ./ max(seedK, eps);
relCp = abs(Cp - seedCp) ./ max(seedCp, eps);
validCp = base & residual <= cpResidualTol & relK <= maxRelK & relCp <= maxRelCp;

if ~solveComplexK
    validAttenuation = false(size(validCp));
    return;
end

attResidualTol = getOption(options, 'mrlfeComplexAttenuationResidualTolerance', 1e-5);
maxLossFactor = getOption(options, 'mrlfeComplexMaxLossFactor', 1e-2);
maxJumpRel = getOption(options, 'mrlfeComplexMaxAttenuationJumpRelative', 5.0);
maxJumpLoss = getOption(options, 'mrlfeComplexMaxAttenuationJumpLossFactor', 5e-3);

lossFactor = kImag ./ max(kReal, eps);
validAttenuation = validCp & isfinite(kImag) & kImag >= 0 & ...
    residual <= attResidualTol & lossFactor <= maxLossFactor;

for i = 2:numel(validAttenuation)
    if ~validAttenuation(i) || ~isfinite(kImag(i-1)) || ~isfinite(kImag(i))
        continue;
    end
    scale = max([abs(kImag(i-1)), maxJumpLoss * max(kReal(i), eps), eps]);
    relJump = abs(kImag(i) - kImag(i-1)) / scale;
    if relJump > maxJumpRel
        validAttenuation(i) = false;
    end
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

function value = getOption(options, fieldName, defaultValue)
if isfield(options, fieldName)
    value = options.(fieldName);
else
    value = defaultValue;
end
end
