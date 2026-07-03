function [options, metadata] = mrlfeResolveExecutionProfile(branchName, profileInput, varargin)
%MRLFERESOLVEEXECUTIONPROFILE Resolve app-level profile for mRLFE workflows.
%
% Surface "gui" preserves the requested profile as the Rayleigh-Lamb seed
% profile. Surface "fit" preserves the current maintained FitTool behavior:
% the effective solver profile remains Fast and the atlas fit preset remains
% route-specific metadata rather than a branch-policy change.

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
        effectiveProfile = requestedProfile;
        options = rlDefaultOptions(effectiveProfile);
        options.computeMRLFEComplexK = false;
        options.mrlfeUseUnifiedAtlasRoute = logical(p.Results.UseUnifiedAtlasRoute);
        options.mrlfeA0Policy = string(p.Results.A0Policy);
        options.mrlfeParams = defaultMRLFEParams();
        options.mrlfeParams.etaS = p.Results.EtaS;
        options.mrlfeParams.etaL = 0;
        options.mrlfeParams.useComplexLambda = false;
        options = localApplyBranchFlags(options, branchName);
        overrideApplied = false;
        overrideReason = "";
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
metadata.internalSolverPreset = effectiveProfile;
metadata.internalAtlasPreset = internalAtlasPreset;
metadata.profileOverrideApplied = logical(overrideApplied);
metadata.profileOverrideReason = overrideReason;
metadata.routePolicy = string(p.Results.A0Policy);
metadata.optimizerProfile = "";
metadata.surface = surface;
metadata.branchName = branchName;
metadata.etaS = p.Results.EtaS;
metadata.useUnifiedAtlasRoute = logical(p.Results.UseUnifiedAtlasRoute);
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
