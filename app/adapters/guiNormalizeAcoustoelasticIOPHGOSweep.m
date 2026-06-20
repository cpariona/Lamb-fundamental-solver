function normalized = guiNormalizeAcoustoelasticIOPHGOSweep(rawResults, summary, request)
%GUINORMALIZEACOUSTOELASTICIOPHGOSWEEP Normalize Acoustoelastic IOP/HGO sweep output.
%
% The normalized curve schema matches guiPlotSweepResult and keeps official
% atlasA0 outputs separate from diagnostic branch information.

conditions = rawResults.conditions;
n = numel(conditions);
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
    condition = conditions(i);
    result = condition.result;

    curves(i).label = string(condition.sweepValueDisplay);
    curves(i).sweepValue = condition.sweepValue;
    curves(i).sweepValueDisplay = condition.sweepValueDisplay;
    curves(i).rawBranch = result;

    frequency = result.frequency(:);
    cp = result.Cp(:);
    valid = result.validCp(:);
    valid = valid & isfinite(frequency) & isfinite(cp);

    curves(i).frequency_Hz = frequency;
    curves(i).Cp_mps = cp;
    curves(i).validMask = valid;

    if any(valid)
        lastIdx = find(valid, 1, 'last');
        curves(i).lastValidFrequency_Hz = frequency(lastIdx);
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
normalized.metadata = struct();
normalized.metadata.request = request;
normalized.metadata.policy = "atlasA0";
end

function value = getRequestField(request, fieldName, defaultValue)
if isstruct(request) && isfield(request, fieldName) && ~isempty(request.(fieldName))
    value = request.(fieldName);
else
    value = defaultValue;
end
end
