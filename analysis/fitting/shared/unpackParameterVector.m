function params = unpackParameterVector(x, params, freeParams)
%UNPACKPARAMETERVECTOR Write optimizer vector values into a parameter struct.
%
% params = unpackParameterVector(x, params, freeParams)

if nargin < 3
    error('x, params, and freeParams are required.');
end
if ~isstruct(params) || ~isscalar(params)
    error('params must be a scalar structure.');
end

x = x(:);
freeParams = string(freeParams(:));

if numel(x) ~= numel(freeParams)
    error('x and freeParams must have the same number of elements.');
end

for i = 1:numel(freeParams)
    name = char(freeParams(i));
    if ~isfield(params, name)
        error('params is missing free parameter field: %s.', name);
    end
    if ~isnumeric(x(i)) || ~isscalar(x(i)) || ~isfinite(x(i))
        error('Parameter vector value for %s must be finite numeric scalar.', name);
    end
    params.(name) = x(i);
end
end
