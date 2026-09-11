function txt = guiBuildMainDiagnosticsText(guiResult, modelResult, requestedOptions, setupParams)
%GUIBUILDMAINDIAGNOSTICSTEXT Build Main GUI diagnostics from computed results.
%
% This presentation helper reports already-computed model/configuration evidence.
% It does not run a solver or make scientific decisions.

if nargin < 1 || isempty(guiResult), guiResult = struct(); end
if nargin < 2 || isempty(modelResult), modelResult = struct(); end
if nargin < 3 || isempty(requestedOptions), requestedOptions = struct(); end
if nargin < 4 || isempty(setupParams), setupParams = struct(); end

modelKey = resolveModelKey(modelResult, requestedOptions);
lines = strings(0, 1);
lines(end+1) = diagnosticTitle(modelKey);
lines(end+1) = "";
lines = appendGuiVisible(lines, guiResult);
lines = appendExecutionProfile(lines, guiResult, modelResult, requestedOptions, modelKey);

switch modelKey
    case "ae"
        lines = appendAeResult(lines, modelResult);
        lines = appendAePhysicalState(lines, modelResult);
    case "mrlfe"
        lines = appendMrlfeResults(lines, guiResult);
        lines = appendMrlfeRequest(lines, guiResult, requestedOptions, setupParams);
    otherwise
        lines = appendRlResult(lines, modelResult, requestedOptions, setupParams);
end

txt = strjoin(lines, newline);
end

function modelKey = resolveModelKey(modelResult, requestedOptions)
modelKey = "rl";
if isstruct(modelResult) && isfield(modelResult, 'model')
    switch string(modelResult.model)
        case "acoustoelastic_iop_hgo"
            modelKey = "ae";
        case "mrlfe"
            modelKey = "mrlfe";
        otherwise
            modelKey = "rl";
    end
elseif getField(requestedOptions, 'computeAcoustoelasticIOPHGO', false)
    modelKey = "ae";
elseif getField(requestedOptions, 'runMRLFE', false)
    modelKey = "mrlfe";
end
end

function title = diagnosticTitle(modelKey)
switch modelKey
    case "ae"
        title = "AE IOP/HGO diagnostics";
    case "mrlfe"
        title = "mRLFE diagnostics";
    otherwise
        title = "Rayleigh-Lamb diagnostics";
end
end

function lines = appendGuiVisible(lines, guiResult)
lines(end+1) = "GUI-visible branches:";
branches = getField(guiResult, 'branches', []);
if isempty(branches)
    lines(end+1) = "  none";
else
    for i = 1:numel(branches)
        branch = branches(i);
        n = numel(getField(branch, 'phaseVelocity', []));
        valid = branchValidCount(branch);
        lines(end+1) = sprintf("  %s %s | valid %d/%d", ...
            string(getField(branch, 'modelName', "")), ...
            string(getField(branch, 'branchName', "")), valid, n); %#ok<AGROW>
    end
end
elapsed = guiElapsedSeconds(guiResult);
if isfinite(elapsed)
    lines(end+1) = sprintf("model elapsed %.6g s", elapsed);
end
metadata = getField(guiResult, 'metadata', struct());
if isfield(metadata, 'seedBranchesHiddenFromPlotSurface')
    lines(end+1) = sprintf("seed branches hidden from plotting surface: %d", ...
        logical(metadata.seedBranchesHiddenFromPlotSurface));
end
lines(end+1) = "";
end

function lines = appendExecutionProfile(lines, guiResult, modelResult, requestedOptions, modelKey)
lines(end+1) = "GUI route / policy:";
metadata = getField(guiResult, 'metadata', struct());
if ~isfield(metadata, 'executionProfile') || ~isstruct(metadata.executionProfile)
    lines(end+1) = "  unavailable";
    lines(end+1) = "";
    return;
end

extra = strings(0, 1);
if isfield(metadata, 'status')
    extra(end+1) = "status: " + string(metadata.status);
end
if modelKey == "mrlfe"
    extra = appendExecutionSummary(extra, getField(metadata, 'execution', struct()));
    extra = appendPolicySummary(extra, "termination", getField(metadata, 'termination', struct()), "policy");
    extra = appendPolicySummary(extra, "fallback", getField(metadata, 'fallback', struct()), "policy");
    extra = appendQualitySummary(extra, getField(metadata, 'quality', struct()));
    a0Policy = getField(metadata.executionProfile, 'a0Policy', "");
    if strlength(string(a0Policy)) > 0
        extra(end+1) = "A0 policy: " + string(a0Policy);
    end
