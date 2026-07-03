function [options, metadata] = mrlfeResolveExecutionProfile(branchName, profileInput, varargin)
%MRLFERESOLVEEXECUTIONPROFILE Resolve app-level profile for mRLFE workflows.
%
% Surface "gui"/"sweep" preserves the current maintained fast atlas routes
% and records non-Fast requests as mapped to the validated Fast internal
% preset. Surface "fit" preserves the fast_fit_atlas route.

p = inputParser;
addRequired(p, 'branchName', @(x)ischar(x) || isstring(x));
addRequired(p, 'profileInput');
addParameter(p, 'Surface', "gui", @(x)ischar(x) || isstring(x));
addParameter(p, 'DefaultProfile', "Fast", @(x)ischar(x) || isstring(x));
addParameter(p, 'DefaultSource', "default", @(x)ischar(x) || isstring(x));
addParameter(p, 'EtaS', 0.05, @(x)isnumeric(x) && isscalar(x) && isfinite(x));
addParameter(p, 'UseUnifiedAtlasRoute', false, @(x)islogical(x) || isnumeric(x));
addParameter(p, 'A0Policy', "adaptivePhysicalTail", @(x)ischar(x) || isstring(x));
parse(p, branchName, profileInput, varargin{:});

branchName = string(p.Results.branchName);
surface = lower(string(p.Results.Surface));
[requestedProfile, metadata] = guiNormalizeExecutionProfile(profileInput, ...
    'DefaultProfile', p.Results.DefaultProfile, ...
    'DefaultSource', p.Results.DefaultSource);

switch surface
    case {"gui", "main", "sweep", "api"}
        effectiveProfile = "Fast";
        options = rlDefaultOptions(requestedProfile);
        options.computeMRLFEComplexK = false;
        options.mrlfeUseUnifiedAtlasRoute = logical(p.Results.UseUnifiedAtlasRoute);
        options.mrlfeA0Policy = string(p.Results.A0Policy);
        options.mrlfeParams = defaultMRLFEParams();
        options.mrlfeParams.etaS = p.Results.EtaS;
        options.mrlfeParams.etaL = 0;
        options.mrlfeParams.useComplexLambda = false;
        options = localApplyBranchFlags(options, branchName);
        overrideApplied = requestedProfile ~= effectiveProfile;
        if overrideApplied
            overrideReason = "mRLFE GUI and sweep surfaces preserve validated fast atlas presets.";
        else
            overrideReason = "";
        end
        internalAtlasPreset = "gui_fast_route_selected_later";
    case "fit"
        effectiveProfile = "Fast";
        options = mrlfeDefaultSweepOptions(branchName, ...
            'EtaS', p.Results.EtaS, ...
            'UseUnifiedAtlasRoute', logical(p.Results.UseUnifiedAtlasRoute), ...
            'A0Policy', string(p.Results.A0Policy));
        options.mrlfeFitAtlasPreset = "fast_fit_atlas";
        overrideApplied = requestedProfile ~= effectiveProfile;
        if overrideApplied
            overrideReason = "mRLFE FitTool preserves the maintained fast atlas fit route.";
        else
            overrideReason = "";
        end
        internalAtlasPreset = "fast_fit_atlas";
    otherwise
        error('mrlfeResolveExecutionProfile:UnsupportedSurface', ...
            'Unsupported mRLFE profile surface: %s.', surface);
end

options.executionProfile = requestedProfile;
options.effectiveExecutionProfile = effectiveProfile;
options.robustness = effectiveProfile;

metadata.requestedExecutionProfile = requestedProfile;
metadata.effectiveExecutionProfile = effectiveProfile;
if surface == "fit"
    metadata.internalSolverPreset = effectiveProfile;
else
    metadata.internalSolverPreset = requestedProfile;
end
metadata.internalAtlasPreset = internalAtlasPreset;
metadata.profileOverrideApplied = logical(overrideApplied);
metadata.profileOverrideReason = overrideReason;
metadata.routePolicy = string(p.Results.A0Policy);
metadata.optimizerProfile = "";
metadata.surface = surface;
metadata.branchName = branchName;
metadata.etaS = p.Results.EtaS;
metadata.useUnifiedAtlasRoute = logical(p.Results.UseUnifiedAtlasRoute);
metadata.supportedExecutionProfiles = guiExecutionProfileValues();
metadata.profileSupportMode = "mapped_to_fast";
metadata.surfaceDefaultExecutionProfile = string(p.Results.DefaultProfile);
end

function options = localApplyBranchFlags(options, branchName)
switch branchName
    case "A0Like"
        options.computeA0 = true;
        options.computeS0 = false;
        options.mrlfeComputeA0Like = true;
        options.mrlfeComputeS0Like = false;
    case "S0Like"
        options.computeA0 = false;
        options.computeS0 = true;
        options.mrlfeComputeA0Like = false;
        options.mrlfeComputeS0Like = true;
    otherwise
        error('mrlfeResolveExecutionProfile:UnsupportedBranch', ...
            'Unsupported mRLFE branchName "%s". Use "A0Like" or "S0Like".', branchName);
end
options.computeMRLFERealK = true;
options.computeMRLFEElasticRealK = false;
options.computeMRLFEViscoRealK = false;
end
