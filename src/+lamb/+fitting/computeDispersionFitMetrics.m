function metrics = computeDispersionFitMetrics(CpModel_mps, experimental)
%COMPUTEDISPERSIONFITMETRICS Compute basic metrics for dispersion fitting.
%
% Metrics are computed on points that are valid in the experimental data and
% finite in the model output.

[~, residualInfo] = lamb.fitting.computeDispersionFitResiduals(CpModel_mps, experimental, struct('useStandardErrorWeights', false));

rawResiduals = residualInfo.rawResiduals_mps;
experimental = lamb.fitting.normalizeExperimentalDispersionData(experimental);
CpExpValid = experimental.Cp_mps(residualInfo.validMask);

metrics = struct();
metrics.NumValid = numel(rawResiduals);
metrics.RMSE = sqrt(mean(rawResiduals.^2));
metrics.MAE = mean(abs(rawResiduals));
metrics.Bias = mean(rawResiduals);
metrics.MaxAbsResidual = max(abs(rawResiduals));

rangeCp = max(CpExpValid) - min(CpExpValid);
meanAbsCp = mean(abs(CpExpValid));

if isfinite(rangeCp) && rangeCp > 0
    metrics.NRMSE_Range = metrics.RMSE / rangeCp;
else
    metrics.NRMSE_Range = NaN;
end

if isfinite(meanAbsCp) && meanAbsCp > 0
    metrics.NRMSE_MeanAbs = metrics.RMSE / meanAbsCp;
else
    metrics.NRMSE_MeanAbs = NaN;
end

if numel(CpExpValid) > 1
    totalSumSquares = sum((CpExpValid - mean(CpExpValid)).^2);
    residualSumSquares = sum(rawResiduals.^2);
    if totalSumSquares > 0
        metrics.R2 = 1 - residualSumSquares / totalSumSquares;
    else
        metrics.R2 = NaN;
    end
else
    metrics.R2 = NaN;
end
end
