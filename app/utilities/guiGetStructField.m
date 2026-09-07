function value = guiGetStructField(s, name, defaultValue)
%GUIGETSTRUCTFIELD Return a non-empty struct field or a default value.
%
%   This helper preserves the GUI adapter convention that empty fields behave
%   like missing fields while false, zero, and empty strings remain explicit
%   values when MATLAB stores them as non-empty scalars.

if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
