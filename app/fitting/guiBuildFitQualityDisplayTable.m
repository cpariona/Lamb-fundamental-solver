function displayTable = guiBuildFitQualityDisplayTable(fitQualitySummaryTable)
%GUIBUILDFITQUALITYDISPLAYTABLE Convert one-row quality summary to Metric/Value.

Metric = strings(0, 1);
Value = strings(0, 1);

if isempty(fitQualitySummaryTable) || ~istable(fitQualitySummaryTable) || height(fitQualitySummaryTable) < 1
    displayTable = table(Metric, Value);
    return;
end

metricMap = [
    "RMSE_mps", "RMSE [m/s]"
    "MAE_mps", "MAE [m/s]"
    "R2", "R^2"
    "AIC", "AIC"
    "BIC", "BIC"
    "NRMSE_MeanAbs", "NRMSE"
    "NumValid", "Valid points"
    "MaxAbsResidual_mps", "Maximum residual [m/s]"
    "ConstantRMSE_mps", "Constant baseline RMSE [m/s]"
    "ImprovementOverConstant", "Improvement over constant"
    "ExperimentalDispersionRatio", "Experimental dispersion ratio"
    "ModelDispersionRatio", "Model dispersion ratio"
    "SensitivityScore", "Sensitivity score"
    "PhysicalQC", "Physical quality check"
    "Warning", "Baseline assessment"
    "Identifiability", "Identifiability"
    "IdentifiabilityMessage", "Identifiability note"
    ];

for i = 1:size(metricMap, 1)
    internalName = metricMap(i, 1);
    if ~ismember(internalName, string(fitQualitySummaryTable.Properties.VariableNames))
        continue;
    end
    rawValue = fitQualitySummaryTable.(internalName)(1);
    displayValue = formatValue(rawValue, internalName);
    if strlength(displayValue) == 0
        continue;
    end
    Metric(end + 1, 1) = metricMap(i, 2); %#ok<AGROW>
    Value(end + 1, 1) = displayValue; %#ok<AGROW>
end

displayTable = table(Metric, Value);
end

function text = formatValue(value, name)
if isnumeric(value) || islogical(value)
    value = double(value);
    if ~isfinite(value)
        text = "";
    elseif name == "NumValid"
        text = string(sprintf('%.0f', value));
    elseif abs(value) >= 1e4 || (abs(value) > 0 && abs(value) < 1e-3)
        text = string(sprintf('%.6g', value));
    else
        text = string(sprintf('%.5g', value));
    end
else
    text = strtrim(string(value));
    text = replace(text, "_", " ");
    if strlength(text) > 0
        text = upper(extractBefore(text, 2)) + extractAfter(text, 1);
    end
end
end
