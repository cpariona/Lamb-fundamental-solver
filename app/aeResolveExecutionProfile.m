function [options, metadata] = aeResolveExecutionProfile(profileInput, varargin)
%AERESOLVEEXECUTIONPROFILE Resolve app-level profile to AE atlas options.

p = inputParser;
addParameter(p, 'DefaultProfile', "Balanced", @(x)ischar(x) || isstring(x));
addParameter(p, 'DefaultSource', "default", @(x)ischar(x) || isstring(x));
parse(p, varargin{:});

[profile, metadata] = guiNormalizeExecutionProfile(profileInput, ...
    'DefaultProfile', p.Results.DefaultProfile, ...
    'DefaultSource', p.Results.DefaultSource);

options = aeDefaultSweepOptions(profile);
options.executionProfile = profile;
options.robustness = profile;

metadata.internalSolverPreset = "";
metadata.internalAtlasPreset = "ae_atlas_" + string(options.atlasNumYPoints) + "x" + string(options.atlasTopNMinima);
metadata.profileOverrideApplied = false;
metadata.profileOverrideReason = "";
metadata.routePolicy = string(options.atlasBranchPolicy);
metadata.optimizerProfile = "";
metadata.atlasNumYPoints = options.atlasNumYPoints;
metadata.atlasTopNMinima = options.atlasTopNMinima;
metadata.supportedExecutionProfiles = ["Fast", "Balanced", "Robust"];
metadata.profileSupportMode = "fully_supported";
metadata.surfaceDefaultExecutionProfile = string(p.Results.DefaultProfile);
end
