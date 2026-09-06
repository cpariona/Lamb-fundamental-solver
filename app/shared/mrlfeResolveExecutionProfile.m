function [options, metadata] = mrlfeResolveExecutionProfile(branchName, profileInput, varargin)
%MRLFERESOLVEEXECUTIONPROFILE Resolve app-level profile for mRLFE workflows.
%
% Maintained app surfaces apply the requested Fast/Balanced/Robust profile
% directly to the public mRLFE numerical preset with the same normalized name.

p = inputParser;
addRequired(p, 'branchName', @(x)ischar(x) || isstring(x));
addRequired(p, 'profileInput');
addParameter(p, 'Surface', "gui", @(x)ischar(x) || isstring(x));
addParameter(p, 'DefaultProfile', "Fast", @(x)ischar(x) || isstring(x));
addParameter(p, 'DefaultSource', "default", @(x)ischar(x) || isstring(x));
addParameter(p, 'EtaS', 0.05, @(x)isnumeric(x) && isscalar(x) && isfinite(x));
addParameter(p, 'A0Policy', "physicalTail", @(x)ischar(x) || isstring(x));
parse(p, branchName, profileInput, varargin{:});

branchName = string(p.Results.branchName);
surface = lower(string(p.Results.Surface));
[requestedProfile, metadata] = guiNormalizeExecutionProfile(profileInput, ...
    'DefaultProfile', p.Results.DefaultProfile, ...
    'DefaultSource', p.Results.DefaultSource);
effectiveProfile = requestedProfile;
numericalPreset = profileToNumericalPreset(requestedProfile);

switch surface
    case {"gui", "main", "sweep", "api"}
        options = mrlfeDefaultSweepOptions(branchName, ...
            'EtaS', p.Results.EtaS, ...
            'A0Policy', normalizeA0Policy(p.Results.A0Policy));
    case "fit"
        options = mrlfeDefaultSweepOptions(branchName, ...
            'EtaS', p.Results.EtaS, ...
            'A0Policy', normalizeA0Policy(p.Results.A0Policy));
    otherwise
        error('mrlfeResolveExecutionProfile:UnsupportedSurface', ...
            'Unsupported mRLFE profile surface: %s.', surface);
end

options.executionProfile = requestedProfile;
options.effectiveExecutionProfile = effectiveProfile;
options.robustness = requestedProfile;
options.mrlfeNumericalPreset = numericalPreset;

metadata.requestedExecutionProfile = requestedProfile;
metadata.effectiveExecutionProfile = effectiveProfile;
metadata.requestedNumericalPreset = numericalPreset;
metadata.effectiveNumericalPreset = numericalPreset;
metadata.internalSolverPreset = effectiveProfile;
metadata.internalAtlasPreset = numericalPreset;
metadata.profileOverrideApplied = false;
metadata.profileOverrideReason = "";
metadata.routePolicy = normalizeA0Policy(p.Results.A0Policy);
metadata.optimizerProfile = "";
metadata.surface = surface;
metadata.branchName = branchName;
metadata.etaS = p.Results.EtaS;
metadata.supportedExecutionProfiles = guiExecutionProfileValues();
metadata.profileSupportMode = "direct";
metadata.surfaceDefaultExecutionProfile = string(p.Results.DefaultProfile);
end

function preset = profileToNumericalPreset(profile)
switch string(profile)
    case "Fast"
        preset = "fast";
    case "Balanced"
        preset = "balanced";
    case "Robust"
        preset = "robust";
    otherwise
        error('mrlfeResolveExecutionProfile:UnsupportedProfile', ...
            'Unsupported execution profile "%s".', string(profile));
end
end

function policy = normalizeA0Policy(policyIn)
policy = string(policyIn);
if policy ~= "physicalTail"
    policy = "physicalTail";
end
end