end

[visibleBranch, validCount, totalCount] = firstVisibleBranchSummary(guiResult);
formatted = guiFormatExecutionProfileDiagnostics(metadata.executionProfile, ...
    'Surface', "Main GUI", ...
    'Model', diagnosticModelName(modelKey), ...
    'ControlProfile', string(getField(requestedOptions, 'executionProfile', "")), ...
    'VisibleBranch', visibleBranch, ...
    'ValidCount', validCount, ...
    'TotalCount', totalCount, ...
    'ElapsedSeconds', guiElapsedSeconds(guiResult), ...
    'Fallback', mainFallbackText(metadata, modelResult, modelKey), ...
    'ExtraLines', extra);
lines = [lines; "  " + formatted(:)]; %#ok<AGROW>
lines(end+1) = "";
end

function name = diagnosticModelName(modelKey)
switch modelKey
    case "ae"
        name = "AE IOP/HGO";
    case "mrlfe"
        name = "mRLFE";
    otherwise
        name = "Rayleigh-Lamb";
end
end

function fallback = mainFallbackText(metadata, modelResult, modelKey)
fallback = "";
if modelKey == "ae" && isfield(modelResult, 'quality') && ...
        isfield(modelResult.quality, 'selectionFallbackUsed')
    fallback = string(logical(modelResult.quality.selectionFallbackUsed));
elseif isfield(metadata, 'executionProfile') && ...
        isfield(metadata.executionProfile, 'anyFallbackApplied')
    fallback = string(logical(metadata.executionProfile.anyFallbackApplied));
end
end

function lines = appendAeResult(lines, result)
lines(end+1) = "AE identity / requested grid:";
if ~isstruct(result) || ~isfield(result, 'frequency_Hz')
    lines(end+1) = "  unavailable";
    lines(end+1) = "";
    return;
end

frequency = result.frequency_Hz(:);
valid = logical(getField(result, 'validMask', false(size(frequency))));
tracking = getField(result, 'internalAtlasTracking', struct());
trackingFrequency = getField(tracking, 'TrackingFrequency_Hz', []);
initMin = getField(tracking, 'InitializationMinFrequency_Hz', nan);
initCount = getField(tracking, 'InitializationNumFrequencyPoints', nan);

lines(end+1) = sprintf("  requested points: %d", numel(frequency));
if ~isempty(frequency)
    lines(end+1) = sprintf("  requested range: %.6g to %.6g Hz", min(frequency), max(frequency));
end
lines(end+1) = sprintf("  internal identity tracking used: %d", logical(getField(tracking, 'Used', false)));
if ~isempty(trackingFrequency)
    lines(end+1) = sprintf("  tracking points: %d", numel(trackingFrequency));
    lines(end+1) = sprintf("  tracking range: %.6g to %.6g Hz", min(trackingFrequency), max(trackingFrequency));
end
if isfinite(initMin)
    lines(end+1) = sprintf("  initialization anchor: %.6g Hz", initMin);
end
if isfinite(initCount)
    lines(end+1) = sprintf("  initialization points: %d", round(initCount));
end

lines(end+1) = sprintf("  valid requested points: %d/%d", nnz(valid), numel(valid));
if isfinite(initMin)
    below = frequency < initMin;
    supported = ~below;
    lines(end+1) = sprintf("  requested below anchor: %d", nnz(below));
    lines(end+1) = sprintf("  missing at/above anchor: %d", nnz(~valid & supported));
end
quality = getField(result, 'quality', struct());
appendNumericQuality = ["firstValidFrequency_Hz", "lastValidFrequency_Hz", "firstMissingFrequency_Hz"];
for i = 1:numel(appendNumericQuality)
    name = appendNumericQuality(i);
    value = getField(quality, char(name), nan);
    if isfinite(value)
        lines(end+1) = "  " + qualityLabel(name) + sprintf(": %.6g Hz", value); %#ok<AGROW>
    end
end

selected = getField(result, 'selectedBranch', table());
if istable(selected) && height(selected) > 0
    row = selected(1,:);
    lines(end+1) = sprintf("  selected branch ID (diagnostic): %g", tableValue(row, 'BranchID', nan));
    lines(end+1) = sprintf("  selected branch start: %.6g Hz", tableValue(row, 'FrequencyStart_Hz', nan));
    lines(end+1) = sprintf("  selected branch end: %.6g Hz", tableValue(row, 'FrequencyEnd_Hz', nan));
    lines(end+1) = sprintf("  selected start y: %.6g", tableValue(row, 'YStart', nan));
    lines(end+1) = sprintf("  selected start rank: %.6g", tableValue(row, 'StartRank', nan));
