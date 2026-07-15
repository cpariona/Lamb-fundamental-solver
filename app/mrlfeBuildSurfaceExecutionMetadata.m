function metadata = mrlfeBuildSurfaceExecutionMetadata(metadata, modelResults, varargin)
%MRLFEBUILDSURFACEEXECUTIONMETADATA Merge surface facts with public solver facts.

p = inputParser;
addParameter(p, 'SurfaceDefault', "Fast", @(x)ischar(x) || isstring(x));
addParameter(p, 'RoutePolicy', "mrlfeSolve", @(x)ischar(x) || isstring(x));
addParameter(p, 'OptimizerProfile', "", @(x)ischar(x) || isstring(x));
addParameter(p, 'GridPolicy', "", @(x)ischar(x) || isstring(x));
addParameter(p, 'EtaS', [], @(x)isempty(x) || (isnumeric(x) && isscalar(x)));
addParameter(p, 'A0Policy', "physicalTail", @(x)ischar(x) || isstring(x));
parse(p, varargin{:});

results = normalizeResults(modelResults);
presets = collectString(results, 'execution', 'effectivePreset');
requestedPresets = collectString(results, 'execution', 'requestedPreset');
engines = collectString(results, 'execution', 'internalEngine');
terminationPolicies = collectString(results, 'termination', 'policy');
fallbackPolicies = collectString(results, 'fallback', 'policy');
qualityReasons = collectString(results, 'quality', 'reason');

metadata.supportedExecutionProfiles = guiExecutionProfileValues();
metadata.profileSupportMode = "direct";
metadata.surfaceDefaultExecutionProfile = string(p.Results.SurfaceDefault);
metadata.routePolicy = string(p.Results.RoutePolicy);
metadata.actualRoute = string(p.Results.RoutePolicy);
metadata.optimizerProfile = string(p.Results.OptimizerProfile);
metadata.gridPolicy = string(p.Results.GridPolicy);
metadata.a0Policy = string(p.Results.A0Policy);
metadata.effectiveA0Policy = string(p.Results.A0Policy);
metadata.effectiveNumericalPresets = unique(presets, 'stable');
metadata.internalEngines = unique(engines, 'stable');
metadata.terminationPolicies = unique(terminationPolicies, 'stable');
metadata.fallbackPolicies = unique(fallbackPolicies, 'stable');
metadata.anyFallbackApplied = any(collectLogical(results, 'fallback', 'applied'));
metadata.fallback = metadata.anyFallbackApplied;
metadata.qualityAccepted = all(collectLogical(results, 'quality', 'accepted'));
metadata.qualityReason = strjoin(unique(qualityReasons, 'stable'), ", ");

if ~isempty(requestedPresets)
    metadata.requestedNumericalPreset = requestedPresets(1);
end
if ~isempty(presets)
    metadata.effectiveNumericalPreset = presets(1);
    metadata.internalAtlasPreset = presets(1);
end
if ~isempty(p.Results.EtaS)
    metadata.etaS = p.Results.EtaS;
end
if ~isfield(metadata, 'profileOverrideApplied')
    metadata.profileOverrideApplied = false;
end
if ~isfield(metadata, 'profileOverrideReason')
    metadata.profileOverrideReason = "";
end
end

function results = normalizeResults(modelResults)
if isempty(modelResults)
    results = cell(1, 0);
elseif iscell(modelResults)
    results = modelResults;
else
    results = {modelResults};
end
results = results(cellfun(@isstruct, results));
end

function values = collectString(results, parent, fieldName)
values = strings(1, 0);
for i = 1:numel(results)
    if isfield(results{i}, parent) && isstruct(results{i}.(parent)) && ...
            isfield(results{i}.(parent), fieldName)
        values(end+1) = string(results{i}.(parent).(fieldName)); %#ok<AGROW>
    end
end
end

function values = collectLogical(results, parent, fieldName)
values = false(1, numel(results));
for i = 1:numel(results)
    if isfield(results{i}, parent) && isstruct(results{i}.(parent)) && ...
            isfield(results{i}.(parent), fieldName)
        values(i) = logical(results{i}.(parent).(fieldName));
    end
end
end
