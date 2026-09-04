function [params, controls] = guiResolveFitModelSetup(modelFamily, baseParams, config)
%GUIRESOLVEFITMODELSETUP Resolve physical parameters from one FitTool config.

params = guiMergeStructs(baseParams, config.fixedParams);
params = guiMergeStructs(params, config.initialGuess);
controls = config.controls;

registry = guiGetFitModelConfiguration();
family = findFamily(registry, modelFamily);
for i = 1:numel(family.parameters)
    meta = family.parameters(i);
    if string(meta.fixedDestination) ~= "controls"
        continue;
    end
    fieldName = char(meta.fieldName);
    if isfield(controls, fieldName) && string(meta.id) == "etaS"
        params.(fieldName) = controls.(fieldName);
    end
end
end

function family = findFamily(registry, modelFamily)
modelFamily = string(modelFamily);
for i = 1:numel(registry.modelFamilies)
    if string(registry.modelFamilies(i).id) == modelFamily
        family = registry.modelFamilies(i);
        return;
    end
end
error('guiResolveFitModelSetup:UnknownModelFamily', ...
    'Unknown fitting model family: %s.', modelFamily);
end