end
if isfield(quality, 'a0StartFilterPassed')
    lines(end+1) = sprintf("  A0 start filter passed: %d", logical(quality.a0StartFilterPassed));
end
if isfield(quality, 'selectionFallbackUsed')
    lines(end+1) = sprintf("  selection fallback used: %d", logical(quality.selectionFallbackUsed));
end
if isfield(quality, 'accepted')
    lines(end+1) = sprintf("  quality accepted: %d", logical(quality.accepted));
end
if isfield(quality, 'reason')
    lines(end+1) = "  quality reason: " + string(quality.reason);
end
summary = getField(result, 'diagnostics', struct());
if isfield(summary, 'explicitBranchPoints')
    lines(end+1) = sprintf("  explicit branch points: %d", summary.explicitBranchPoints);
end
if isfield(summary, 'interpolatedPoints')
    lines(end+1) = sprintf("  interpolated points: %d", summary.interpolatedPoints);
end
lines(end+1) = "";
end

function label = qualityLabel(fieldName)
switch string(fieldName)
    case "firstValidFrequency_Hz"
        label = "first valid frequency";
    case "lastValidFrequency_Hz"
        label = "last valid frequency";
    otherwise
        label = "first missing frequency after valid start";
end
end

function lines = appendAePhysicalState(lines, result)
lines(end+1) = "AE constitutive / physical state:";
state = getField(result, 'constitutiveState', struct());
direct = getField(result, 'directParams', struct());
if isempty(fieldnames(state))
    lines(end+1) = "  unavailable";
    return;
end
lines(end+1) = sprintf("  IOP %.6g Pa (%.6g mmHg)", state.IOP, state.IOP / 133.322);
lines(end+1) = sprintf("  R %.6g m (%.6g mm)", state.R, state.R * 1e3);
lines(end+1) = sprintf("  thickness %.6g m (%.6g mm)", state.h, state.h * 1e3);
lines(end+1) = sprintf("  mu %.6g Pa (%.6g kPa)", state.mu, state.mu / 1e3);
lines(end+1) = sprintf("  k1 %.6g Pa (%.6g kPa)", state.k1, state.k1 / 1e3);
lines(end+1) = sprintf("  k2 %.6g", state.k2);
lines(end+1) = sprintf("  prestress sigma %.6g Pa (%.6g kPa)", state.sigma, state.sigma / 1e3);
lines(end+1) = sprintf("  stretch lambda %.9g", state.lambda);
if isfield(direct, 'alpha')
    lines(end+1) = sprintf("  alpha %.6g Pa (%.6g kPa)", direct.alpha, direct.alpha / 1e3);
end
if isfield(direct, 'beta')
    lines(end+1) = sprintf("  beta %.6g Pa (%.6g kPa)", direct.beta, direct.beta / 1e3);
end
if isfield(direct, 'gamma')
    lines(end+1) = sprintf("  gamma %.6g Pa (%.6g kPa)", direct.gamma, direct.gamma / 1e3);
end
if isfield(direct, 'rho')
    lines(end+1) = sprintf("  rho %.6g kg/m^3", direct.rho);
end
if isfield(direct, 'rhoF')
    lines(end+1) = sprintf("  fluid rho %.6g kg/m^3", direct.rhoF);
end
if isfield(direct, 'fluidBulkModulus')
    lines(end+1) = sprintf("  fluid bulk modulus %.6g Pa (%.6g GPa)", ...
        direct.fluidBulkModulus, direct.fluidBulkModulus / 1e9);
end
end

function lines = appendMrlfeResults(lines, guiResult)
lines(end+1) = "mRLFE model results:";
metadata = getField(guiResult, 'metadata', struct());
results = getField(metadata, 'modelResults', struct());
if isempty(fieldnames(results))
    result = getField(metadata, 'modelResult', struct());
    if isempty(fieldnames(result))
        lines(end+1) = "  unavailable";
        lines(end+1) = "";
        return;
    end
    results = struct(char(string(getField(result, 'branch', "branch"))), result);
