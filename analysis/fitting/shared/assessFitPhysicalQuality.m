function qc = assessFitPhysicalQuality(fitResult)
%ASSESSFITPHYSICALQUALITY Assess physical/numerical quality of a fit.
%
% qc = assessFitPhysicalQuality(fitResult)
%
% This helper does not reject a fit. It classifies warning conditions that are
% not captured by RMSE alone, such as nearly-flat experimental data, physical
% model not improving over a constant-speed baseline, low model dispersion,
% boundary hits, and low local sensitivity.

experimental = struct();
experimental.frequency_Hz = fitResult.frequency_Hz(:);
experimental.Cp_mps = fitResult.Cp_exp_mps(:);
experimental.validMask = fitResult.validMask(:) & isfinite(fitResult.Cp_exp_mps(:));
baseline = computeConstantSpeedBaseline(experimental);

valid = fitResult.validMask(:) & isfinite(fitResult.Cp_exp_mps(:)) & isfinite(fitResult.Cp_fit_mps(:));
CpExp = fitResult.Cp_exp_mps(:);
CpFit = fitResult.Cp_fit_mps(:);
CpExpValid = CpExp(valid);
CpFitValid = CpFit(valid);

expRangeRatio = localRangeRatio(CpExpValid);
modelRangeRatio = localRangeRatio(CpFitValid);
fitRMSE = fitResult.metrics.RMSE;
constantRMSE = baseline.RMSE;
if isfinite(constantRMSE) && constantRMSE > 0
    improvementOverConstant = 1 - fitRMSE / constantRMSE;
else
    improvementOverConstant = 0;
end

boundaryHit = localBoundaryHit(fitResult);
sensitivityScore = localSensitivityScore(fitResult);
reasons = strings(0, 1);

flatExpThreshold = 0.015;
weakModelDispersionThreshold = 0.015;
constantCompetitiveThreshold = 0.10;
lowSensitivityThreshold = 1e-3;

if expRangeRatio < flatExpThreshold
    reasons(end+1, 1) = "near-flat experimental curve"; %#ok<AGROW>
end

branchName = string(fitResult.branchName);
modelFamily = string(fitResult.modelFamily);
if (branchName == "A0" || branchName == "A0Like" || branchName == "atlasA0") && modelRangeRatio < weakModelDispersionThreshold
    reasons(end+1, 1) = "weakly dispersive fitted A0-like curve"; %#ok<AGROW>
end

if improvementOverConstant < constantCompetitiveThreshold
    reasons(end+1, 1) = "constant-speed baseline is competitive"; %#ok<AGROW>
end

if boundaryHit
    reasons(end+1, 1) = "fitted parameter is near declared bound"; %#ok<AGROW>
end

if sensitivityScore < lowSensitivityThreshold
    reasons(end+1, 1) = "low local parameter sensitivity"; %#ok<AGROW>
end

if modelFamily == "acoustoelastic_iop_hgo" && isfield(fitResult.modelEvaluation, 'solverResult') && ...
        isfield(fitResult.modelEvaluation.solverResult, 'quality') && ...
        isfield(fitResult.modelEvaluation.solverResult.quality, 'selectionFallbackUsed') && ...
        fitResult.modelEvaluation.solverResult.quality.selectionFallbackUsed
    reasons(end+1, 1) = "AE atlas fallback was used"; %#ok<AGROW>
end

if isempty(reasons)
    classification = "pass";
elseif any(reasons == "constant-speed baseline is competitive") || any(reasons == "low local parameter sensitivity")
    classification = "warning";
else
    classification = "caution";
end

qc = struct();
qc.classification = classification;
qc.reasons = reasons;
qc.baseline = baseline;
qc.NumValid = nnz(valid);
qc.ExperimentalDispersionRatio = expRangeRatio;
qc.ModelDispersionRatio = modelRangeRatio;
qc.ConstantRMSE_mps = constantRMSE;
qc.ModelRMSE_mps = fitRMSE;
qc.ImprovementOverConstant = improvementOverConstant;
qc.BoundaryHit = boundaryHit;
qc.SensitivityScore = sensitivityScore;
qc.BranchName = branchName;
qc.ModelFamily = modelFamily;
end

function ratio = localRangeRatio(values)
values = values(:);
values = values(isfinite(values));
if isempty(values)
    ratio = NaN;
    return;
end
meanAbs = mean(abs(values));
if meanAbs <= 0
    ratio = NaN;
else
    ratio = (max(values) - min(values)) / meanAbs;
end
end

function boundaryHit = localBoundaryHit(fitResult)
boundaryHit = false;
if ~isfield(fitResult, 'xBest') || ~isfield(fitResult, 'lowerBounds') || ~isfield(fitResult, 'upperBounds')
    return;
end
x = fitResult.xBest(:);
lb = fitResult.lowerBounds(:);
ub = fitResult.upperBounds(:);
for i = 1:numel(x)
    if ~isfinite(x(i)) || ~isfinite(lb(i)) || ~isfinite(ub(i)) || ub(i) <= lb(i)
        continue;
    end
    relToRange = min(abs(x(i) - lb(i)), abs(x(i) - ub(i))) / (ub(i) - lb(i));
    if relToRange < 0.02
        boundaryHit = true;
        return;
    end
end
end

function score = localSensitivityScore(fitResult)
score = NaN;
if ~isfield(fitResult, 'sensitivityMatrix') || isempty(fitResult.sensitivityMatrix)
    return;
end
S = fitResult.sensitivityMatrix;
S = S(isfinite(S));
if isempty(S)
    return;
end
Cp = fitResult.Cp_fit_mps(:);
Cp = Cp(isfinite(Cp));
if isempty(Cp)
    return;
end
cpScale = max(mean(abs(Cp)), eps);
paramScale = max(abs(fitResult.xBest(:)), 1);
score = norm(S(:) .* mean(paramScale), 2) / cpScale;
end
