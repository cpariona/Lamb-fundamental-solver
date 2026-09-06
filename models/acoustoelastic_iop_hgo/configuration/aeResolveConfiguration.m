function [options, metadata] = aeResolveConfiguration(overrides, varargin)
%AERESOLVECONFIGURATION Build the complete effective AE solver options.

if nargin < 1 || isempty(overrides)
    overrides = struct();
end
if ~isstruct(overrides) || ~isscalar(overrides)
    error('aeResolveConfiguration:InvalidOverrides', ...
        'AE configuration overrides must be a scalar struct.');
end

p = inputParser;
addParameter(p, 'NumericalPreset', "", @(x)ischar(x) || isstring(x));
parse(p, varargin{:});

options = defaultAcoustoelasticIOPHGOOptions();

requestedPreset = "";
if strlength(string(p.Results.NumericalPreset)) > 0
    [presetValues, requestedPreset] = aeGetNumericalPreset(p.Results.NumericalPreset);
    options = applyFields(options, presetValues);
end

options = applyFields(options, overrides, true);
options.atlasBranchPolicy = aeNormalizeBranchPolicy(options.atlasBranchPolicy);

effectivePreset = inferAtlasPreset(options);
metadata = struct();
metadata.requestedNumericalPreset = requestedPreset;
metadata.effectiveNumericalPreset = effectivePreset;
metadata.profileOverrideApplied = strlength(requestedPreset) > 0 && ...
    (strlength(effectivePreset) == 0 || effectivePreset ~= requestedPreset);
metadata.internalAtlasPreset = "ae_atlas_" + string(options.atlasNumYPoints) + ...
    "x" + string(options.atlasTopNMinima);
metadata.atlasNumYPoints = options.atlasNumYPoints;
metadata.atlasTopNMinima = options.atlasTopNMinima;
metadata.routePolicy = string(options.atlasBranchPolicy);
end

function name = inferAtlasPreset(options)
name = "";
profiles = ["Fast", "Balanced", "Robust"];
for i = 1:numel(profiles)
    preset = aeGetNumericalPreset(profiles(i));
    if options.atlasNumYPoints == preset.atlasNumYPoints && ...
            options.atlasTopNMinima == preset.atlasTopNMinima
        name = profiles(i);
        return;
    end
end
end
function target = applyFields(target, source, skipEmpty)
if nargin < 3
    skipEmpty = false;
end
names = fieldnames(source);
for i = 1:numel(names)
    if skipEmpty && isempty(source.(names{i}))
        continue;
    end
    target.(names{i}) = source.(names{i});
end
end
