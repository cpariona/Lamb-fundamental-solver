function normalized = guiNormalizeMRLFESweep(sweepResult, summaryTable, request, modelName, branchName)
%GUINORMALIZEMRLFESWEEP Normalize mRLFE sweep output for GUI plotting/export.
%
% Plotting code should consume this normalized structure instead of reading
% model-specific raw solver fields directly.

n = numel(sweepResult.results);
curves = repmat(struct( ...
    'label', "", ...
    'sweepValue', nan, ...
    'sweepValueDisplay', nan, ...
    'frequency_Hz', [], ...
    'Cp_mps', [], ...
    'validMask', [], ...
    'lastValidFrequency_Hz', nan, ...
    'rawBranch', [], ...
    'modelResult', [], ...
    'status', "", ...
    'errorIdentifier', "", ...
    'errorMessage', ""), 1, n);

for i = 1:n
    branch = extractMRLFESweepBranch(sweepResult.results{i}, branchName);
    curves(i).label = makeMRLFELegendLabel(sweepResult, i);
    curves(i).sweepValue = sweepResult.values(i);
    curves(i).sweepValueDisplay = sweepResult.displayValues(i);
    curves(i).rawBranch = branch;
    if isfield(sweepResult, 'points') && numel(sweepResult.points) >= i && isstruct(sweepResult.points{i})
        point = sweepResult.points{i};
        curves(i).status = string(point.status);
        curves(i).errorIdentifier = string(point.errorIdentifier);
        curves(i).errorMessage = string(point.errorMessage);
        if isfield(point, 'modelResult')
            curves(i).modelResult = point.modelResult;
        end
    end

    if isempty(branch)
        continue;
    end

    valid = branch.validMask(:);
    frequency = branch.frequency_Hz(:);
    cp = branch.phaseVelocity_mps(:);
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
normalized.modelFamily = "mrlfe";
normalized.modelName = string(modelName);
normalized.branchName = string(branchName);
normalized.sweepField = string(request.sweepField);
normalized.sweepLabel = string(sweepResult.spec.label);
normalized.sweepUnit = string(sweepResult.spec.units);
normalized.displayScale = sweepResult.spec.displayScale;
normalized.curves = curves;
normalized.summaryTable = summaryTable;
normalized.metadata = struct();
normalized.metadata.request = request;
if isfield(sweepResult, 'points')
    normalized.metadata.points = sweepResult.points;
end
end

function branch = extractMRLFESweepBranch(result, branchName)
branch = [];
branchName = string(branchName);

if isfield(result, 'model') && string(result.model) == "mrlfe" && ...
        string(result.branch) == branchName
    branch = result;
end
end

function txt = makeMRLFELegendLabel(sweepResult, idx)
spec = sweepResult.spec;
value = sweepResult.displayValues(idx);
if isfield(spec, 'units') && strlength(string(spec.units)) > 0
    txt = sprintf('%s = %.4g %s', string(spec.label), value, string(spec.units));
else
    txt = sprintf('%s = %.4g', string(spec.label), value);
end
end
