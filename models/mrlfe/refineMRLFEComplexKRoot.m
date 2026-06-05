function [bestK, bestResidual, bestScore] = refineMRLFEComplexKRoot(kSeed, omega, material, geometry, mrlfeParams, options, physicalReference)
% Refine a complex-k mRLFE candidate around a predicted seed.
%
% This fast prototype uses a single local fminsearch pass on the normalized
% singular-value residual with light penalties that keep kReal close to the
% real-k reference. Spatial attenuation Im(k) is still experimental and is
% validated separately downstream.

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
maxLossFactor = getFieldOrDefault(options, 'mrlfeComplexMaxLossFactor', 1e-2);

kr0 = max(real(kSeed), eps);
if imag(kSeed) > 0
    ki0 = max(imag(kSeed), minImagAbs);
else
    ki0 = max(abs(kr0) * initialImagFraction, minImagAbs);
end

x0 = [log(kr0), log(ki0)];
opts = optimset('Display', 'off', ...
    'MaxIter', getFieldOrDefault(options, 'mrlfeComplexMaxIter', 60), ...
    'MaxFunEvals', getFieldOrDefault(options, 'mrlfeComplexMaxFunEvals', 120), ...
    'TolX', getFieldOrDefault(options, 'mrlfeComplexTolX', 1e-7), ...
    'TolFun', getFieldOrDefault(options, 'mrlfeComplexTolFun', 1e-9));

obj = @(x) fastComplexObjective(x, kSeed, omega, material, geometry, mrlfeParams, options, physicalReference, maxLossFactor);
try
    [xBest, bestScore] = fminsearch(obj, x0, opts);
    kr = exp(xBest(1));
    ki = exp(xBest(2));
    bestK = kr + 1i * ki;
    bestResidual = mrlfeResidual(bestK, omega, material, geometry, mrlfeParams);
catch
    bestK = kr0 + 1i * ki0;
    bestResidual = mrlfeResidual(bestK, omega, material, geometry, mrlfeParams);
    bestScore = bestResidual;
end
end

function score = fastComplexObjective(x, kSeed, omega, material, geometry, mrlfeParams, options, physicalReference, maxLossFactor)
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

score = r;

% Keep kReal close to the continuation prediction.
relPred = abs(kr - real(kSeed)) / max(real(kSeed), eps);
score = score * (1 + getFieldOrDefault(options, 'mrlfeComplexPredictionWeight', 2.0) * relPred);

% Keep kReal and Cp close to the real-k mRLFE reference when available.
if isfield(physicalReference, 'k') && isfinite(physicalReference.k) && physicalReference.k > 0
    relRefK = abs(kr - physicalReference.k) / max(physicalReference.k, eps);
    score = score * (1 + getFieldOrDefault(options, 'mrlfeComplexReferenceWeight', 12.0) * relRefK^2);
end

if isfield(physicalReference, 'Cp') && isfinite(physicalReference.Cp) && physicalReference.Cp > 0
    Cp = omega / kr;
    relRefCp = abs(Cp - physicalReference.Cp) / max(physicalReference.Cp, eps);
    score = score * (1 + getFieldOrDefault(options, 'mrlfeComplexReferenceCpWeight', 8.0) * relRefCp^2);
end

% Do not let the local optimizer wander into extremely lossy roots.
lossFactor = ki / max(kr, eps);
if lossFactor > maxLossFactor
    score = score * (1 + 1e4 * (lossFactor - maxLossFactor)^2);
end
end

function value = getFieldOrDefault(s, name, defaultValue)
if isfield(s, name)
    value = s.(name);
else
    value = defaultValue;
end
end
