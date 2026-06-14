function result = solveAcoustoelasticDispersion(params, options)
%SOLVEACOUSTOELASTICDISPERSION Solve direct alpha-beta-gamma dispersion.
%
% Required params fields:
%   alpha, beta, gamma : acoustoelastic stiffness parameters [Pa]
%   thickness          : plate/cornea thickness [m]
%   rho                : solid density [kg/m^3]
%   rhoF               : fluid density [kg/m^3]
%   fluidBulkModulus   : fluid bulk modulus [Pa]
%   frequency          : frequency vector [Hz]
%
% Optional params field:
%   cGrid              : custom Cp grid [m/s]

if nargin < 2 || isempty(options)
    options = defaultLi2024AcoustoelasticOptions();
end

validateDirectParams(params);

f = params.frequency(:);
n = numel(f);
cp = nan(n, 1);
objective = nan(n, 1);
sigmaMin = nan(n, 1);
modalMAC = nan(n, 1);
valid = false(n, 1);
s1 = nan(n, 1) + 1i*nan(n, 1);
s2 = nan(n, 1) + 1i*nan(n, 1);
xi = nan(n, 1) + 1i*nan(n, 1);

[cGrid, gridInfo] = makeCpGrid(params, options);
cShear = sqrt(params.alpha / params.rho);
dimensionlessFrequency = f .* params.thickness ./ cShear;
solveMask = dimensionlessFrequency >= options.minDimensionlessFrequency;

trackOrder = getTrackingOrder(n, solveMask, options);
previousCp = nan;
previousPreviousCp = nan;
previousModeVector = [];

for jj = 1:numel(trackOrder)
    i = trackOrder(jj);

    [cp(i), objective(i), sigmaMin(i), details] = solveOneFrequency(params, options, f(i), cGrid, previousCp, previousPreviousCp, previousModeVector);
    if isfinite(cp(i))
        if isfinite(previousCp) && isfinite(options.maxRelativeCpJump)
            relJump = abs(cp(i) - previousCp) / max(abs(previousCp), eps);
            if relJump > options.maxRelativeCpJump
                break;
            end
        end
        if ~isempty(previousModeVector) && isfield(details, 'singularVectorRight')
            modalMAC(i) = computeMAC(details.singularVectorRight, previousModeVector);
        end
        previousPreviousCp = previousCp;
        previousCp = cp(i);
        if isfield(details, 'singularVectorRight')
            previousModeVector = details.singularVectorRight;
        end
        valid(i) = objective(i) <= options.maxObjectiveForValid;
        s1(i) = details.aux.s1;
        s2(i) = details.aux.s2;
        xi(i) = details.aux.xi;
    end
end

result = struct();
result.frequency = f;
result.dimensionlessFrequency = dimensionlessFrequency;
result.trackingOrder = trackOrder;
result.omega = 2*pi*f;
result.Cp = cp;
result.k = 2*pi*f ./ cp;
result.kThickness = result.k .* params.thickness;
result.objective = objective;
result.sigmaMin = sigmaMin;
result.modalMAC = modalMAC;
result.valid = valid & isfinite(cp);
result.validCp = result.valid;
result.skippedLowDimensionlessFrequency = ~solveMask;
result.s1 = s1;
result.s2 = s2;
result.xi = xi;
result.params = params;
result.options = options;
result.gridInfo = gridInfo;
result.diagnostics = summarizeResult(result);
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

function [bestCp, bestObj, bestSigmaMin, bestDetails] = solveOneFrequency(params, options, f, cGrid, previousCp, previousPreviousCp, previousModeVector)
method = string(options.trackingMethod);
if isfinite(previousCp) && method == "localContinuation"
    [bestCp, bestObj, bestSigmaMin, bestDetails, ok] = solveOneFrequencyLocal(params, options, f, cGrid, previousCp);
    if ok
        return;
    end
    if string(options.localContinuationFallback) ~= "globalScan"
        [bestCp, bestObj, bestSigmaMin, bestDetails] = emptySolution();
        return;
    end
end

[bestCp, bestObj, bestSigmaMin, bestDetails] = solveOneFrequencyGlobal(params, options, f, cGrid, previousCp, previousPreviousCp, previousModeVector);
end

