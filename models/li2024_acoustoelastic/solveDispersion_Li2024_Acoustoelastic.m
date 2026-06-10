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
previousCp = nan;

for i = 1:n
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
result.omega = 2*pi*f;
result.Cp = cp;
result.k = 2*pi*f ./ cp;
result.kThickness = result.k .* params.thickness;
result.objective = objective;
result.sigmaMin = sigmaMin;
result.valid = valid & isfinite(cp);
result.validCp = result.valid;
result.s1 = s1;
result.s2 = s2;
result.xi = xi;
result.params = params;
result.options = options;
result.gridInfo = gridInfo;
result.diagnostics = summarizeResult(result);
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

scores = candidateObj(:);
if isfinite(previousCp)
    scores = scores + options.previousCpWeight * abs(log(candidateCp(:) ./ previousCp));
else
    target = getInitialBranchTarget(params, options);
    scores = scores + options.firstPointPreferenceWeight * abs(log(candidateCp(:) ./ target));
end

[~, bestLocal] = min(scores);
bestCp = candidateCp(bestLocal);
bestObj = candidateObj(bestLocal);
[~, bestDetails] = objective_Li2024_Acoustoelastic(params.alpha, params.beta, params.gamma, ...
    params.thickness, params.rho, params.rhoF, params.fluidBulkModulus, f, bestCp, options);
bestSigmaMin = bestDetails.sigmaMin;
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
if any(valid)
    diagnostics.minCp = min(result.Cp(valid));
    diagnostics.maxCp = max(result.Cp(valid));
    diagnostics.maxFrequencyValid = max(result.frequency(valid));
    diagnostics.minSigmaMin = min(result.sigmaMin(valid));
else
    diagnostics.minCp = nan;
    diagnostics.maxCp = nan;
    diagnostics.maxFrequencyValid = nan;
    diagnostics.minSigmaMin = nan;
end
diagnostics.M54_variant = string(result.options.M54_variant);
diagnostics.gridInfo = result.gridInfo;
end
