function policy = aeNormalizeBranchPolicy(policy)
%AENORMALIZEBRANCHPOLICY Normalize acoustoelastic atlas branch-policy names.
%
%   policy = aeNormalizeBranchPolicy(policy) returns the canonical policy name
%   used by maintained acoustoelastic IOP/HGO workflows when a known alias is
%   supplied.
%
%   Canonical policy
%   ----------------
%   "atlasA0" is the maintained atlas-based A0 branch-selection policy.
%
%   Legacy alias
%   ------------
%   "strictA0" remains accepted for backward compatibility with existing
%   workspaces, scripts, and diagnostic outputs. It maps to "atlasA0".
%
%   Diagnostic policies
%   -------------------
%   Other policy names are returned unchanged so experimental diagnostic
%   scripts can continue to compare policy variants without being blocked by
%   this compatibility helper.

if nargin < 1 || isempty(policy)
    policy = "atlasA0";
    return;
end

policy = string(policy);

switch lower(strtrim(policy))
    case "stricta0"
        policy = "atlasA0";
    case "atlasa0"
        policy = "atlasA0";
    otherwise
        policy = string(policy);
end
end
