function [bestK, bestResidual, bestScore] = refineMRLFEComplexKRoot(kSeed, omega, material, geometry, mrlfeParams, options, physicalReference)
% Refine a complex-k mRLFE root candidate around a predicted seed.
%
% The optimizer minimizes a composite score that balances the singular-value
% residual, real-k continuity, Cp continuity, Im(k) continuity, and a loss
% factor bound. The returned residual is the raw sigma_min/sigma_max value.

if nargin < 7
    physicalReference = struct();
end

if ~isfinite(real(kSeed)) || real(kSeed) <= 0
    bestK = nan;
    bestResidual = inf;
    bestScore = inf;
    return;
end

initialImagFraction = getFieldOrDefault(mrlfeParams, 'initialImagKFraction', 1e-5);
minImagAbs = getFieldOrDefault(mrlfeParams, 'minImagKAbsolute', 1e-12);
maxImagFraction = getFieldOrDefault(options, 'mrlfeComplexMaxLossFactor', ...
    getFieldOrDefault(mrlfeParams, 'maxImagKFraction', 1e-2));

kr0 = max(real(kSeed), eps);
if imag(kSeed) > 0
    kiSeed = max(imag(kSeed), minImagAbs);
else
    kiSeed = max(abs(kr0) * initialImagFraction, minImagAbs);
end

kiGuesses = uniquePositive([kiSeed, minImagAbs, kr0 * initialImagFraction, kr0 * 1e-8, kr0 * 1e-6]);
krGuesses = uniquePositive([kr0, real(kSeed), getFieldOrDefault(physicalReference, 'k', kr0)]);

opts = optimset('Display', 'off', ...
    'MaxIter', getFieldOrDefault(options, 'mrlfeComplexMaxIter', 120), ...
    'MaxFunEvals', getFieldOrDefault(options, 'mrlfeComplexMaxFunEvals', 260), ...
    'TolX', getFieldOrDefault(options, 'mrlfeComplexTolX', 1e-7), ...
    'TolFun', getFieldOrDefault(options, 'mrlfeComplexTolFun', 1e-9));

bestK = nan;
bestResidual = inf;
bestScore = inf;

for a = 1:numel(krGuesses)
    for b = 1:numel(kiGuesses)
        x0 = [log(max(krGuesses(a), eps)), log(max(kiGuesses(b), minImagAbs))];
        obj = @(x) complexObjective(x, kSeed, omega, material, geometry, mrlfeParams, options, physicalReference, maxImagFraction);
        try
            [xCandidate, scoreCandidate] = fminsearch(obj, x0, opts);
            kr = exp(xCandidate(1));
            ki = exp(xCandidate(2));
            kCandidate = kr + 1i * ki;
            residualCandidate = mrlfeResidual(kCandidate, omega, material, geometry, mrlfeParams);
            if isfinite(scoreCandidate) && scoreCandidate < bestScore
                bestK = kCandidate;
                bestResidual = residualCandidate;
                bestScore = scoreCandidate;
            end
        catch
        end
    end
end

if isnan(real(bestK))
    bestK = kr0 + 1i * kiSeed;
    bestResidual = mrlfeResidual(bestK, omega, material, geometry, mrlfeParams);
    bestScore = bestResidual;
end
end

function score = complexObjective(x, kSeed, omega, material, geometry, mrlfeParams, options, physicalReference, maxLossFactor)
kr = exp(x(1));
ki = exp(x(2));
if ~isfinite(kr) || ~isfinite(ki) || kr <= 0 || ki < 0
    score = inf;
    return;
end

k = kr + 1i * ki;
r = mrlfeResidual(k, omega, material, geometry, mrlfeParams);
if ~isfinite(r)
    score = inf;
    return;
end

residualScale = getFieldOrDefault(options, 'mrlfeComplexResidualScale', 1e-8);
score = getFieldOrDefault(options, 'mrlfeComplexResidualWeight', 1.0) * log1p(r / max(residualScale, eps));

relPred = abs(kr - real(kSeed)) / max(real(kSeed), eps);
score = score + getFieldOrDefault(options, 'mrlfeComplexPredictionWeight', 2.0) * relPred^2;

if isfield(physicalReference, 'k') && isfinite(physicalReference.k) && physicalReference.k > 0
    relRefK = abs(kr - physicalReference.k) / max(physicalReference.k, eps);
    score = score + getFieldOrDefault(options, 'mrlfeComplexReferenceWeight', 12.0) * relRefK^2;
    maxRelRefK = getFieldOrDefault(options, 'mrlfeComplexMaxRelativeKDrift', 0.25);
    if relRefK > maxRelRefK
        score = score + 1e4 * (relRefK - maxRelRefK)^2;
    end
end

if isfield(physicalReference, 'Cp') && isfinite(physicalReference.Cp) && physicalReference.Cp > 0
    Cp = omega / kr;
    relRefCp = abs(Cp - physicalReference.Cp) / max(physicalReference.Cp, eps);
    score = score + getFieldOrDefault(options, 'mrlfeComplexReferenceCpWeight', 8.0) * relRefCp^2;
    maxRelRefCp = getFieldOrDefault(options, 'mrlfeComplexMaxRelativeCpDrift', 0.30);
    if relRefCp > maxRelRefCp
        score = score + 1e4 * (relRefCp - maxRelRefCp)^2;
    end
end

if isfield(physicalReference, 'kImagPred') && isfinite(physicalReference.kImagPred)
    kiPred = max(physicalReference.kImagPred, 0);
    kiScale = max([abs(kiPred), getFieldOrDefault(options, 'mrlfeComplexImagScaleFraction', 1e-7) * kr, eps]);
    relImagJump = abs(ki - kiPred) / kiScale;
    score = score + getFieldOrDefault(options, 'mrlfeComplexImagContinuityWeight', 4.0) * relImagJump^2;
end

lossFactor = ki / max(kr, eps);
if lossFactor > maxLossFactor
    excess = (lossFactor - maxLossFactor) / max(maxLossFactor, eps);
    score = score + getFieldOrDefault(options, 'mrlfeComplexLossPenaltyWeight', 100.0) * excess^2;
end
end

function values = uniquePositive(values)
values = values(isfinite(values) & values > 0);
if isempty(values)
    values = eps;
else
    values = unique(values, 'stable');
end
end

function value = getFieldOrDefault(s, name, defaultValue)
if isfield(s, name)
    value = s.(name);
else
    value = defaultValue;
end
end
