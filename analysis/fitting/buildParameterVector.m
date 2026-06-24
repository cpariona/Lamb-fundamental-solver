function [x, parameterInfo] = buildParameterVector(params, freeParams)
%BUILDPARAMETERVECTOR Build an optimizer vector from named free parameters.
%
% [x, parameterInfo] = buildParameterVector(params, freeParams)
%
% params is a scalar structure containing parameter fields. freeParams is a
% string array or cell array of parameter names. Each free parameter must be a
% finite scalar numeric value.

if nargin < 2
    error('params and freeParams are required.');
end
if ~isstruct(params) || ~isscalar(params)
    error('params must be a scalar structure.');
end

freeParams = string(freeParams(:));
if isempty(freeParams)
    error('freeParams must contain at least one parameter name.');
end

x = zeros(numel(freeParams), 1);
for i = 1:numel(freeParams)
    name = char(freeParams(i));
    if ~isfield(params, name)
        error('params is missing free parameter field: %s.', name);
    end
    value = params.(name);
    if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value)
        error('Free parameter %s must be a finite scalar numeric value.', name);
    end
    x(i) = value;
end

parameterInfo = struct();
parameterInfo.names = freeParams;
parameterInfo.numParameters = numel(freeParams);
parameterInfo.initialVector = x;
end