end
names = fieldnames(results);
for i = 1:numel(names)
    result = results.(names{i});
    branch = string(getField(result, 'branch', names{i}));
    valid = logical(getField(result, 'validMask', []));
    lines(end+1) = sprintf("  %s valid %d/%d", branch, nnz(valid), numel(valid)); %#ok<AGROW>
    execution = getField(result, 'execution', struct());
    if isfield(execution, 'internalEngine')
        lines(end+1) = "    engine: " + string(execution.internalEngine); %#ok<AGROW>
    end
    if isfield(execution, 'effectivePreset')
        lines(end+1) = "    numerical preset: " + string(execution.effectivePreset); %#ok<AGROW>
    end
    termination = getField(result, 'termination', struct());
    if isfield(termination, 'policy')
        lines(end+1) = "    termination: " + string(termination.policy); %#ok<AGROW>
    end
    if isfield(termination, 'applied')
        lines(end+1) = "    termination applied: " + string(logical(termination.applied)); %#ok<AGROW>
    end
    if isfield(termination, 'reason') && string(termination.reason) ~= "none"
        lines(end+1) = "    termination reason: " + string(termination.reason); %#ok<AGROW>
    end
    if isfield(termination, 'firstRejectedFrequency_Hz') && isfinite(termination.firstRejectedFrequency_Hz)
        lines(end+1) = sprintf("    first rejected frequency: %.6g Hz", termination.firstRejectedFrequency_Hz); %#ok<AGROW>
    end
    fallback = getField(result, 'fallback', struct());
    if isfield(fallback, 'policy')
        lines(end+1) = "    fallback: " + string(fallback.policy); %#ok<AGROW>
    end
    if isfield(fallback, 'applied')
        lines(end+1) = "    fallback applied: " + string(logical(fallback.applied)); %#ok<AGROW>
    end
    quality = getField(result, 'quality', struct());
    if isfield(quality, 'accepted')
        lines(end+1) = "    quality accepted: " + string(logical(quality.accepted)); %#ok<AGROW>
    end
    if isfield(quality, 'reason')
        lines(end+1) = "    quality reason: " + string(quality.reason); %#ok<AGROW>
    end
end
lines(end+1) = "";
end

function lines = appendMrlfeRequest(lines, guiResult, requestedOptions, setupParams)
lines(end+1) = "mRLFE physical / requested configuration:";
lines = appendBaseMaterial(lines, setupParams, false);
metadata = getField(guiResult, 'metadata', struct());
options = getField(metadata, 'options', requestedOptions);
params = getField(options, 'mrlfeParams', getField(requestedOptions, 'mrlfeParams', struct()));
if isfield(params, 'fluidDensity')
    lines(end+1) = sprintf("  fluid density %.6g kg/m^3", params.fluidDensity);
end
if isfield(params, 'fluidSoundSpeed')
    lines(end+1) = sprintf("  fluid sound speed %.6g m/s", params.fluidSoundSpeed);
end
if isfield(params, 'etaS')
    lines(end+1) = sprintf("  etaS %.6g Pa*s", params.etaS);
end
branches = getField(options, 'branchNames', getField(requestedOptions, 'branchNames', strings(0,1)));
if ~isempty(branches)
    lines(end+1) = "  requested branches: " + strjoin(string(branches), ", ");
end
lines(end+1) = "  A0Like termination policy: physicalTail";
lines(end+1) = "  S0Like termination policy: none";
if isfield(params, 'solveComplexK')
    lines(end+1) = "  solveComplexK: " + string(logical(params.solveComplexK));
end
if isfield(params, 'etaL')
    lines(end+1) = "  etaL: " + string(params.etaL);
end
if isfield(params, 'useComplexLambda')
    lines(end+1) = "  useComplexLambda: " + string(logical(params.useComplexLambda));
end
end

function lines = appendRlResult(lines, result, requestedOptions, setupParams)
lines(end+1) = "Rayleigh-Lamb request / material:";
lines(end+1) = sprintf("  requested A0: %d", logical(getField(requestedOptions, 'computeA0', false)));
lines(end+1) = sprintf("  requested S0: %d", logical(getField(requestedOptions, 'computeS0', false)));
lines = appendBaseMaterial(lines, setupParams, true);
if isfield(result, 'modes') && isstruct(result.modes)
    names = fieldnames(result.modes);
    for i = 1:numel(names)
        mode = result.modes.(names{i});
        f = getField(mode, 'frequency_Hz', []);
        valid = logical(getField(mode, 'validMask', false(size(f))));
        if isempty(f)
            continue;
        end
        lines(end+1) = sprintf("  %s: %d/%d valid, %.6g to %.6g Hz", ...
            names{i}, nnz(valid), numel(valid), min(f), max(f)); %#ok<AGROW>
    end
