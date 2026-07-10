function [options, metadata] = mrlfeResolveExecutionProfile(branchName, profileInput, varargin)
%MRLFERESOLVEEXECUTIONPROFILE Resolve app-level profile for mRLFE workflows.
%
% All mRLFE app surfaces map to the maintained public fast preset and report
% non-Fast requests as mapped to that validated production configuration.

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

switch surface
    case {"gui", "main", "sweep", "api"}
        effectiveProfile = "Fast";
        options = rlDefaultOptions(requestedProfile);
        options.computeMRLFEComplexK = false;
        options.mrlfeA0Policy = normalizeA0Policy(p.Results.A0Policy);
        options.mrlfeParams = defaultMRLFEParams();
        options.mrlfeParams.etaS = p.Results.EtaS;
        options.mrlfeParams.etaL = 0;
        options.mrlfeParams.useComplexLambda = false;
        options = localApplyBranchFlags(options, branchName);
        overrideApplied = requestedProfile ~= effectiveProfile;
        if overrideApplied
            overrideReason = "mRLFE app surfaces preserve the validated public fast preset.";
        else
            overrideReason = "";
        end
        internalAtlasPreset = "fast";
    case "fit"
        effectiveProfile = "Fast";
        options = mrlfeDefaultSweepOptions(branchName, ...
            'EtaS', p.Results.EtaS, ...
            'A0Policy', normalizeA0Policy(p.Results.A0Policy));
        overrideApplied = requestedProfile ~= effectiveProfile;
        if overrideApplied
            overrideReason = "mRLFE FitTool preserves the maintained public fast preset.";
        else
            overrideReason = "";
        end
        internalAtlasPreset = "fast";
    otherwise
        error('mrlfeResolveExecutionProfile:UnsupportedSurface', ...
            'Unsupported mRLFE profile surface: %s.', surface);
end

options.executionProfile = requestedProfile;
options.effectiveExecutionProfile = effectiveProfile;
options.robustness = requestedProfile;

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
metadata.routePolicy = normalizeA0Policy(p.Results.A0Policy);
metadata.optimizerProfile = "";
metadata.surface = surface;
metadata.branchName = branchName;
metadata.etaS = p.Results.EtaS;
metadata.supportedExecutionProfiles = guiExecutionProfileValues();
metadata.profileSupportMode = "mapped_to_fast";
metadata.surfaceDefaultExecutionProfile = string(p.Results.DefaultProfile);
end

function policy = normalizeA0Policy(policyIn)
policy = string(policyIn);
if policy ~= "physicalTail"
    policy = "physicalTail";
end
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
