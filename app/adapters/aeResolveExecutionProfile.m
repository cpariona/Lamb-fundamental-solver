function [options, metadata] = aeResolveExecutionProfile(profileInput, varargin)
%AERESOLVEEXECUTIONPROFILE Resolve app-level profile to AE atlas options.

p = inputParser;
addParameter(p, 'DefaultProfile', "Balanced", @(x)ischar(x) || isstring(x));
addParameter(p, 'DefaultSource', "default", @(x)ischar(x) || isstring(x));
addParameter(p, 'Surface', "physicalSweep", @(x)ischar(x) || isstring(x));
addParameter(p, 'Overrides', struct(), @(x)isstruct(x) && isscalar(x));
addParameter(p, 'OverrideReason', "", @(x)ischar(x) || isstring(x));
parse(p, varargin{:});

[profile, metadata] = guiNormalizeExecutionProfile(profileInput, ...
    'DefaultProfile', p.Results.DefaultProfile, ...
    'DefaultSource', p.Results.DefaultSource);

[options, configurationMetadata] = aeResolveConfiguration(p.Results.Overrides, ...
    'NumericalPreset', profile, ...
    'Surface', p.Results.Surface);
options.executionProfile = profile;
options.robustness = profile;

metadata.internalSolverPreset = "";
metadata.internalAtlasPreset = configurationMetadata.internalAtlasPreset;
metadata.profileOverrideApplied = configurationMetadata.profileOverrideApplied;
metadata.profileOverrideReason = "";
if metadata.profileOverrideApplied
    metadata.profileOverrideReason = string(p.Results.OverrideReason);
end
if strlength(configurationMetadata.effectiveNumericalPreset) > 0
    metadata.effectiveExecutionProfile = configurationMetadata.effectiveNumericalPreset;
end
metadata.routePolicy = configurationMetadata.routePolicy;
metadata.optimizerProfile = "";
metadata.atlasNumYPoints = configurationMetadata.atlasNumYPoints;
metadata.atlasTopNMinima = configurationMetadata.atlasTopNMinima;
metadata.supportedExecutionProfiles = guiExecutionProfileValues();
metadata.profileSupportMode = "fully_supported";
metadata.surfaceDefaultExecutionProfile = string(p.Results.DefaultProfile);
if strcmpi(string(p.Results.Surface), "FitTool") || strcmpi(string(p.Results.Surface), "fit")
    metadata.atlasInitializationNumFrequencyPoints = options.atlasInitializationNumFrequencyPoints;
end
end
