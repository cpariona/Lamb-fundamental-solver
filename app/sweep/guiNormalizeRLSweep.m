function normalized = guiNormalizeRLSweep(sweepResult, summaryTable, request, modelName, branchName)
%GUINORMALIZERLSWEEP Normalize Rayleigh-Lamb sweep output for GUI plotting/export.

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
    branch = extractRLBranch(sweepResult.results{i}, branchName);
    curves(i).label = makeLegendLabel(sweepResult, i);
    curves(i).sweepValue = sweepResult.values(i);
    curves(i).sweepValueDisplay = sweepResult.displayValues(i);
    curves(i).rawBranch = branch;

    if isempty(branch)
        continue;
    end

    frequency = branch.frequency_Hz(:);
    cp = branch.phaseVelocity_mps(:);
    valid = getBranchValidityMask(branch) & isfinite(frequency) & isfinite(cp);

    curves(i).frequency_Hz = frequency;
    curves(i).Cp_mps = cp;
    curves(i).validMask = valid;

    if any(valid)
        lastIdx = find(valid, 1, 'last');
        curves(i).lastValidFrequency_Hz = frequency(lastIdx);
    end
end

normalized = struct();
normalized.modelFamily = "rayleigh_lamb";
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
end

function branch = extractRLBranch(result, branchName)
branch = [];
branchName = string(branchName);
if isfield(result, 'modes') && isfield(result.modes, char(branchName))
    branch = result.modes.(char(branchName));
end
end

function valid = getBranchValidityMask(branch)
valid = branch.validMask(:) & isfinite(branch.phaseVelocity_mps(:));
end

function txt = makeLegendLabel(sweepResult, idx)
spec = sweepResult.spec;
value = sweepResult.displayValues(idx);
if isfield(spec, 'units') && strlength(string(spec.units)) > 0
    txt = sprintf('%s = %.4g %s', char(string(spec.label)), value, char(string(spec.units)));
else
    txt = sprintf('%s = %.4g', char(string(spec.label)), value);
end
end
