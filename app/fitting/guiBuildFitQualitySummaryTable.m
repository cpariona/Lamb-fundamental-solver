function fitQualitySummaryTable = guiBuildFitQualitySummaryTable(fitResult, qc)
%GUIBUILDFITQUALITYSUMMARYTABLE Build one-row global fit quality summary.

metrics = fitResult.metrics;
identifiability = fitResult.identifiability;

RMSE_mps = localField(metrics, 'RMSE', nan);
MAE_mps = localField(metrics, 'MAE', nan);
R2 = localField(metrics, 'R2', nan);
NRMSE_MeanAbs = localField(metrics, 'NRMSE_MeanAbs', nan);
NumValid = localField(metrics, 'NumValid', nan);
MaxAbsResidual_mps = localField(metrics, 'MaxAbsResidual', nan);
ConstantRMSE_mps = localField(qc, 'ConstantRMSE_mps', nan);
ImprovementOverConstant = localField(qc, 'ImprovementOverConstant', nan);
ExperimentalDispersionRatio = localField(qc, 'ExperimentalDispersionRatio', nan);
ModelDispersionRatio = localField(qc, 'ModelDispersionRatio', nan);
SensitivityScore = localField(qc, 'SensitivityScore', nan);
PhysicalQC = string(localField(qc, 'classification', ""));
Warning = strjoin(string(localField(qc, 'reasons', strings(0, 1))), '; ');
Identifiability = string(localField(identifiability, 'classification', ""));
IdentifiabilityMessage = string(localField(identifiability, 'message', ""));
AIC = nan;
BIC = nan;

fitQualitySummaryTable = table(RMSE_mps, MAE_mps, R2, AIC, BIC, NRMSE_MeanAbs, ...
    NumValid, MaxAbsResidual_mps, ConstantRMSE_mps, ImprovementOverConstant, ...
    ExperimentalDispersionRatio, ModelDispersionRatio, SensitivityScore, ...
    PhysicalQC, Warning, Identifiability, IdentifiabilityMessage);
end

function value = localField(s, fieldName, defaultValue)
value = defaultValue;
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = s.(fieldName);
end
end
