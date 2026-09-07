function [profile, metadata] = guiNormalizeExecutionProfile(inputValue, varargin)
%GUINORMALIZEEXECUTIONPROFILE Canonicalize app-level execution profile input.

p = inputParser;
addParameter(p, 'DefaultProfile', "Balanced", @(x)ischar(x) || isstring(x));
addParameter(p, 'DefaultSource', "default", @(x)ischar(x) || isstring(x));
addParameter(p, 'Source', "", @(x)ischar(x) || isstring(x));
parse(p, varargin{:});

defaultProfile = localCanonicalProfile(p.Results.DefaultProfile);
defaultSource = string(p.Results.DefaultSource);

if nargin < 1 || isempty(inputValue)
    profile = defaultProfile;
    source = defaultSource;
elseif isstruct(inputValue)
    if isfield(inputValue, 'executionProfile') && ~isempty(inputValue.executionProfile) && ...
            strlength(string(inputValue.executionProfile)) > 0
        profile = localCanonicalProfile(inputValue.executionProfile);
        source = "executionProfile";
    else
        profile = defaultProfile;
        source = defaultSource;
    end
else
    profile = localCanonicalProfile(inputValue);
    source = string(p.Results.Source);
    if strlength(source) == 0
        source = "executionProfile";
    end
end

metadata = struct();
metadata.requestedExecutionProfile = profile;
metadata.effectiveExecutionProfile = profile;
metadata.executionProfileSource = source;
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
