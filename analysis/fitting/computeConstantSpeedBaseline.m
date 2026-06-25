function baseline = computeConstantSpeedBaseline(experimental)
%COMPUTECONSTANTSPEEDBASELINE Compute a constant-Cp baseline for fit QC.
%
% baseline = computeConstantSpeedBaseline(experimental)
%
% The baseline uses the mean experimental phase speed over valid points. It is
% intended as a null model: if a physical dispersion model does not improve on
% this baseline, the fit may be numerically good but physically uninformative.

experimental = validateExperimentalDispersionData(experimental, 1);
valid = experimental.validMask(:) & isfinite(experimental.Cp_mps(:));
CpExp = experimental.Cp_mps(:);
CpValid = CpExp(valid);

Cp0 = mean(CpValid);
CpBaseline = Cp0 * ones(size(CpExp));
residuals = CpBaseline(valid) - CpValid;

baseline = struct();
baseline.modelName = "constant_speed";
baseline.Cp0_mps = Cp0;
baseline.Cp_mps = CpBaseline;
baseline.validMask = valid;
baseline.residuals_mps = residuals;
baseline.NumValid = nnz(valid);
baseline.RMSE = sqrt(mean(residuals.^2));
baseline.MAE = mean(abs(residuals));
baseline.MaxAbsResidual = max(abs(residuals));
baseline.RangeCp_mps = max(CpValid) - min(CpValid);
baseline.MeanAbsCp_mps = mean(abs(CpValid));
if baseline.MeanAbsCp_mps > 0
    baseline.RangeRatio = baseline.RangeCp_mps / baseline.MeanAbsCp_mps;
    baseline.NRMSE_MeanAbs = baseline.RMSE / baseline.MeanAbsCp_mps;
else
    baseline.RangeRatio = NaN;
    baseline.NRMSE_MeanAbs = NaN;
end
end
