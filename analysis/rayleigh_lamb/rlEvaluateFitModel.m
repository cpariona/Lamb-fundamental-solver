function [Cp_mps, rawResult] = rlEvaluateFitModel(params, frequency_Hz, branchName, options)
%RLEVALUATEFITMODEL Evaluate Rayleigh-Lamb Cp on a fitting frequency grid.
%
% [Cp_mps, rawResult] = rlEvaluateFitModel(params, frequency_Hz, branchName, options)
%
% This helper is intended for fitting. It evaluates each experimental
% frequency independently using a branch-specific physical search window. It
% does not use continuation or prediction fallback, so one failed point cannot
% collapse the rest of the fitting grid and no predictor-only points are used as
% model data.

if nargin < 3 || isempty(branchName)
    branchName = "A0";
end
if nargin < 4 || isempty(options)
    options = rlDefaultOptions("Fast");
end

branchName = string(branchName);
frequencyInput = frequency_Hz(:);
if isempty(frequencyInput) || any(~isfinite(frequencyInput)) || any(frequencyInput <= 0)
    error('frequency_Hz must contain positive finite values.');
end

rlValidateParams(params);
rlValidateOptions(options);

material = rlComputeMaterial(params);
geometry = rlComputeGeometry(params);
omega = 2 * pi * frequencyInput;

Cp_mps = nan(size(frequencyInput));
residual = nan(size(frequencyInput));

for i = 1:numel(frequencyInput)
    fi = frequencyInput(i);
    geometryForSpec = geometry;
    geometryForSpec.frequency0 = fi;
    branchSpec = rlMakeBranchSpec(branchName, material, geometryForSpec);
    switch branchName
        case "A0"
            residualFcn = @(Cp) rlAResidual(Cp, fi, material.CL, material.CT, geometry.halfThickness);
        case "S0"
            residualFcn = @(Cp) rlSResidual(Cp, fi, material.CL, material.CT, geometry.halfThickness);
        otherwise
            error('Unsupported Rayleigh-Lamb fitting branch: %s.', branchName);
    end
    [Cp_mps(i), residual(i)] = localSolveIndependentFrequency(residualFcn, branchSpec, material, options);
end

k = omega ./ Cp_mps;
validMask = isfinite(Cp_mps) & isfinite(residual) & isfinite(k) & Cp_mps > 0;
Cp_mps(~validMask) = NaN;
k(~validMask) = NaN;

rawResult = struct();
rawResult.modelFamily = "rayleigh_lamb";
rawResult.branchName = branchName;
rawResult.frequency_Hz = frequencyInput;
rawResult.Cp_mps = Cp_mps;
rawResult.omega = omega;
rawResult.k = k;
rawResult.kThickness = k * geometry.thickness;
rawResult.residual = residual;
rawResult.validMask = validMask;
rawResult.material = material;
rawResult.geometry = rmfield(geometry, 'halfThickness');
rawResult.options = options;
rawResult.trackingMode = "independent_frequency_search";
end

function [bestCp, bestResidual] = localSolveIndependentFrequency(residualFcn, branchSpec, material, options)
bestCp = nan;
bestResidual = inf;

CpMinAbs = getOption(options, 'minCpAbsolute', 1e-4);
CpMin = max(CpMinAbs, getOption(options, 'minCpRelativeToCT', 1e-3) * material.CT);
CpMax = max(getOption(options, 'maxCpFactorCT', 20) * material.CT, getOption(options, 'minCpGlobalMax', 1.0));

if isfield(branchSpec, 'initialSearchRange') && numel(branchSpec.initialSearchRange) == 2 && ...
        all(isfinite(branchSpec.initialSearchRange)) && branchSpec.initialSearchRange(2) > branchSpec.initialSearchRange(1)
    CpMin = max(CpMin, branchSpec.initialSearchRange(1));
    CpMax = min(CpMax, branchSpec.initialSearchRange(2));
end

if CpMax <= CpMin
    return;
end

numGrid = max(200, getOption(options, 'gridPointsInitial', 1200));
CpGrid = linspace(CpMin, CpMax, numGrid);
RGrid = arrayfun(residualFcn, CpGrid);
valid = isfinite(RGrid) & CpGrid > CpMinAbs;
CpGrid = CpGrid(valid);
RGrid = RGrid(valid);
if numel(CpGrid) < 5
    return;
end

candidateIdx = localFindLocalMinima(RGrid);
if isempty(candidateIdx)
    [~, idx] = min(RGrid);
    candidateIdx = idx;
end

bestScore = inf;
for j = candidateIdx(:).'
    leftIdx = max(j - 2, 1);
    rightIdx = min(j + 2, numel(CpGrid));
    CpLeft = CpGrid(leftIdx);
    CpRight = CpGrid(rightIdx);
    if CpRight <= CpLeft
        continue;
    end
    try
        CpCandidate = fminbnd(residualFcn, CpLeft, CpRight);
        RCandidate = residualFcn(CpCandidate);
        if ~isfinite(CpCandidate) || ~isfinite(RCandidate) || CpCandidate <= 0
            continue;
        end
        score = RCandidate;
        if branchSpec.preferLowestCp
            score = score * (1 + 0.01 * CpCandidate / max(material.CT, eps));
        end
        if isfinite(branchSpec.initialCpGuess) && branchSpec.initialCpGuess > 0
            relSeed = abs(CpCandidate - branchSpec.initialCpGuess) / branchSpec.initialCpGuess;
            score = score * (1 + getOption(options, 'initialGuessWeight', 0.25) * relSeed);
        end
        if score < bestScore
            bestScore = score;
            bestCp = CpCandidate;
            bestResidual = RCandidate;
        end
    catch
    end
end
end

function idx = localFindLocalMinima(y)
idx = [];
if numel(y) < 3
    return;
end
for i = 2:numel(y)-1
    if isfinite(y(i)) && y(i) < y(i-1) && y(i) < y(i+1)
        idx(end+1) = i; %#ok<AGROW>
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