end
end

function lines = appendBaseMaterial(lines, params, includeDerived)
if isempty(fieldnames(params))
    lines(end+1) = "  material unavailable";
    return;
end
if isfield(params, 'modelType')
    lines(end+1) = "  modelType " + string(params.modelType);
end
appendNumeric = {'rho','mu','thickness'};
appendUnits = {" kg/m^3"," Pa"," m"};
appendLabels = {"rho","mu","full thickness"};
for i = 1:numel(appendNumeric)
    if isfield(params, appendNumeric{i})
        lines(end+1) = "  " + appendLabels{i} + " " + string(params.(appendNumeric{i})) + appendUnits{i}; %#ok<AGROW>
    end
end
if isfield(params, 'nu')
    lines(end+1) = "  nu " + string(params.nu);
end
if ~includeDerived
    return;
end
fields = {'E','lambda','K','CL','CT'};
labels = {"E","lambda_Lame","K","CL","CT"};
units = {" Pa"," Pa"," Pa"," m/s"," m/s"};
for i = 1:numel(fields)
    if isfield(params, fields{i})
        lines(end+1) = "  " + labels{i} + " " + string(params.(fields{i})) + units{i}; %#ok<AGROW>
    end
end
end

function [visibleBranch, validCount, totalCount] = firstVisibleBranchSummary(guiResult)
visibleBranch = "";
validCount = nan;
totalCount = nan;
branches = getField(guiResult, 'branches', []);
if isempty(branches)
    return;
end
branch = branches(1);
visibleBranch = string(getField(branch, 'modelName', "")) + " " + string(getField(branch, 'branchName', ""));
totalCount = numel(getField(branch, 'phaseVelocity', []));
validCount = branchValidCount(branch);
end

function nValid = branchValidCount(branch)
values = getField(branch, 'phaseVelocity', []);
valid = isfinite(values(:));
diagnostics = getField(branch, 'diagnostics', struct());
if isfield(diagnostics, 'valid') && ~isempty(diagnostics.valid)
    valid = valid & logical(diagnostics.valid(:));
end
nValid = nnz(valid);
end

function elapsed = guiElapsedSeconds(guiResult)
elapsed = nan;
metadata = getField(guiResult, 'metadata', struct());
if isfield(metadata, 'elapsedSeconds')
    elapsed = metadata.elapsedSeconds;
    return;
end
diagnostics = getField(guiResult, 'diagnostics', struct());
if isfield(diagnostics, 'elapsedSeconds')
    elapsed = diagnostics.elapsedSeconds;
end
end

function linesOut = appendExecutionSummary(linesIn, execution)
linesOut = linesIn;
names = fieldnames(execution);
for i = 1:numel(names)
    value = execution.(names{i});
    if isstruct(value) && isfield(value, 'internalEngine')
        linesOut(end+1) = string(names{i}) + " engine: " + string(value.internalEngine); %#ok<AGROW>
    end
    if isstruct(value) && isfield(value, 'effectivePreset')
        linesOut(end+1) = string(names{i}) + " numerical preset: " + string(value.effectivePreset); %#ok<AGROW>
    end
end
end

function linesOut = appendPolicySummary(linesIn, label, policies, fieldName)
linesOut = linesIn;
names = fieldnames(policies);
for i = 1:numel(names)
    value = policies.(names{i});
    if isstruct(value) && isfield(value, fieldName)
        linesOut(end+1) = string(names{i}) + " " + label + ": " + string(value.(fieldName)); %#ok<AGROW>
    end
    if label == "fallback" && isstruct(value) && isfield(value, 'applied')
        linesOut(end+1) = string(names{i}) + " fallback applied: " + string(logical(value.applied)); %#ok<AGROW>
    end
end
end

function linesOut = appendQualitySummary(linesIn, quality)
linesOut = linesIn;
names = fieldnames(quality);
for i = 1:numel(names)
    value = quality.(names{i});
    if isstruct(value) && isfield(value, 'accepted')
        linesOut(end+1) = string(names{i}) + " quality accepted: " + string(logical(value.accepted)); %#ok<AGROW>
    end
    if isstruct(value) && isfield(value, 'reason')
        linesOut(end+1) = string(names{i}) + " quality reason: " + string(value.reason); %#ok<AGROW>
    end
end
end

function value = tableValue(row, name, defaultValue)
if istable(row) && ismember(name, row.Properties.VariableNames)
    value = row.(name)(1);
else
    value = defaultValue;
end
end

function value = getField(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