function [bestCp, bestObj, bestSigmaMin, bestDetails, ok] = solveOneFrequencyLocal(params, options, f, cGrid, previousCp)
localHalfWidth = max(options.localContinuationWindow * abs(previousCp), options.localContinuationMinWidth);
[cLower, cUpper] = getLocalContinuationBounds(params, options, cGrid, previousCp, localHalfWidth);

ok = false;
[bestCp, bestObj, bestSigmaMin, bestDetails] = emptySolution();
if ~(isfinite(cLower) && isfinite(cUpper) && cUpper > cLower)
    return;
end

localObj = @(cc)objective_Li2024_Acoustoelastic(params.alpha, params.beta, params.gamma, ...
    params.thickness, params.rho, params.rhoF, params.fluidBulkModulus, f, cc, options);

try
    [candidateCp, candidateObj] = fminbnd(localObj, cLower, cUpper);
catch
    return;
end

if ~isfinite(candidateCp) || ~isfinite(candidateObj)
    return;
end

[~, candidateDetails] = objective_Li2024_Acoustoelastic(params.alpha, params.beta, params.gamma, ...
    params.thickness, params.rho, params.rhoF, params.fluidBulkModulus, f, candidateCp, options);

bestCp = candidateCp;
bestObj = candidateObj;
bestSigmaMin = candidateDetails.sigmaMin;
bestDetails = candidateDetails;
ok = true;
end

function [cLower, cUpper] = getLocalContinuationBounds(params, options, cGrid, previousCp, localHalfWidth)
cLower = max(min(cGrid), previousCp - localHalfWidth);
cUpper = min(max(cGrid), previousCp + localHalfWidth);

if isfield(options, 'branchSelectionMode') && string(options.branchSelectionMode) == "band"
    shearSpeed = sqrt(params.alpha / params.rho);
    band = getBranchBand(options);
    if ~isempty(band)
        cLower = max(cLower, band(1) * shearSpeed);
        cUpper = min(cUpper, band(2) * shearSpeed);
    end
end
end

function [bestCp, bestObj, bestSigmaMin, bestDetails] = solveOneFrequencyGlobal(params, options, f, cGrid, previousCp, previousPreviousCp, previousModeVector)
objVals = nan(size(cGrid));
for j = 1:numel(cGrid)
    objVals(j) = objective_Li2024_Acoustoelastic(params.alpha, params.beta, params.gamma, ...
        params.thickness, params.rho, params.rhoF, params.fluidBulkModulus, f, cGrid(j), options);
end

candidateIdx = findLocalMinimaIndices(objVals);
if isempty(candidateIdx)
    [~, idx] = min(objVals);
    candidateIdx = idx;
end

candidateIdx = filterCandidatesByBranchBand(candidateIdx, cGrid, params, options);
method = string(options.trackingMethod);

if isfinite(previousCp) && (method == "predictiveContinuation" || method == "singularVectorTracking")
    candidateIdx = filterCandidatesByPrediction(candidateIdx, cGrid, previousCp, previousPreviousCp, options);
else
    candidateIdx = filterCandidatesByContinuity(candidateIdx, cGrid, previousCp, options);
end

[~, order] = sort(objVals(candidateIdx), 'ascend');
candidateIdx = candidateIdx(order);
candidateIdx = candidateIdx(1:min(numel(candidateIdx), options.maxLocalCandidates));

candidateCp = cGrid(candidateIdx);
candidateObj = objVals(candidateIdx);

if options.refineLocalMinima
    [candidateCp, candidateObj] = refineCandidates(candidateIdx, candidateCp, candidateObj, cGrid, params, options, f);
end

candidateDetails = evaluateCandidateDetails(candidateCp, params, options, f);

if isfinite(previousCp)
    switch method
        case "predictiveContinuation"
            scores = predictiveScores(candidateCp(:), candidateObj(:), previousCp, previousPreviousCp, options);
        case "singularVectorTracking"
            scores = singularVectorScores(candidateCp(:), candidateObj(:), candidateDetails, previousCp, previousPreviousCp, previousModeVector, options);
        otherwise
            scores = candidateObj(:) + options.previousCpWeight * abs(log(candidateCp(:) ./ previousCp));
    end
else
    scores = firstPointScores(candidateCp(:), candidateObj(:), params, options);
end

[~, bestLocal] = min(scores);
bestCp = candidateCp(bestLocal);
bestObj = candidateObj(bestLocal);
bestDetails = candidateDetails{bestLocal};
bestSigmaMin = bestDetails.sigmaMin;
end

