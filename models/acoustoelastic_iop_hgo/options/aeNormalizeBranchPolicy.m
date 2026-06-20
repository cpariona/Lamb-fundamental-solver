function policy = aeNormalizeBranchPolicy(policy)
%AENORMALIZEBRANCHPOLICY Normalize acoustoelastic atlas branch-policy names.
%
%   "atlasA0" is the maintained atlas-based A0 branch-selection policy.
%   "identityA0Diagnostic" keeps the official atlasA0 output unchanged and
%   writes an identity-scored candidate branch under result.identityA0.

if nargin < 1 || isempty(policy)
    policy = "atlasA0";
    return;
end

policy = string(policy);

switch lower(strtrim(policy))
    case "atlasa0"
        policy = "atlasA0";
    case "identitya0diagnostic"
        policy = "identityA0Diagnostic";
    otherwise
        policy = string(policy);
end
end
