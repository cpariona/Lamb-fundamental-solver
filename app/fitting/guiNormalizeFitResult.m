function normalized = guiNormalizeFitResult(fitResult, request)
%GUINORMALIZEFITRESULT Normalize model-specific fit output for app plotting/export.

validMask = fitResult.validMask(:) & isfinite(fitResult.frequency_Hz(:)) & ...
    isfinite(fitResult.Cp_exp_mps(:)) & isfinite(fitResult.Cp_fit_mps(:));

qc = lamb.fitting.assessFitPhysicalQuality(fitResult);
fullCurve = guiBuildFitDisplayCurve(fitResult);

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

normalized.parameterSummaryTable = guiBuildFitParameterSummaryTable(fitResult, request);
normalized.fitQualitySummaryTable = guiBuildFitQualitySummaryTable(fitResult, qc);
normalized.summaryTable = normalized.parameterSummaryTable;
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
