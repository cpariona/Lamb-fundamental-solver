function normalized = guiNormalizeAcoustoelasticIOPHGOSweep(sweepResult, summary, request)
%GUINORMALIZEACOUSTOELASTICIOPHGOSWEEP Normalize canonical AE sweep output.

n = numel(sweepResult.results);
curves = repmat(struct( ...
    'label', "", ...
    'sweepValue', nan, ...
    'sweepValueDisplay', nan, ...
    'frequency_Hz', [], ...
    'Cp_mps', [], ...
    'validMask', [], ...
    'lastValidFrequency_Hz', nan, ...
    'rawBranch', []), 1, n);

for i = 1:n
    result = sweepResult.results{i};
    curves(i).label = formatDisplayValue(sweepResult, i);
    curves(i).sweepValue = sweepResult.values(i);
    curves(i).sweepValueDisplay = sweepResult.displayValues(i);
    curves(i).rawBranch = result;

    if isempty(result) || ~isstruct(result) || ~isfield(result, 'frequency_Hz')
        curves(i).frequency_Hz = nan;
        curves(i).Cp_mps = nan;
        curves(i).validMask = false;
        continue;
    end

    frequency = result.frequency_Hz(:);
    cp = result.phaseVelocity_mps(:);
    valid = logical(result.validMask(:)) & isfinite(frequency) & isfinite(cp);

    curves(i).frequency_Hz = frequency;
    curves(i).Cp_mps = cp;
    curves(i).validMask = valid;
    if any(valid)
        curves(i).lastValidFrequency_Hz = frequency(find(valid, 1, 'last'));
    end
end

normalized = struct();
normalized.modelFamily = "acoustoelastic_iop_hgo";
normalized.modelName = "AcoustoelasticIOPHGO";
normalized.branchName = string(getRequestField(request, 'branchName', "atlasA0"));
normalized.sweepField = string(request.sweepField);
normalized.sweepLabel = string(getRequestField(request, 'sweepLabel', request.sweepField));
normalized.sweepUnit = string(getRequestField(request, 'displayUnit', ""));
normalized.displayScale = getRequestField(request, 'displayScale', 1);
normalized.curves = curves;
normalized.summaryTable = summary.conditionTable;
normalized.dispersionTable = summary.dispersionTable;
normalized.branchTable = summary.branchTable;
normalized.metadata = struct('request', request, 'policy', "atlasA0");
end

function text = formatDisplayValue(sweepResult, index)
value = sweepResult.displayValues(index);
formatSpec = "%.6g";
units = "";
if isfield(sweepResult, 'spec')
    if isfield(sweepResult.spec, 'valueFormatter')
        formatSpec = string(sweepResult.spec.valueFormatter);
    end
    if isfield(sweepResult.spec, 'units')
        units = string(sweepResult.spec.units);
    end
end
text = string(sprintf(char(formatSpec), value));
if strlength(units) > 0
    text = text + " " + units;
end
end

function value = getRequestField(request, fieldName, defaultValue)
if isstruct(request) && isfield(request, fieldName) && ~isempty(request.(fieldName))
    value = request.(fieldName);
else
    value = defaultValue;
end
end
