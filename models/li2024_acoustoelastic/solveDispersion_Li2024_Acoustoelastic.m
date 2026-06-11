function result = solveDispersion_Li2024_Acoustoelastic(params, options)
%SOLVEDISPERSION_LI2024_ACOUSTOELASTIC Solve direct alpha-beta-gamma dispersion.
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

for jj = 1:numel(trackOrder)
    i = trackOrder(jj);

    [cp(i), objective(i), sigmaMin(i), details] = solveOneFrequency(params, options, f(i), cGrid, previousCp);
    if isfinite(cp(i))
        if isfinite(previousCp) && isfinite(options.maxRelativeCpJump)
            relJump = abs(cp(i) - previousCp) / max(abs(previousCp), eps);
            if relJump > options.maxRelativeCpJump
                break;
            end
        end
        previousCp = cp(i);
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

function [bestCp, bestObj, bestSigmaMin, bestDetails] = solveOneFrequency(params, options, f, cGrid, previousCp)
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
candidateIdx = filterCandidatesByContinuity(candidateIdx, cGrid, previousCp, options);

[~, order] = sort(objVals(candidateIdx), 'ascend');
candidateIdx = candidateIdx(order);
candidateIdx = candidateIdx(1:min(numel(candidateIdx), options.maxLocalCandidates));

candidateCp = cGrid(candidateIdx);
candidateObj = objVals(candidateIdx);

if options.refineLocalMinima
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

if isfinite(previousCp)
    scores = candidateObj(:) + options.previousCpWeight * abs(log(candidateCp(:) ./ previousCp));
else
    scores = firstPointScores(candidateCp(:), candidateObj(:), params, options);
end

[~, bestLocal] = min(scores);
bestCp = candidateCp(bestLocal);
bestObj = candidateObj(bestLocal);
[~, bestDetails] = objective_Li2024_Acoustoelastic(params.alpha, params.beta, params.gamma, ...
    params.thickness, params.rho, params.rhoF, params.fluidBulkModulus, f, bestCp, options);
bestSigmaMin = bestDetails.sigmaMin;
end

function candidateIdx = filterCandidatesByBranchBand(candidateIdx, cGrid, params, options)
if ~isfield(options, 'branchSelectionMode') || string(options.branchSelectionMode) ~= "band"
    return;
end

shearSpeed = sqrt(params.alpha / params.rho);
yCandidates = cGrid(candidateIdx) ./ shearSpeed;
branch = string(options.branch);

switch branch
    case "A0"
        band = options.A0Band;
    case "A0High"
        band = options.A0HighBand;
    case "S0"
        band = options.S0Band;
    otherwise
        return;
end

mask = yCandidates >= band(1) & yCandidates <= band(2);
if any(mask)
    candidateIdx = candidateIdx(mask);
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

function diagnostics = summarizeResult(result)
valid = result.validCp & isfinite(result.Cp);
diagnostics = struct();
diagnostics.validCpPoints = nnz(valid);
diagnostics.totalPoints = numel(result.Cp);
diagnostics.skippedLowDimensionlessFrequencyPoints = nnz(result.skippedLowDimensionlessFrequency);
diagnostics.minDimensionlessFrequency = result.options.minDimensionlessFrequency;
diagnostics.trackingDirection = string(result.options.trackingDirection);
if any(valid)
    diagnostics.minCp = min(result.Cp(valid));
    diagnostics.maxCp = max(result.Cp(valid));
    diagnostics.maxFrequencyValid = max(result.frequency(valid));
    diagnostics.minDimensionlessFrequencyValid = min(result.dimensionlessFrequency(valid));
    diagnostics.maxDimensionlessFrequencyValid = max(result.dimensionlessFrequency(valid));
    diagnostics.minSigmaMin = min(result.sigmaMin(valid));
else
    diagnostics.minCp = nan;
    diagnostics.maxCp = nan;
    diagnostics.maxFrequencyValid = nan;
    diagnostics.minDimensionlessFrequencyValid = nan;
    diagnostics.maxDimensionlessFrequencyValid = nan;
    diagnostics.minSigmaMin = nan;
end
diagnostics.M54_variant = string(result.options.M54_variant);
diagnostics.gridInfo = result.gridInfo;
end