function [candidateCp, candidateObj] = refineCandidates(candidateIdx, candidateCp, candidateObj, cGrid, params, options, f)
for j = 1:numel(candidateIdx)
    idx = candidateIdx(j);
    leftIdx = max(1, idx - options.refineHalfWindowPoints);
    rightIdx = min(numel(cGrid), idx + options.refineHalfWindowPoints);
    cLeft = cGrid(leftIdx);
    cRight = cGrid(rightIdx);
    if cRight > cLeft
        localObj = @(cc)objective_Li2024_Acoustoelastic(params.alpha, params.beta, params.gamma, ...
            params.thickness, params.rho, params.rhoF, params.fluidBulkModulus, f, cc, options);
        [candidateCp(j), candidateObj(j)] = fminbnd(localObj, cLeft, cRight);
    end
end
end

function candidateDetails = evaluateCandidateDetails(candidateCp, params, options, f)
candidateDetails = cell(numel(candidateCp), 1);
for j = 1:numel(candidateCp)
    [~, details] = objective_Li2024_Acoustoelastic(params.alpha, params.beta, params.gamma, ...
        params.thickness, params.rho, params.rhoF, params.fluidBulkModulus, f, candidateCp(j), options);
    candidateDetails{j} = details;
end
end

function scores = predictiveScores(candidateCp, candidateObj, previousCp, previousPreviousCp, options)
predictedCp = predictCp(previousCp, previousPreviousCp);
scale = max(abs(previousCp), eps);
predictionPenalty = abs(candidateCp - predictedCp) ./ scale;

if isfinite(previousPreviousCp)
    curvaturePenalty = abs(candidateCp - 2*previousCp + previousPreviousCp) ./ scale;
else
    curvaturePenalty = zeros(size(candidateCp));
end

scores = candidateObj + ...
    options.predictionWeight .* predictionPenalty + ...
    options.curvatureWeight .* curvaturePenalty;
end

function scores = singularVectorScores(candidateCp, candidateObj, candidateDetails, previousCp, previousPreviousCp, previousModeVector, options)
scores = predictiveScores(candidateCp, candidateObj, previousCp, previousPreviousCp, options);
if isempty(previousModeVector)
    return;
end

macValues = nan(numel(candidateCp), 1);
for j = 1:numel(candidateCp)
    if isfield(candidateDetails{j}, 'singularVectorRight')
        macValues(j) = computeMAC(candidateDetails{j}.singularVectorRight, previousModeVector);
    end
end

macPenalty = 1 - macValues;
macPenalty(~isfinite(macPenalty)) = 1;
scores = scores + options.macWeight .* macPenalty;

if options.minAcceptableMAC > 0
    reject = macValues < options.minAcceptableMAC;
    if any(~reject)
        scores(reject) = inf;
    end
end
end

function value = computeMAC(v1, v2)
if isempty(v1) || isempty(v2) || numel(v1) ~= numel(v2)
    value = nan;
    return;
