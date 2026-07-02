clear; clc;
startup

fprintf('\nRunning FitTool model registry contract test...\n');
fprintf('--------------------------------------------\n');

registry = guiGetFitRegistry();
assert(numel(registry.modelFamilies) >= 3, 'Fit registry must expose at least three model families.');

ids = strings(1, numel(registry.modelFamilies));
labels = strings(1, numel(registry.modelFamilies));
for i = 1:numel(registry.modelFamilies)
    ids(i) = registry.modelFamilies(i).id;
    labels(i) = registry.modelFamilies(i).label;
end

assert(any(ids == "rayleigh_lamb"), 'FitTool registry must expose Rayleigh-Lamb.');
assert(any(ids == "mrlfe"), 'FitTool registry must expose mRLFE.');
assert(any(ids == "acoustoelastic_iop_hgo"), 'FitTool registry must expose AE IOP/HGO.');
assert(all(strlength(labels) > 0), 'FitTool registry labels must be nonempty.');

assertFamilyParameters(registry, "rayleigh_lamb", ["mu", "thickness"]);
assertFamilyParameters(registry, "mrlfe", ["mu", "thickness", "etaS"]);
assertFamilyParameters(registry, "acoustoelastic_iop_hgo", ["mu", "thickness", "IOP"]);

fig = uifigure('Visible', 'off');
cleanup = onCleanup(@()delete(fig));
tabs = uitabgroup(fig);
callbacks = struct();
callbacks.onFitModelChanged = @(~,~)[];
callbacks.onFitParameterChanged = @(~,~)[];
callbacks.onPopulateFitData = @(~,~)[];
callbacks.onResetDefaults = @(~,~)[];
callbacks.onRunFit = @(~,~)[];

controls = createFittingTab(tabs, rlDefaultParams(), callbacks);
assert(isfield(controls, 'model'), 'Fitting tab controls must include model dropdown.');
assert(isfield(controls, 'branch'), 'Fitting tab controls must include branch dropdown.');
assert(isfield(controls, 'freeParam'), 'Fitting tab controls must include freeParam dropdown.');
assert(numel(controls.model.Items) >= 3, 'Model dropdown must expose at least three models.');
assert(any(strcmp(controls.model.Items, 'Rayleigh-Lamb')), 'Model dropdown must include Rayleigh-Lamb.');
assert(any(strcmp(controls.model.Items, 'mRLFE')), 'Model dropdown must include mRLFE.');
assert(any(strcmp(controls.model.Items, 'AE IOP/HGO')), 'Model dropdown must include AE IOP/HGO.');

fprintf('Available fitting models: %s\n', strjoin(cellstr(labels), ', '));
fprintf('\nFitTool model registry contract test passed.\n');

function assertFamilyParameters(registry, familyId, requiredParams)
family = [];
for i = 1:numel(registry.modelFamilies)
    if registry.modelFamilies(i).id == familyId
        family = registry.modelFamilies(i);
        break;
    end
end
assert(~isempty(family), 'Missing fitting family: %s.', familyId);
ids = strings(1, numel(family.parameters));
canFit = false(1, numel(family.parameters));
for i = 1:numel(family.parameters)
    ids(i) = family.parameters(i).id;
    canFit(i) = family.parameters(i).canFit;
end
for i = 1:numel(requiredParams)
    idx = find(ids == requiredParams(i), 1, 'first');
    assert(~isempty(idx), 'Fitting family %s must expose parameter %s.', familyId, requiredParams(i));
    assert(canFit(idx), 'Fitting family %s parameter %s must be fit-capable.', familyId, requiredParams(i));
end
end
