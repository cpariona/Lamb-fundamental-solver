function controls = guiNormalizeControlExecutionProfile(controls, varargin)
%GUINORMALIZECONTROLEXECUTIONPROFILE Normalize request controls profile alias.
%
% The canonical app-level field is executionProfile. The historical
% robustness alias is preserved in normalized controls for compatibility with
% maintained APIs and older scripts.

p = inputParser;
addParameter(p, 'DefaultProfile', "Fast", @(x)ischar(x) || isstring(x));
addParameter(p, 'DefaultSource', "default", @(x)ischar(x) || isstring(x));
parse(p, varargin{:});

if ~isstruct(controls)
    controls = struct();
    return;
end

if ~localHasProfileField(controls, 'executionProfile') && ...
        ~localHasProfileField(controls, 'robustness')
    return;
end

[profile, ~] = guiNormalizeExecutionProfile(controls, ...
    'DefaultProfile', p.Results.DefaultProfile, ...
    'DefaultSource', p.Results.DefaultSource);
controls.executionProfile = profile;
controls.robustness = profile;
end

function tf = localHasProfileField(s, fieldName)
tf = isfield(s, fieldName) && ~isempty(s.(fieldName)) && ...
    strlength(string(s.(fieldName))) > 0;
end
