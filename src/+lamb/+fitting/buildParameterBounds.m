function [lowerBounds, upperBounds] = buildParameterBounds(bounds, freeParams)
%BUILDPARAMETERBOUNDS Build ordered lower and upper fitting bounds.

lowerBounds = -inf(numel(freeParams), 1);
upperBounds = inf(numel(freeParams), 1);
for i = 1:numel(freeParams)
    name = char(freeParams(i));
    if isstruct(bounds) && isfield(bounds, name) && ~isempty(bounds.(name))
        value = bounds.(name);
        if ~isnumeric(value) || numel(value) ~= 2 || value(1) >= value(2)
            error('bounds.%s must be a numeric [lower upper] pair.', name);
        end
        lowerBounds(i) = value(1);
        upperBounds(i) = value(2);
    end
end
end
