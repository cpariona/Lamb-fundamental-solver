function result = solveAcoustoelasticComplexCDispersion(params, options, seedResult)
%SOLVEACOUSTOELASTICCOMPLEXCDISPERSION Complex-C continuation solver.
%
% This solver is a parallel strategy to the real-Cp sigma_min trackers. It
% follows a complex phase velocity c = cr + i*ci by minimizing abs(det(M)) in
% the complex plane using fminsearch. It is intended for diagnostics and for
% cases where real-Cp minimum tracking switches between competing valleys.
%
% Required params fields:
%   alpha, beta, gamma, thickness, rho, rhoF, fluidBulkModulus, frequency
%
% Optional input:
%   seedResult : output from solveAcoustoelasticDispersion. If given,
%                its real Cp values are used as initial seeds.

if nargin < 2 || isempty(options)
    options = defaultAcoustoelasticIOPHGOOptions();
end
if nargin < 3
    seedResult = [];
end

validateDirectParams(params);

f = params.frequency(:);
n = numel(f);
cComplex = nan(n, 1) + 1i*nan(n, 1);
objective = nan(n, 1);
absDet = nan(n, 1);
sigmaMin = nan(n, 1);
exitFlag = nan(n, 1);
valid = false(n, 1);

cShear = sqrt(params.alpha / params.rho);
dimensionlessFrequency = f .* params.thickness ./ cShear;
solveMask = dimensionlessFrequency >= options.minDimensionlessFrequency;
trackOrder = getTrackingOrder(n, solveMask, options);

seedCp = makeInitialSeeds(params, options, seedResult);
previousC = nan + 1i*nan;
previousPreviousC = nan + 1i*nan;

for jj = 1:numel(trackOrder)
    i = trackOrder(jj);
    c0 = getComplexSeed(i, seedCp, previousC, previousPreviousC, options);

    [cComplex(i), objective(i), absDet(i), sigmaMin(i), exitFlag(i)] = solveOneComplexRoot(params, options, f(i), c0);

    if isfinite(real(cComplex(i))) && isfinite(imag(cComplex(i)))
        previousPreviousC = previousC;
        previousC = cComplex(i);
        valid(i) = true;
    end
end

result = struct();
result.frequency = f;
result.dimensionlessFrequency = dimensionlessFrequency;
result.CpComplex = cComplex;
result.CpReal = real(cComplex);
result.CpImag = imag(cComplex);
result.objective = objective;
result.absDet = absDet;
result.sigmaMin = sigmaMin;
result.exitFlag = exitFlag;
result.valid = valid;
result.validCp = valid & isfinite(real(cComplex));
result.params = params;
result.options = options;
result.seedCp = seedCp;
result.trackingOrder = trackOrder;
result.diagnostics = summarizeComplexResult(result);
end

function [cBest, objBest, absDetBest, sigmaMinBest, exitFlag] = solveOneComplexRoot(params, options, f, c0)
scale = max(abs(real(c0)), options.complexCMinScale);
x0 = [real(c0), imag(c0)] ./ scale;

obj = @(x) complexDetObjectiveScaled(x, scale, params, options, f);
optimOptions = optimset('Display', char(options.complexCDisplay), ...
    'MaxIter', options.complexCMaxIter, ...
    'MaxFunEvals', options.complexCMaxFunEvals, ...
    'TolX', options.complexCTolX, ...
    'TolFun', options.complexCTolFun);

try
    [xBest, objBest, exitFlag] = fminsearch(obj, x0, optimOptions);
catch
    cBest = nan + 1i*nan;
    objBest = inf;
    absDetBest = inf;
    sigmaMinBest = inf;
    exitFlag = -1;
    return;
end

cBest = scale .* (xBest(1) + 1i*xBest(2));
[~, details] = objectiveAcoustoelasticComplexDeterminant(params.alpha, params.beta, params.gamma, ...
    params.thickness, params.rho, params.rhoF, params.fluidBulkModulus, f, cBest, options);
