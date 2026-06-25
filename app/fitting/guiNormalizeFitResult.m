function normalized = guiNormalizeFitResult(fitResult, request)
%GUINORMALIZEFITRESULT Normalize model-specific fit output for app plotting/export.

validMask = fitResult.validMask(:) & isfinite(fitResult.frequency_Hz(:)) & ...
    isfinite(fitResult.Cp_exp_mps(:)) & isfinite(fitResult.Cp_fit_mps(:));

qc = assessFitPhysicalQuality(fitResult);
fullCurve = guiEvaluateFitFullCurve(fitResult);

normalized = struct();
normalized.modelFamily = string(fitResult.modelFamily);
normalized.modelName = localModelName(fitResult.modelFamily);
normalized.branchName = string(fitResult.branchName);
normalized.freeParams = string(fitResult.freeParams(:));
normalized.frequency_Hz = fitResult.frequency_Hz(:);
normalized.Cp_exp_mps = fitResult.Cp_exp_mps(:);
normalized.Cp_fit_mps = fitResult.Cp_fit_mps(:);
normalized.residuals_mps = fitResult.residualInfo.rawResiduals_mps(:);
normalized.validMask = validMask;
normalized.bestParams = fitResult.bestParams;
normalized.fixedParams = fitResult.fixedParams;
normalized.metrics = fitResult.metrics;
normalized.identifiability = fitResult.identifiability;
normalized.optimizer = fitResult.optimizer;
normalized.qc = qc;
normalized.fullCurve = fullCurve;
normalized.request = request;

normalized.summaryTable = localBuildSummaryTable(fitResult, qc);
end

function modelName = localModelName(modelFamily)
switch lower(string(modelFamily))
    case "rayleigh_lamb"
        modelName = "RayleighLamb";
    case "mrlfe"
        modelName = "mRLFERealK";
    case "acoustoelastic_iop_hgo"
        modelName = "AcoustoelasticIOPHGO";
    otherwise
        modelName = string(modelFamily);
end
end

function summaryTable = localBuildSummaryTable(fitResult, qc)
paramNames = string(fitResult.freeParams(:));
paramValues = nan(numel(paramNames), 1);
for i = 1:numel(paramNames)
    name = char(paramNames(i));
    if isfield(fitResult.bestParams, name)
        paramValues(i) = fitResult.bestParams.(name);
    end
end

summaryTable = table(paramNames, paramValues, ...
    'VariableNames', {'Parameter', 'Value'});
summaryTable.RMSE_mps = repmat(fitResult.metrics.RMSE, height(summaryTable), 1);
summaryTable.NRMSE_MeanAbs = repmat(fitResult.metrics.NRMSE_MeanAbs, height(summaryTable), 1);
summaryTable.ConstantRMSE_mps = repmat(qc.ConstantRMSE_mps, height(summaryTable), 1);
summaryTable.ImprovementOverConstant = repmat(qc.ImprovementOverConstant, height(summaryTable), 1);
summaryTable.ExpDispersionRatio = repmat(qc.ExperimentalDispersionRatio, height(summaryTable), 1);
summaryTable.ModelDispersionRatio = repmat(qc.ModelDispersionRatio, height(summaryTable), 1);
summaryTable.SensitivityScore = repmat(qc.SensitivityScore, height(summaryTable), 1);
summaryTable.PhysicalQC = repmat(string(qc.classification), height(summaryTable), 1);
summaryTable.QCReasons = repmat(strjoin(qc.reasons, '; '), height(summaryTable), 1);
summaryTable.Identifiability = repmat(string(fitResult.identifiability.classification), height(summaryTable), 1);
end
