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
result = normalizeOfficialFields(result);

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
result.quality = aeEvaluateAtlasA0Quality( ...
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
result.model = "acoustoelastic_iop_hgo";
result.branch = "atlasA0";
if isfield(spec, 'configuration')
    result.configuration = spec.configuration;
end
if isfield(spec, 'execution')
    result.execution = spec.execution;
end
end

function result = normalizeOfficialFields(result)
if isfield(result, 'frequency')
    result.frequency_Hz = result.frequency;
    result = rmfield(result, 'frequency');
end
if isfield(result, 'Cp')
    result.phaseVelocity_mps = result.Cp;
    result = rmfield(result, 'Cp');
end
if isfield(result, 'validCp')
    result.validMask = logical(result.validCp);
    result = rmfield(result, 'validCp');
end
result.wavenumber_radpm = nan(size(result.phaseVelocity_mps));
valid = result.validMask & isfinite(result.frequency_Hz) & ...
    isfinite(result.phaseVelocity_mps) & result.phaseVelocity_mps > 0;
result.wavenumber_radpm(valid) = 2*pi*result.frequency_Hz(valid) ./ result.phaseVelocity_mps(valid);
end

function target = assignFields(target, fields)
names = fieldnames(fields);
for i = 1:numel(names)
    target.(names{i}) = fields.(names{i});
end
end

function diagnostics = buildDiagnosticSummary(result, diagnostics)
diagnostics.validCpPoints = nnz(result.validMask);
diagnostics.totalPoints = numel(result.phaseVelocity_mps);
diagnostics.explicitBranchPoints = nnz(result.branchExistsAtFrequency);
diagnostics.interpolatedPoints = nnz(result.interpolatedCp);
diagnostics.missingBranchPoints = nnz(~result.validMask);
diagnostics.selectedBranchID = result.selectedBranchID;
diagnostics.policyName = string(result.options.atlasBranchPolicy);
diagnostics.lastValidFrequency_kHz = result.quality.LastValidFrequency_kHz;
diagnostics.validFraction = result.quality.ValidFraction;
if any(result.validMask)
    diagnostics.minCp = min(result.phaseVelocity_mps(result.validMask));
    diagnostics.maxCp = max(result.phaseVelocity_mps(result.validMask));
    diagnostics.medianCp = median(result.phaseVelocity_mps(result.validMask), 'omitnan');
else
    diagnostics.minCp = nan;
    diagnostics.maxCp = nan;
    diagnostics.medianCp = nan;
end
end