absDetBest = details.absDet;
sigmaMinBest = details.sigmaMin;
end

function value = complexDetObjectiveScaled(x, scale, params, options, f)
c = scale .* (x(1) + 1i*x(2));
if real(c) <= 0
    value = inf;
    return;
end

imagLimit = options.complexCImagLimitRatio * max(real(c), eps);
if abs(imag(c)) > imagLimit
    value = inf;
    return;
end

[value, ~] = objectiveAcoustoelasticComplexDeterminant(params.alpha, params.beta, params.gamma, ...
    params.thickness, params.rho, params.rhoF, params.fluidBulkModulus, f, c, options);

if ~isfinite(value)
    value = inf;
end
end

function seedCp = makeInitialSeeds(params, options, seedResult)
if ~isempty(seedResult) && isfield(seedResult, 'Cp')
    seedCp = seedResult.Cp(:);
elseif ~isempty(seedResult) && isfield(seedResult, 'CpReal')
    seedCp = seedResult.CpReal(:);
else
    seedCp = nan(numel(params.frequency), 1);
    shearSpeed = sqrt(params.alpha / params.rho);
    switch string(options.branch)
        case "A0"
            seedCp(:) = 0.65 * shearSpeed;
        case "A0High"
            seedCp(:) = options.A0HighTarget * shearSpeed;
        case "S0"
            seedCp(:) = sqrt((2*params.beta + 2*params.gamma) / params.rho);
        otherwise
            seedCp(:) = shearSpeed;
    end
end
end

function c0 = getComplexSeed(i, seedCp, previousC, previousPreviousC, options)
if isfinite(real(previousC))
    if isfinite(real(previousPreviousC))
        c0 = previousC + (previousC - previousPreviousC);
    else
        c0 = previousC;
    end
else
    c0 = seedCp(i);
end

if ~isfinite(real(c0)) || real(c0) <= 0
    c0 = max(seedCp(i), options.complexCMinScale);
end

if ~isfinite(imag(c0)) || imag(c0) == 0
    c0 = real(c0) .* (1 + 1i*options.complexCInitialImagRatio);
end
end

function trackOrder = getTrackingOrder(n, solveMask, options)
validIdx = find(solveMask(:));
switch string(options.trackingDirection)
    case "forward"
        trackOrder = validIdx(:).';
    case "backward"
        trackOrder = flipud(validIdx(:)).';
    otherwise
        error('Unknown trackingDirection: %s. Use "forward" or "backward".', string(options.trackingDirection));
end
end

function validateDirectParams(params)
requiredFields = {'alpha', 'beta', 'gamma', 'thickness', 'rho', 'rhoF', 'fluidBulkModulus', 'frequency'};
for i = 1:numel(requiredFields)
    if ~isfield(params, requiredFields{i})
        error('Missing required Acoustoelastic IOP/HGO parameter: %s', requiredFields{i});
    end
end
end

function diagnostics = summarizeComplexResult(result)
valid = result.validCp & isfinite(result.CpReal);
diagnostics = struct();
diagnostics.validCpPoints = nnz(valid);
diagnostics.totalPoints = numel(result.CpReal);
diagnostics.trackingDirection = string(result.options.trackingDirection);
diagnostics.complexCMethod = "complexDetContinuation";
if any(valid)
    diagnostics.minCpReal = min(result.CpReal(valid));
    diagnostics.maxCpReal = max(result.CpReal(valid));
    diagnostics.minAbsDet = min(result.absDet(valid));
    diagnostics.medianAbsImagOverReal = median(abs(result.CpImag(valid))./max(abs(result.CpReal(valid)), eps), 'omitnan');
else
    diagnostics.minCpReal = nan;
    diagnostics.maxCpReal = nan;
    diagnostics.minAbsDet = nan;
    diagnostics.medianAbsImagOverReal = nan;
end
end
