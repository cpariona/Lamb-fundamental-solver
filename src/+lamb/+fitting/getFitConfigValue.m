function value = getFitConfigValue(config, fieldName, defaultValue)
%GETFITCONFIGVALUE Read a nonempty fitting configuration value or its default.

if isstruct(config) && isfield(config, fieldName) && ~isempty(config.(fieldName))
    value = config.(fieldName);
else
    value = defaultValue;
end
end
