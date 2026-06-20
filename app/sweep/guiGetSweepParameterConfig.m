function parameter = guiGetSweepParameterConfig(family, parameterId)
%GUIGETSWEEPPARAMETERCONFIG Return one parameter config from a model-family config.

parameterId = string(parameterId);
parameters = family.parameters;

for i = 1:numel(parameters)
    if string(parameters(i).id) == parameterId
        parameter = parameters(i);
        return;
    end
end

error('Unknown GUI sweep parameter for %s: %s', string(family.id), parameterId);
end
