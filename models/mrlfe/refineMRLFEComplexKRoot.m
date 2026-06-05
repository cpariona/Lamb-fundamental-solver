function [bestK, bestResidual] = refineMRLFEComplexKRoot(kSeed, omega, material, geometry, mrlfeParams, options, physicalReference)
% Refine a complex-k mRLFE root candidate around a predicted seed.
%
% The optimizer minimizes sigma_min(M)/sigma_max(M) over [kr, ki]. When a
% physical real-k reference is supplied, roots far from that reference are
% penalized to reduce branch switching.

if nargin < 7
    physicalReference = struct();
end

if ~isfinite(real(kSeed)) || real(kSeed) <= 0
    bestK = nan;
    bestResidual = inf;
    return;
end

initialImagFraction = getFieldOrDefault(mrlfeParams, 'initialImagKFraction', 1e-5);
minImagAbs = getFieldOrDefault(mrlfeParams, 'minImagKAbsolute', 1e-9);
maxImagFraction = getFieldOrDefault(mrlfeParams, 'maxImagKFraction', 0.50);

kr0 = max(real(kSeed), eps);
if imag(kSeed) > 0
    ki0 = max(imag(kSeed), minImagAbs);
else
    ki0 = max(abs(kr0) * initialImagFraction, minImagAbs);
end

x0 = [log(kr0), log(ki0)];

opts = optimset('Display', 'off', ...
    'MaxIter', getFieldOrDefault(options, 'mrlfeComplexMaxIter', 120), ...
    'MaxFunEvals', getFieldOrDefault(options, 'mrlfeComplexMaxFunEvals', 260), ...
    'TolX', getFieldOrDefault(options, 'mrlfeComplexTolX', 1e-7), ...
    'TolFun', getFieldOrDefault(options, 'mrlfeComplexTolFun', 1e-9));

obj = @(x) complexObjective(x, kSeed, omega, material, geometry, mrlfeParams, options, physicalReference, maxImagFraction);
try
    [xBest, bestResidual] = fminsearch(obj, x0, opts);
    kr = exp(xBest(1));
    ki = exp(xBest(2));
    bestK = kr + 1i * ki;
catch
    bestK = kr0 + 1i * ki0;
    bestResidual = mrlfeResidual(bestK, omega, material, geometry, mrlfeParams);
end
end

function score = complexObjective(x, kSeed, omega, material, geometry, mrlfeParams, options, physicalReference, maxImagFraction)
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

relPred = abs(kr - real(kSeed)) / max(real(kSeed), eps);
relImag = ki / max(kr, eps);
penalty = 1 + getFieldOrDefault(options, 'mrlfeComplexPredictionWeight', 2.0) * relPred;

if isfield(physicalReference, 'k') && isfinite(physicalReference.k) && physicalReference.k > 0
    relRefK = abs(kr - physicalReference.k) / max(physicalReference.k, eps);
    penalty = penalty * (1 + getFieldOrDefault(options, 'mrlfeComplexReferenceWeight', 12.0) * relRefK^2);
    maxRelRefK = getFieldOrDefault(options, 'mrlfeComplexMaxRelativeKDrift', 0.25);
    if relRefK > maxRelRefK
        penalty = penalty * (1 + 1e4 * (relRefK - maxRelRefK)^2);
    end
end

if isfield(physicalReference, 'Cp') && isfinite(physicalReference.Cp) && physicalReference.Cp > 0
    Cp = omega / kr;
    relRefCp = abs(Cp - physicalReference.Cp) / max(physicalReference.Cp, eps);
    penalty = penalty * (1 + getFieldOrDefault(options, 'mrlfeComplexReferenceCpWeight', 8.0) * relRefCp^2);
    maxRelRefCp = getFieldOrDefault(options, 'mrlfeComplexMaxRelativeCpDrift', 0.30);
    if relRefCp > maxRelRefCp
        penalty = penalty * (1 + 1e4 * (relRefCp - maxRelRefCp)^2);
    end
end

if relImag > maxImagFraction
    penalty = penalty * (1 + 100 * (relImag - maxImagFraction)^2);
end

score = r * penalty;
end

function value = getFieldOrDefault(s, name, defaultValue)
if isfield(s, name)
    value = s.(name);
else
    value = defaultValue;
end
end
