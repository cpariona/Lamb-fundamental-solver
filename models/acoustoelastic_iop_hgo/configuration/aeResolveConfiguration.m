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
addParameter(p, 'Surface', "direct", @(x)ischar(x) || isstring(x));
parse(p, varargin{:});

options = defaultAcoustoelasticIOPHGOOptions();
options = applyFields(options, atlasDefaults());

requestedPreset = "";
if strlength(string(p.Results.NumericalPreset)) > 0
    [presetValues, requestedPreset] = aeGetNumericalPreset(p.Results.NumericalPreset);
    options = applyFields(options, presetValues);
end

surface = canonicalSurface(p.Results.Surface);
options = applySurface(options, surface, overrides);
options = applyFields(options, overrides, true);
options.atlasBranchPolicy = aeNormalizeBranchPolicy(options.atlasBranchPolicy);

effectivePreset = inferAtlasPreset(options);
metadata = struct();
metadata.surface = surface;
metadata.requestedNumericalPreset = requestedPreset;
metadata.effectiveNumericalPreset = effectivePreset;
metadata.profileOverrideApplied = strlength(requestedPreset) > 0 && ...
    (strlength(effectivePreset) == 0 || effectivePreset ~= requestedPreset);
metadata.internalAtlasPreset = "ae_atlas_" + string(options.atlasNumYPoints) + ...
    "x" + string(options.atlasTopNMinima);
metadata.atlasNumYPoints = options.atlasNumYPoints;
metadata.atlasTopNMinima = options.atlasTopNMinima;
metadata.routePolicy = string(options.atlasBranchPolicy);
metadata.aeGuiInteractivePreset = getField(options, 'aeGuiAtlasPreset', "none");
end

function options = applySurface(options, surface, overrides)
switch surface
    case "direct"
        return;
    case {"physicalSweep", "SweepTool", "FitTool"}
        options = applyFields(options, maintainedWorkflowBundle());
    case "MainGUI"
        options = applyFields(options, maintainedWorkflowBundle());
        useBundle = logical(getField(overrides, 'aeUseGuiFastAtlasPreset', true));
        if useBundle
            options = applyFields(options, aeGetNumericalPreset("MainGUI"));
        else
            options.aeGuiAtlasPreset = "off";
        end
end
end

function surface = canonicalSurface(value)
key = lower(strtrim(string(value)));
if numel(key) ~= 1
    error('aeResolveConfiguration:InvalidSurface', ...
        'AE configuration surface must be scalar.');
end
switch key
    case {"", "direct", "model"}
        surface = "direct";
    case {"physicalsweep", "physical_sweep", "analysis"}
        surface = "physicalSweep";
    case {"sweeptool", "sweep"}
        surface = "SweepTool";
    case {"fittool", "fit"}
        surface = "FitTool";
    case {"maingui", "main_gui"}
        surface = "MainGUI";
    otherwise
        error('aeResolveConfiguration:InvalidSurface', ...
            'Unknown AE configuration surface "%s".', string(value));
end
end

function values = maintainedWorkflowBundle()
values = struct( ...
    'M54_variant', "corrected", ...
    'normalizeRows', false, ...
    'usePhysicalCpWindow', false, ...
    'atlasBranchPolicy', "atlasA0");
end

function values = atlasDefaults()
values = struct( ...
    'atlasYMin', 0.003, ...
    'atlasYMax', 2.0, ...
    'atlasNumYPoints', 1000, ...
    'atlasTopNMinima', 18, ...
    'atlasMaxLogYJump', 0.075, ...
    'atlasMinBranchPoints', 12, ...
    'atlasCoverageWeight', 1.40, ...
    'atlasRoughnessWeight', 1.20, ...
    'atlasRankWeight', 0.70, ...
    'atlasLowYWeight', 0.35, ...
    'atlasIncreaseWeight', 0.50, ...
    'atlasDropWeight', 1.25, ...
    'atlasStartYWeight', 1.10, ...
    'atlasStartRankWeight', 0.55, ...
    'atlasStartCpWeight', 0.65, ...
    'atlasPreferPositiveSlope', true, ...
    'atlasSplitOnLargeCpJump', true, ...
    'atlasMaxRelativeCpJump', 0.05, ...
    'atlasRequireLowStartY', true, ...
    'atlasMaxStartY', 0.50, ...
    'atlasRequireStartRank', true, ...
    'atlasMaxStartRank', 3, ...
    'atlasFallbackToUnfilteredSelection', true, ...
    'atlasAllowInterpolationAcrossGaps', false, ...
    'atlasMaxInterpolationFrequencyRatio', 1.12);
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

function value = getField(s, name, defaultValue)
if isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
