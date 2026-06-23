function normalized = guiNormalizeMRLFESweep(rawResults, summaryTable, request, modelName, branchName)
%GUINORMALIZEMRLFESWEEP Normalize mRLFE sweep output for GUI plotting/export.
%
% Plotting code should consume this normalized structure instead of reading
% model-specific raw solver fields directly.

n = numel(rawResults.results);
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
    branch = extractMRLFESweepBranch(rawResults.results{i}, modelName, branchName);
    curves(i).label = makeMRLFELegendLabel(rawResults, i);
    curves(i).sweepValue = rawResults.values(i);
    curves(i).sweepValueDisplay = rawResults.displayValues(i);
    curves(i).rawBranch = branch;

    if isempty(branch)
        continue;
    end

    valid = getMRLFEBranchValidityMask(branch);
    frequency = branch.frequency(:);
    cp = branch.Cp(:);
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
normalized.sweepLabel = string(rawResults.spec.label);
normalized.sweepUnit = string(rawResults.spec.units);
normalized.displayScale = rawResults.spec.displayScale;
normalized.curves = curves;
normalized.summaryTable = summaryTable;
normalized.metadata = struct();
normalized.metadata.request = request;
end

function branch = extractMRLFESweepBranch(result, modelName, branchName)
branch = [];
modelName = string(modelName);
branchName = string(branchName);
modelCandidates = modelCandidateNames(modelName);

if ~isfield(result, 'models')
    return;
end

for i = 1:numel(modelCandidates)
    candidate = char(modelCandidates(i));
    if isfield(result.models, candidate) && isfield(result.models.(candidate), 'branches') && ...
            isfield(result.models.(candidate).branches, char(branchName))
        branch = result.models.(candidate).branches.(char(branchName));
        return;
    end
end
end

function names = modelCandidateNames(modelName)
switch string(modelName)
    case "mRLFEViscoRealK"
        names = ["mRLFEViscoRealK", "mRLFEHanViscoRealK"];
    case "mRLFEElasticRealK"
        names = ["mRLFEElasticRealK", "mRLFERealK"];
    otherwise
        names = string(modelName);
end
end

function valid = getMRLFEBranchValidityMask(branch)
if isfield(branch, 'validCp')
    valid = branch.validCp(:) & isfinite(branch.Cp(:));
elseif isfield(branch, 'valid')
    valid = branch.valid(:) & isfinite(branch.Cp(:));
else
    valid = isfinite(branch.Cp(:));
end
end

function txt = makeMRLFELegendLabel(rawResults, idx)
spec = rawResults.spec;
value = rawResults.displayValues(idx);
if isfield(spec, 'units') && strlength(string(spec.units)) > 0
    txt = sprintf('%s = %.4g %s', string(spec.label), value, string(spec.units));
else
    txt = sprintf('%s = %.4g', string(spec.label), value);
end
end
