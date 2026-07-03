function normalized = guiNormalizeFitResult(fitResult, request)
%GUINORMALIZEFITRESULT Normalize model-specific fit output for app plotting/export.

validMask = fitResult.validMask(:) & isfinite(fitResult.frequency_Hz(:)) & ...
    isfinite(fitResult.Cp_exp_mps(:)) & isfinite(fitResult.Cp_fit_mps(:));

qc = assessFitPhysicalQuality(fitResult);
tFullCurve = tic;
fullCurve = guiEvaluateFitFullCurve(fitResult);
fullCurve.elapsedSeconds = toc(tFullCurve);

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

normalized.summaryTable = localBuildSummaryTable(fitResult, qc, request);
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

function summaryTable = localBuildSummaryTable(fitResult, qc, request)
registry = guiGetFitRegistry();
family = localFindFamily(registry, fitResult.modelFamily);
n = numel(family.parameters);
Parameter = strings(n, 1);
Role = strings(n, 1);
Value = nan(n, 1);
Unit = strings(n, 1);
freeParams = string(fitResult.freeParams(:));

for i = 1:n
    meta = family.parameters(i);
    fieldName = char(meta.fieldName);
    Parameter(i) = string(meta.label);
    Unit(i) = string(meta.displayUnit);
    if any(freeParams == string(meta.fieldName))
        Role(i) = "Fit";
        if isfield(fitResult.bestParams, fieldName)
            Value(i) = fitResult.bestParams.(fieldName) ./ meta.displayScale;
        end
    else
        Role(i) = "Fixed";
        if string(meta.fixedDestination) == "controls"
            source = request.controls;
        else
            source = request.fixedParams;
        end
        if isfield(source, fieldName)
            Value(i) = source.(fieldName) ./ meta.displayScale;
        end
    end
end

summaryTable = table(Parameter, Role, Value, Unit);
summaryTable.RMSE_mps = repmat(fitResult.metrics.RMSE, n, 1);
summaryTable.NRMSE_MeanAbs = repmat(fitResult.metrics.NRMSE_MeanAbs, n, 1);
summaryTable.ConstantRMSE_mps = repmat(qc.ConstantRMSE_mps, n, 1);
summaryTable.ImprovementOverConstant = repmat(qc.ImprovementOverConstant, n, 1);
summaryTable.ExpDispersionRatio = repmat(qc.ExperimentalDispersionRatio, n, 1);
summaryTable.ModelDispersionRatio = repmat(qc.ModelDispersionRatio, n, 1);
summaryTable.SensitivityScore = repmat(qc.SensitivityScore, n, 1);
summaryTable.PhysicalQC = repmat(string(qc.classification), n, 1);
summaryTable.QCReasons = repmat(strjoin(qc.reasons, '; '), n, 1);
summaryTable.Identifiability = repmat(string(fitResult.identifiability.classification), n, 1);
end

function family = localFindFamily(registry, modelFamily)
modelFamily = string(modelFamily);
for i = 1:numel(registry.modelFamilies)
    if string(registry.modelFamilies(i).id) == modelFamily
        family = registry.modelFamilies(i);
        return;
    end
end
error('guiNormalizeFitResult:UnknownModelFamily', ...
    'Unknown fitting model family: %s.', modelFamily);
end
