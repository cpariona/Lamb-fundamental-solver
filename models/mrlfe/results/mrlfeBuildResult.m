function result = mrlfeBuildResult(configuration, solverResult, elapsedSeconds)
%MRLFEBUILDRESULT Normalize internal mRLFE output to the public result schema.

frequency_Hz = configuration.request.frequency_Hz(:);
phaseVelocity_mps = solverResult.Cp_mps(:);
validMask = logical(solverResult.validMask(:)) & isfinite(phaseVelocity_mps) & phaseVelocity_mps > 0;
phaseVelocity_mps(~validMask) = nan;

wavenumber_radpm = nan(size(phaseVelocity_mps));
wavenumber_radpm(validMask) = 2*pi*frequency_Hz(validMask) ./ phaseVelocity_mps(validMask);

quality = mrlfeEvaluateBranchQuality(frequency_Hz, phaseVelocity_mps, validMask, configuration.qualityOptions);

result = struct();
result.model = "mrlfe";
result.branch = configuration.branch;
result.frequency_Hz = frequency_Hz;
result.phaseVelocity_mps = phaseVelocity_mps;
result.wavenumber_radpm = wavenumber_radpm;
result.validMask = validMask;
result.quality = quality;
result.termination = buildTermination(configuration, solverResult);
result.fallback = struct( ...
    'policy', configuration.fallbackPolicy, ...
    'applied', false, ...
    'reason', "none", ...
    'engine', "");
result.execution = struct( ...
    'requestedPreset', configuration.requestedPreset, ...
    'effectivePreset', configuration.effectivePreset, ...
    'internalEngine', configuration.internalEngine, ...
    'elapsedSeconds', elapsedSeconds);
result.configuration = configuration.public;
result.diagnostics = buildDiagnosticSummary(configuration, solverResult);
result.debug = struct('solverResult', solverResult);
end

function summary = buildDiagnosticSummary(configuration, rawResult)
summary = struct( ...
    'branch', configuration.branch, ...
    'internalEngine', configuration.internalEngine, ...
    'requestedPointCount', numel(configuration.request.frequency_Hz), ...
    'solvePointCount', numel(rawResult.frequencySolve_Hz), ...
    'requestedPreset', configuration.requestedPreset, ...
    'effectivePreset', configuration.effectivePreset);
end

function termination = buildTermination(configuration, rawResult)
termination = struct();
termination.applied = false;
termination.policy = configuration.terminationPolicy;
termination.reason = "none";
termination.firstRejectedIndex = NaN;
termination.firstRejectedFrequency_Hz = NaN;

if ~isfield(rawResult, 'branch') || ~isstruct(rawResult.branch)
    return;
end
branch = rawResult.branch;
if isfield(branch, 'physicalCorridor')
    cut = branch.physicalCorridor;
    termination = applyCut(termination, cut, 'FirstCutIndex', 'FirstCutFrequency', 'CutReason');
elseif isfield(branch, 'adaptiveCut')
    cut = branch.adaptiveCut;
    termination = applyCut(termination, cut, 'FirstCutIndex', 'FirstCutFrequency', 'CutReason');
elseif isfield(branch, 'delayedViscoModalCut')
    cut = branch.delayedViscoModalCut;
    termination = applyCut(termination, cut, 'FirstCutIndex', 'FirstCutFrequency', 'CutReason');
elseif isfield(branch, 'firstMissingModalMinimumIndex') && isfinite(branch.firstMissingModalMinimumIndex)
    termination.applied = true;
    termination.reason = getStringField(branch, 'modalCutReason', "missing_modal_minimum");
    termination.firstRejectedIndex = branch.firstMissingModalMinimumIndex;
    termination.firstRejectedFrequency_Hz = getNumericField(branch, 'firstMissingModalMinimumFrequency', NaN);
end
end

function termination = applyCut(termination, cut, indexField, frequencyField, reasonField)
idx = getNumericField(cut, indexField, NaN);
freq = getNumericField(cut, frequencyField, NaN);
if isfinite(idx) || isfinite(freq)
    termination.applied = true;
    termination.firstRejectedIndex = idx;
    termination.firstRejectedFrequency_Hz = freq;
    termination.reason = getStringField(cut, reasonField, "cut_applied");
end
end

function value = getNumericField(s, fieldName, defaultValue)
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = s.(fieldName);
else
    value = defaultValue;
end
end

function value = getStringField(s, fieldName, defaultValue)
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = string(s.(fieldName));
else
    value = defaultValue;
end
end
