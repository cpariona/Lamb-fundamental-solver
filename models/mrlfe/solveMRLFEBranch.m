function branch = solveMRLFEBranch(name, seedMode, material, geometry, mrlfeParams, options)
% Track one mRLFE fundamental-like branch.
%
% The branch is seeded from either a Rayleigh-Lamb mode or a real-k mRLFE
% reference mode and refined by minimizing sigma_min(M)/sigma_max(M).

frequency = seedMode.frequency;
omega = seedMode.omega;
if isfield(seedMode, 'kReal')
    seedK = seedMode.kReal;
else
    seedK = real(seedMode.k);
end
solveComplexK = isfield(mrlfeParams, 'solveComplexK') && mrlfeParams.solveComplexK;
anchorToSeed = isfield(options, 'mrlfeRealKAnchorToSeed') && options.mrlfeRealKAnchorToSeed;

k = nan(size(frequency));
residual = nan(size(frequency));
score = nan(size(frequency));
seedCp = omega ./ seedK;

for i = 1:numel(frequency)
    if ~isfinite(seedK(i)) || seedK(i) <= 0
        continue;
    end

    if anchorToSeed && ~solveComplexK
        kPred = seedK(i);
    elseif i >= 2 && isfinite(real(k(i-1))) && real(k(i-1)) > 0
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

[validResidual, validReference, validSmooth, validCp, validAttenuation] = ...
    computeBranchValidity(Cp, kReal, kImag, residual, seedCp, seedK, solveComplexK, options);

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
branch.validResidual = validResidual;
branch.validReference = validReference;
branch.validSmooth = validSmooth;
branch.validCp = validCp;
branch.validAttenuation = validAttenuation;
branch.valid = validCp;
if solveComplexK
    branch.note = "mRLFE complex-k prototype seeded from real-k reference when available.";
elseif anchorToSeed
    branch.note = "mRLFE real-k branch anchored to seed reference.";
else
    branch.note = "mRLFE real-k branch seeded from previous frequency continuation.";
end
end

function [validResidual, validReference, validSmooth, validCp, validAttenuation] = computeBranchValidity(Cp, kReal, kImag, residual, seedCp, seedK, solveComplexK, options)
base = isfinite(kReal) & kReal > 0 & isfinite(Cp) & isfinite(residual);

if solveComplexK
    cpResidualTol = getOption(options, 'mrlfeComplexCpResidualTolerance', 1e-4);
    maxRelK = getOption(options, 'mrlfeComplexMaxRelativeKDrift', 0.25);
    maxRelCp = getOption(options, 'mrlfeComplexMaxRelativeCpDrift', 0.30);
else
    cpResidualTol = getOption(options, 'mrlfeResidualTolerance', 1e-4);
    maxRelK = getOption(options, 'mrlfeRealKValidationMaxRelativeKDrift', inf);
    maxRelCp = getOption(options, 'mrlfeRealKValidationMaxRelativeCpDrift', inf);
end

relK = abs(kReal - seedK) ./ max(seedK, eps);
relCp = abs(Cp - seedCp) ./ max(seedCp, eps);
validResidual = base & residual <= cpResidualTol;
validReference = base & relK <= maxRelK & relCp <= maxRelCp;
validSmooth = computeSmoothMask(Cp, base, options);
validCp = validResidual & validReference & validSmooth;

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

function validSmooth = computeSmoothMask(Cp, base, options)
validSmooth = base & isfinite(Cp);
maxJump = getOption(options, 'mrlfeRealKMaxCpJumpRelative', inf);
maxPredictionError = getOption(options, 'mrlfeRealKMaxCpPredictionError', inf);
minPointsForPrediction = getOption(options, 'mrlfeRealKMinPointsForPrediction', 3);

if ~isfinite(maxJump) && ~isfinite(maxPredictionError)
    return;
end

for i = 2:numel(Cp)
    if ~validSmooth(i) || ~validSmooth(i-1)
        continue;
    end
    relJump = abs(Cp(i) - Cp(i-1)) / max(abs(Cp(i-1)), eps);
    if isfinite(maxJump) && relJump > maxJump
        validSmooth(i) = false;
        continue;
    end

    if isfinite(maxPredictionError) && i >= minPointsForPrediction
        previous = find(validSmooth(1:i-1));
        if numel(previous) >= 2
            p1 = previous(end-1);
            p2 = previous(end);
            step = i - p2;
            prevStep = max(p2 - p1, 1);
            cpPred = Cp(p2) + (Cp(p2) - Cp(p1)) * step / prevStep;
            relPred = abs(Cp(i) - cpPred) / max(abs(cpPred), eps);
            if relPred > maxPredictionError
                validSmooth(i) = false;
            end
        end
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
