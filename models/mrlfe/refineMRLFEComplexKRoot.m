function [bestK, bestResidual] = refineMRLFEComplexKRoot(kSeed, omega, material, geometry, mrlfeParams, options)
% Refine a complex-k mRLFE root candidate around a predicted real-k seed.
%
% This prototype minimizes sigma_min(M)/sigma_max(M) over [kr, ki] using
% fminsearch. It is intended as a first continuation step toward the full
% viscoelastic mRLFE solver.

if ~isfinite(kSeed) || kSeed <= 0
    bestK = nan;
    bestResidual = inf;
    return;
end

initialImagFraction = getFieldOrDefault(mrlfeParams, 'initialImagKFraction', 1e-5);
minImagAbs = getFieldOrDefault(mrlfeParams, 'minImagKAbsolute', 1e-9);
maxImagFraction = getFieldOrDefault(mrlfeParams, 'maxImagKFraction', 0.50);

kr0 = max(real(kSeed), eps);
ki0 = max(abs(kr0) * initialImagFraction, minImagAbs);

x0 = [log(kr0), log(ki0)];

opts = optimset('Display', 'off', ...
    'MaxIter', getFieldOrDefault(options, 'mrlfeComplexMaxIter', 120), ...
    'MaxFunEvals', getFieldOrDefault(options, 'mrlfeComplexMaxFunEvals', 260), ...
    'TolX', getFieldOrDefault(options, 'mrlfeComplexTolX', 1e-7), ...
    'TolFun', getFieldOrDefault(options, 'mrlfeComplexTolFun', 1e-9));

obj = @(x) complexObjective(x, kSeed, omega, material, geometry, mrlfeParams, maxImagFraction);
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

function score = complexObjective(x, kSeed, omega, material, geometry, mrlfeParams, maxImagFraction)
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

relReal = abs(kr - real(kSeed)) / max(real(kSeed), eps);
relImag = ki / max(kr, eps);
penalty = 1 + 0.50 * relReal;

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
