function family = guiGetSweepFamilyConfig(registry, modelFamily)
%GUIGETSWEEPFAMILYCONFIG Return one model-family config from the sweep registry.

modelFamily = string(modelFamily);
families = registry.modelFamilies;

for i = 1:numel(families)
    if string(families(i).id) == modelFamily
        family = families(i);
        return;
    end
end

error('Unknown GUI sweep model family: %s', modelFamily);
end
