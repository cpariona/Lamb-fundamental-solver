function value = getOptionValue(optionsStruct, fieldName, defaultValue)
%GETOPTIONVALUE Return a struct field value or a default value.
%
% value = getOptionValue(optionsStruct, fieldName, defaultValue) reads
% optionsStruct.(fieldName) when it exists and is non-empty. Otherwise it
% returns defaultValue. This small helper is shared by GUI callbacks and
% adapter-facing code that needs robust optional-field reads.

if isstruct(optionsStruct) && isfield(optionsStruct, fieldName) && ~isempty(optionsStruct.(fieldName))
    value = optionsStruct.(fieldName);
else
    value = defaultValue;
end
end
