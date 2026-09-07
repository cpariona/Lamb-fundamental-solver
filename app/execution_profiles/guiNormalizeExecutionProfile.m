function [profile, metadata] = guiNormalizeExecutionProfile(inputValue, varargin)
%GUINORMALIZEEXECUTIONPROFILE Canonicalize app-level execution profile input.
%
% Supports the canonical executionProfile field and the legacy robustness
% alias. If both are present they must resolve to the same canonical value.

p = inputParser;
addParameter(p, 'DefaultProfile', "Balanced", @(x)ischar(x) || isstring(x));
addParameter(p, 'DefaultSource', "default", @(x)ischar(x) || isstring(x));
addParameter(p, 'Source', "", @(x)ischar(x) || isstring(x));
parse(p, varargin{:});

defaultProfile = localCanonicalProfile(p.Results.DefaultProfile);
defaultSource = string(p.Results.DefaultSource);

if nargin < 1 || isempty(inputValue)
    [profile, source, aliasUsed] = deal(defaultProfile, defaultSource, false);
elseif isstruct(inputValue)
    [profile, source, aliasUsed] = localProfileFromStruct(inputValue, defaultProfile, defaultSource);
else
    profile = localCanonicalProfile(inputValue);
    source = string(p.Results.Source);
    if strlength(source) == 0
        source = "executionProfile";
    end
    aliasUsed = source == "robustness";
end

metadata = struct();
metadata.requestedExecutionProfile = profile;
metadata.effectiveExecutionProfile = profile;
metadata.executionProfileSource = source;
metadata.legacyRobustnessAliasUsed = logical(aliasUsed);
end

function [profile, source, aliasUsed] = localProfileFromStruct(s, defaultProfile, defaultSource)
hasExecutionProfile = isfield(s, 'executionProfile') && ~isempty(s.executionProfile) && ...
    strlength(string(s.executionProfile)) > 0;
hasRobustness = isfield(s, 'robustness') && ~isempty(s.robustness) && ...
    strlength(string(s.robustness)) > 0;

if hasExecutionProfile
    executionProfile = localCanonicalProfile(s.executionProfile);
end
if hasRobustness
    robustnessProfile = localCanonicalProfile(s.robustness);
end

if hasExecutionProfile && hasRobustness
    if executionProfile ~= robustnessProfile
        error('guiNormalizeExecutionProfile:ConflictingProfiles', ...
            'executionProfile "%s" conflicts with robustness "%s".', ...
            string(s.executionProfile), string(s.robustness));
    end
    profile = executionProfile;
    source = "executionProfile+robustness";
    aliasUsed = true;
elseif hasExecutionProfile
    profile = executionProfile;
    source = "executionProfile";
    aliasUsed = false;
elseif hasRobustness
    profile = robustnessProfile;
    source = "robustness";
    aliasUsed = true;
else
    profile = defaultProfile;
    source = defaultSource;
    aliasUsed = false;
end
end

function profile = localCanonicalProfile(value)
value = string(value);
if numel(value) ~= 1 || strlength(value) == 0
    error('guiNormalizeExecutionProfile:InvalidProfile', ...
        'Execution profile must be one of Fast, Balanced, or Robust.');
end

switch lower(strtrim(value))
    case "fast"
        profile = "Fast";
    case "balanced"
        profile = "Balanced";
    case "robust"
        profile = "Robust";
    otherwise
        error('guiNormalizeExecutionProfile:InvalidProfile', ...
            'Unknown execution profile "%s". Use Fast, Balanced, or Robust.', value);
end
end
