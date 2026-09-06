function [options, metadata] = aeResolveExecutionProfile(profileInput, varargin)
%AERESOLVEEXECUTIONPROFILE Resolve app-level profile to AE atlas options.

p = inputParser;
addParameter(p, 'DefaultProfile', "Balanced", @(x)ischar(x) || isstring(x));
addParameter(p, 'DefaultSource', "default", @(x)ischar(x) || isstring(x));
addParameter(p, 'Surface', "physicalSweep", @(x)ischar(x) || isstring(x));
addParameter(p, 'Overrides', struct(), @(x)isstruct(x) && isscalar(x));
addParameter(p, 'OverrideReason', "", @(x)ischar(x) || isstring(x));
addParameter(p, 'ApplyNumericalPreset', true, @(x)islogical(x) && isscalar(x));
parse(p, varargin{:});

[profile, metadata] = guiNormalizeExecutionProfile(profileInput, ...
    'DefaultProfile', p.Results.DefaultProfile, ...
    'DefaultSource', p.Results.DefaultSource);

[numericalPreset, applyNumericalPreset] = selectedNumericalPreset( ...
    profile, p.Results.ApplyNumericalPreset);
surface = canonicalSurface(p.Results.Surface);
surfaceOverrides = buildSurfaceOverrides(surface, p.Results.Overrides);
[options, configurationMetadata] = aeResolveConfiguration(surfaceOverrides, ...
    'NumericalPreset', numericalPreset);
options.executionProfile = profile;
options.robustness = profile;

metadata.internalSolverPreset = "";
metadata.internalAtlasPreset = configurationMetadata.internalAtlasPreset;
metadata.profileOverrideApplied = configurationMetadata.profileOverrideApplied;
metadata.profileOverrideReason = "";
if metadata.profileOverrideApplied
    metadata.profileOverrideReason = string(p.Results.OverrideReason);
end
if applyNumericalPreset && strlength(configurationMetadata.effectiveNumericalPreset) > 0
    metadata.effectiveExecutionProfile = configurationMetadata.effectiveNumericalPreset;
end
metadata.routePolicy = configurationMetadata.routePolicy;
metadata.optimizerProfile = "";
metadata.atlasNumYPoints = configurationMetadata.atlasNumYPoints;
metadata.atlasTopNMinima = configurationMetadata.atlasTopNMinima;
metadata.supportedExecutionProfiles = guiExecutionProfileValues();
metadata.profileSupportMode = "fully_supported";
metadata.surfaceDefaultExecutionProfile = string(p.Results.DefaultProfile);
metadata.surface = surface;
if surface == "FitTool"
    metadata.atlasInitializationNumFrequencyPoints = options.atlasInitializationNumFrequencyPoints;
end
end

function overrides = buildSurfaceOverrides(surface, requestedOverrides)
overrides = struct();
if ismember(surface, ["MainGUI", "FitTool", "SweepTool", "physicalSweep"])
    overrides = struct( ...
        'M54_variant', "corrected", ...
        'normalizeRows', false, ...
        'atlasBranchPolicy', "atlasA0");
end
overrides = guiMergeStructs(overrides, requestedOverrides);
end

function surface = canonicalSurface(value)
switch lower(strtrim(string(value)))
    case {"", "direct", "model"}
        surface = "direct";
    case {"physicalsweep", "physical_sweep", "analysis"}
        surface = "physicalSweep";
    case {"sweeptool", "sweep"}
        surface = "SweepTool";
    case {"fittool", "fit", "fittool requested curve", "fittool synthetic"}
        surface = "FitTool";
    case {"maingui", "main_gui", "main"}
        surface = "MainGUI";
    otherwise
        error('aeResolveExecutionProfile:InvalidSurface', ...
            'Unknown AE application surface "%s".', string(value));
end
end

function [numericalPreset, applyNumericalPreset] = selectedNumericalPreset(profile, value)
applyNumericalPreset = logical(value);
if applyNumericalPreset
    numericalPreset = profile;
else
    numericalPreset = "";
end
end
