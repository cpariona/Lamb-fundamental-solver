function policy = aeNormalizeBranchPolicy(policy)
%AENORMALIZEBRANCHPOLICY Normalize acoustoelastic atlas branch-policy names.
%
%   policy = aeNormalizeBranchPolicy(policy) returns the canonical policy name
%   used by maintained acoustoelastic IOP/HGO workflows.
%
%   Canonical policy
%   ----------------
%   "atlasA0" is the maintained atlas-based A0 branch-selection policy.
%
%   Legacy alias
%   ------------
%   "strictA0" remains accepted for backward compatibility with existing
%   workspaces, scripts, and diagnostic outputs. It maps to "atlasA0".

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
        error('Unknown acoustoelastic atlas branch policy: %s. Use "atlasA0" or legacy alias "strictA0".', policy);
end
end
