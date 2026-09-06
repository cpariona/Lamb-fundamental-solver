function [options, metadata] = rlResolveExecutionProfile(profileInput, varargin)
%RLRESOLVEEXECUTIONPROFILE Resolve app-level profile to RL solver options.

p = inputParser;
addParameter(p, 'DefaultProfile', "Balanced", @(x)ischar(x) || isstring(x));
addParameter(p, 'DefaultSource', "default", @(x)ischar(x) || isstring(x));
parse(p, varargin{:});

[profile, metadata] = guiNormalizeExecutionProfile(profileInput, ...
    'DefaultProfile', p.Results.DefaultProfile, ...
    'DefaultSource', p.Results.DefaultSource);

options = rlDefaultOptions(profile);
options.executionProfile = profile;
options.robustness = profile;

metadata.internalSolverPreset = profile;
metadata.internalAtlasPreset = "";
metadata.profileOverrideApplied = false;
metadata.profileOverrideReason = "";
metadata.routePolicy = "direct";
metadata.optimizerProfile = "";
metadata.gridPointsInitial = options.gridPointsInitial;
metadata.gridPointsTracking = options.gridPointsTracking;
metadata.jumpTol = options.jumpTol;
metadata.searchFactors = options.searchFactors;
metadata.supportedExecutionProfiles = guiExecutionProfileValues();
metadata.profileSupportMode = "fully_supported";
metadata.surfaceDefaultExecutionProfile = string(p.Results.DefaultProfile);
end