end
num = abs(v1(:)' * v2(:)).^2;
den = (v1(:)' * v1(:)) * (v2(:)' * v2(:));
if den == 0 || ~isfinite(den)
    value = nan;
else
    value = real(num ./ den);
end
end

function predictedCp = predictCp(previousCp, previousPreviousCp)
if isfinite(previousPreviousCp)
    predictedCp = previousCp + (previousCp - previousPreviousCp);
else
    predictedCp = previousCp;
end
predictedCp = max(predictedCp, eps);
end

function candidateIdx = filterCandidatesByPrediction(candidateIdx, cGrid, previousCp, previousPreviousCp, options)
predictedCp = predictCp(previousCp, previousPreviousCp);
halfWidth = max(options.predictiveWindow * abs(predictedCp), options.predictiveMinWidth);
absDistance = abs(cGrid(candidateIdx) - predictedCp);
mask = absDistance <= halfWidth;

if any(mask)
    candidateIdx = candidateIdx(mask);
elseif options.allowPredictiveFallbackNearest
    [~, nearestIdx] = min(absDistance);
    candidateIdx = candidateIdx(nearestIdx);
end
end

function candidateIdx = filterCandidatesByBranchBand(candidateIdx, cGrid, params, options)
if ~isfield(options, 'branchSelectionMode') || string(options.branchSelectionMode) ~= "band"
    return;
end

shearSpeed = sqrt(params.alpha / params.rho);
yCandidates = cGrid(candidateIdx) ./ shearSpeed;
band = getBranchBand(options);
if isempty(band)
    return;
end

mask = yCandidates >= band(1) & yCandidates <= band(2);
if any(mask)
    candidateIdx = candidateIdx(mask);
end
end

function band = getBranchBand(options)
switch string(options.branch)
    case "A0"
        band = options.A0Band;
    case "A0High"
        band = options.A0HighBand;
    case "S0"
        band = options.S0Band;
    otherwise
        band = [];
end
end

function candidateIdx = filterCandidatesByContinuity(candidateIdx, cGrid, previousCp, options)
if ~isfield(options, 'useBranchContinuityWindow') || ~options.useBranchContinuityWindow
    return;
end
if ~isfinite(previousCp)
    return;
end

window = getContinuityWindow(options);
if ~isfinite(window) || window <= 0
    return;
end

relDistance = abs(cGrid(candidateIdx) - previousCp) ./ max(abs(previousCp), eps);
nearMask = relDistance <= window;
if any(nearMask)
    candidateIdx = candidateIdx(nearMask);
else
    [~, nearestIdx] = min(relDistance);
    candidateIdx = candidateIdx(nearestIdx);
end
end

function window = getContinuityWindow(options)
switch string(options.branch)
    case "A0"
        window = options.A0ContinuityWindow;
    case "A0High"
        window = options.A0HighContinuityWindow;
    case "S0"
        window = options.S0ContinuityWindow;
    otherwise
        window = inf;
end
end

function scores = firstPointScores(candidateCp, candidateObj, params, options)
preference = resolveStartPreference(options);

switch preference
    case "lowCp"
        cpScale = max(candidateCp) - min(candidateCp);
        if cpScale <= 0, cpScale = max(abs(candidateCp)); end
        scores = candidateObj + options.firstPointPreferenceWeight * ((candidateCp - min(candidateCp)) ./ max(cpScale, eps));
    case "A0HighTarget"
        shearSpeed = sqrt(params.alpha / params.rho);
        target = options.A0HighTarget * shearSpeed;
        scores = candidateObj + options.firstPointPreferenceWeight * abs(log(candidateCp ./ target));
    case "tensileTarget"
        target = sqrt((2*params.beta + 2*params.gamma) / params.rho);
        scores = candidateObj + options.firstPointPreferenceWeight * abs(log(candidateCp ./ target));
    case "shearTarget"
        target = sqrt(params.alpha / params.rho);
        scores = candidateObj + options.firstPointPreferenceWeight * abs(log(candidateCp ./ target));
    case "bestObjective"
        scores = candidateObj;
    otherwise
        target = getInitialBranchTarget(params, options);
        scores = candidateObj + options.firstPointPreferenceWeight * abs(log(candidateCp ./ target));
end
end

function preference = resolveStartPreference(options)
preference = string(options.branchStartPreference);
if preference ~= "auto"
    return;
end
switch string(options.branch)
    case "A0"
        preference = "lowCp";
    case "A0High"
        preference = "A0HighTarget";
    case "S0"
        preference = "tensileTarget";
    otherwise
        preference = "bestObjective";
end
end

function idx = findLocalMinimaIndices(y)
finiteMask = isfinite(y);
idx = [];
for i = 2:numel(y)-1
    if finiteMask(i) && finiteMask(i-1) && finiteMask(i+1) && y(i) <= y(i-1) && y(i) <= y(i+1)
        idx(end+1) = i; %#ok<AGROW>
    end
end
end

function [cGrid, gridInfo] = makeCpGrid(params, options)
if isfield(params, 'cGrid') && ~isempty(params.cGrid)
    cGrid = params.cGrid(:);
    gridInfo = struct('source', "params.cGrid", 'cMin', min(cGrid), 'cMax', max(cGrid));
    return;
end

if isfield(options, 'usePhysicalCpWindow') && options.usePhysicalCpWindow
    [cMin, cMax, source] = getPhysicalCpWindow(params, options);
else
    cMin = options.cMin;
    if isempty(options.cMax)
        shearSpeed = sqrt(params.alpha / params.rho);
        tensileSpeed = sqrt((2*params.beta + 2*params.gamma) / params.rho);
        cMax = 1.35 * max([shearSpeed, tensileSpeed, cMin]);
    else
        cMax = options.cMax;
    end
    source = "manual/global";
end

if cMax <= cMin
    error('Invalid Cp scan range: cMax must be greater than cMin.');
end

cGrid = linspace(cMin, cMax, options.numCpScanPoints).';
gridInfo = struct('source', source, 'cMin', cMin, 'cMax', cMax);
end

function [cMin, cMax, source] = getPhysicalCpWindow(params, options)
branch = string(options.branch);
shearSpeed = sqrt(params.alpha / params.rho);
tensileSpeed = sqrt((2*params.beta + 2*params.gamma) / params.rho);

switch branch
    case "A0"
        scale = options.A0CpWindowScale;
        ref = shearSpeed;
        source = "A0 sqrt(alpha/rho) window";
    case "A0High"
        scale = options.A0HighCpWindowScale;
        ref = shearSpeed;
        source = "A0High sqrt(alpha/rho) window";
    case "S0"
        scale = options.S0CpWindowScale;
        ref = tensileSpeed;
        source = "S0 sqrt((2beta+2gamma)/rho) window";
    otherwise
        scale = [0.03, 1.35];
        ref = max(shearSpeed, tensileSpeed);
        source = "fallback physical window";
end

cMin = max(options.cMin, scale(1) * ref);
cMaxPhysical = scale(2) * ref;
if isempty(options.cMax)
    cMax = cMaxPhysical;
else
    cMax = min(options.cMax, cMaxPhysical);
end
end

function target = getInitialBranchTarget(params, options)
branch = string(options.branch);
shearSpeed = sqrt(params.alpha / params.rho);
tensileSpeed = sqrt((2*params.beta + 2*params.gamma) / params.rho);

switch branch
    case "A0"
        target = 0.9 * shearSpeed;
    case "A0High"
        target = options.A0HighTarget * shearSpeed;
    case "S0"
        target = tensileSpeed;
    otherwise
        target = shearSpeed;
end
end

function validateDirectParams(params)
requiredFields = {'alpha', 'beta', 'gamma', 'thickness', 'rho', 'rhoF', 'fluidBulkModulus', 'frequency'};
for i = 1:numel(requiredFields)
    if ~isfield(params, requiredFields{i})
        error('Missing required Li2024 parameter: %s', requiredFields{i});
    end
end
end

function [bestCp, bestObj, bestSigmaMin, bestDetails] = emptySolution()
bestCp = nan;
bestObj = nan;
bestSigmaMin = nan;
bestDetails = struct('aux', struct('s1', nan, 's2', nan, 'xi', nan), ...
    'sigmaMin', nan, 'singularVectorRight', []);
end

function diagnostics = summarizeResult(result)
valid = result.validCp & isfinite(result.Cp);
diagnostics = struct();
diagnostics.validCpPoints = nnz(valid);
diagnostics.totalPoints = numel(result.Cp);
diagnostics.skippedLowDimensionlessFrequencyPoints = nnz(result.skippedLowDimensionlessFrequency);
diagnostics.minDimensionlessFrequency = result.options.minDimensionlessFrequency;
diagnostics.trackingDirection = string(result.options.trackingDirection);
diagnostics.trackingMethod = string(result.options.trackingMethod);
if any(valid)
    diagnostics.minCp = min(result.Cp(valid));
    diagnostics.maxCp = max(result.Cp(valid));
    diagnostics.maxFrequencyValid = max(result.frequency(valid));
    diagnostics.minDimensionlessFrequencyValid = min(result.dimensionlessFrequency(valid));
    diagnostics.maxDimensionlessFrequencyValid = max(result.dimensionlessFrequency(valid));
    diagnostics.minSigmaMin = min(result.sigmaMin(valid));
    diagnostics.medianMAC = median(result.modalMAC(valid), 'omitnan');
    diagnostics.minMAC = min(result.modalMAC(valid), [], 'omitnan');
else
    diagnostics.minCp = nan;
    diagnostics.maxCp = nan;
    diagnostics.maxFrequencyValid = nan;
    diagnostics.minDimensionlessFrequencyValid = nan;
    diagnostics.maxDimensionlessFrequencyValid = nan;
    diagnostics.minSigmaMin = nan;
    diagnostics.medianMAC = nan;
    diagnostics.minMAC = nan;
end
diagnostics.M54_variant = string(result.options.M54_variant);
diagnostics.gridInfo = result.gridInfo;
end
