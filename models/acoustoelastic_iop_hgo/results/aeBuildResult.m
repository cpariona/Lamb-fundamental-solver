function result = aeBuildResult(spec)
%AEBUILDRESULT Construct the maintained AE result without numerical decisions.
%
% spec.baseResult may contain an already-built tracking-grid result.
% spec.fields are assigned before quality/diagnostic summaries.
% spec.postSummaryFields are assigned after those summaries to preserve the
% established field order for diagnostic extensions and wrapper metadata.

if isfield(spec, 'baseResult') && ~isempty(spec.baseResult)
    result = spec.baseResult;
else
    result = struct();
end

if isfield(spec, 'fields')
    result = assignFields(result, spec.fields);
end

qualityBase = struct();
if isfield(spec, 'qualityBase')
    qualityBase = spec.qualityBase;
end
qualityNote = "";
if isfield(spec, 'qualityNote')
    qualityNote = spec.qualityNote;
end
firstMissingAtStartWhenInvalid = false;
if isfield(spec, 'qualityFirstMissingAtStartWhenInvalid')
    firstMissingAtStartWhenInvalid = spec.qualityFirstMissingAtStartWhenInvalid;
end
result.reliability = aeEvaluateAtlasA0Quality( ...
    result, qualityBase, qualityNote, firstMissingAtStartWhenInvalid);

diagnosticBase = struct();
if isfield(spec, 'diagnosticBase')
    diagnosticBase = spec.diagnosticBase;
end
result.diagnostics = buildDiagnosticSummary(result, diagnosticBase);
if isfield(spec, 'diagnosticFields')
    result.diagnostics = assignFields(result.diagnostics, spec.diagnosticFields);
end

if isfield(spec, 'postSummaryFields')
    result = assignFields(result, spec.postSummaryFields);
end
end

function target = assignFields(target, fields)
names = fieldnames(fields);
for i = 1:numel(names)
    target.(names{i}) = fields.(names{i});
end
end

function diagnostics = buildDiagnosticSummary(result, diagnostics)
diagnostics.validCpPoints = nnz(result.validCp);
diagnostics.totalPoints = numel(result.Cp);
diagnostics.explicitBranchPoints = nnz(result.branchExistsAtFrequency);
diagnostics.interpolatedPoints = nnz(result.interpolatedCp);
diagnostics.missingBranchPoints = nnz(~result.validCp);
diagnostics.selectedBranchID = result.selectedBranchID;
diagnostics.policyName = string(result.options.atlasBranchPolicy);
diagnostics.lastValidFrequency_kHz = result.reliability.LastValidFrequency_kHz;
diagnostics.validFraction = result.reliability.ValidFraction;
if any(result.validCp)
    diagnostics.minCp = min(result.Cp(result.validCp));
    diagnostics.maxCp = max(result.Cp(result.validCp));
    diagnostics.medianCp = median(result.Cp(result.validCp), 'omitnan');
else
    diagnostics.minCp = nan;
    diagnostics.maxCp = nan;
    diagnostics.medianCp = nan;
end
end
