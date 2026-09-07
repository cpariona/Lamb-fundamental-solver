function params = applyParameterOverrides(params, overrides)
%APPLYPARAMETEROVERRIDES Apply scalar-structure fitting parameter overrides.

if isempty(overrides)
    return;
end
if ~isstruct(overrides) || ~isscalar(overrides)
    error('Parameter overrides must be scalar structures.');
end
names = fieldnames(overrides);
for i = 1:numel(names)
    params.(names{i}) = overrides.(names{i});
end
end
