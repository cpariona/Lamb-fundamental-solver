%TEST_FIT_PARAMETER_EXECUTION_CONTRACT Trace edited physical parameters.

registry = guiGetFitRegistry();
for iFamily = 1:numel(registry.modelFamilies)
    family = registry.modelFamilies(iFamily);
    fitIds = string({family.parameters([family.parameters.canFit]).id});
    state = guiBuildFitParameterState(family.id, fitIds(1));

    for i = 1:numel(state.parameters)
        if state.parameters(i).role == "Fixed"
            state.parameters(i).valueDisplay = state.parameters(i).valueDisplay + 0.01 * i;
        end
    end
    config = guiBuildFitParameterRequest(state);
    request = guiBuildFitRequest(family.id, ...
        'branchName', family.defaultBranchName, ...
        'experimental', struct('frequency_Hz', [1000; 2000], 'Cp_mps', [1; 1]), ...
        'fixedParams', config.fixedParams, ...
        'freeParams', config.freeParams, ...
        'initialGuess', config.initialGuess, ...
        'bounds', config.bounds, ...
        'controls', config.controls);

    assert(isequaln(request.fixedParams, config.fixedParams));
    assert(isequaln(request.initialGuess, config.initialGuess));
    assert(isequaln(request.bounds, config.bounds));
    assert(isequaln(request.controls, config.controls));

    baseParams = struct();
    for i = 1:numel(family.parameters)
        meta = family.parameters(i);
        if string(meta.fixedDestination) == "fixedParams"
            baseParams.(char(meta.fieldName)) = meta.defaultValue;
        end
    end
    [syntheticParams, syntheticControls] = guiResolveFitModelSetup(family.id, baseParams, config);

    fixedNames = fieldnames(config.fixedParams);
    for i = 1:numel(fixedNames)
        name = fixedNames{i};
        assert(syntheticParams.(name) == config.fixedParams.(name));
    end
    initialNames = fieldnames(config.initialGuess);
    for i = 1:numel(initialNames)
        name = initialNames{i};
        assert(syntheticParams.(name) == config.initialGuess.(name));
    end
    assert(isequaln(syntheticControls, config.controls));
end

aeState = guiBuildFitParameterState("acoustoelastic_iop_hgo", "mu");
ids = string({aeState.parameters.id});
assert(aeState.parameters(ids == "mu").valueDisplay == 64);
assert(aeState.parameters(ids == "k1").valueDisplay == 50);
assert(aeState.parameters(ids == "k2").valueDisplay == 200);

fprintf('test_fit_parameter_execution_contract passed. Synthetic and fitting paths share the same edited configuration.\n');
