%TEST_FIT_PARAMETER_STATE_CONTRACT Registry-driven one-parameter state contract.

registry = guiGetFitRegistry();
for iFamily = 1:numel(registry.modelFamilies)
    family = registry.modelFamilies(iFamily);
    fitIds = string({family.parameters([family.parameters.canFit]).id});
    state = guiBuildFitParameterState(family.id, fitIds(1));

    assert(numel(state.parameters) == numel(family.parameters), ...
        'Every registered parameter must appear in FitTool state.');
    assert(nnz(arrayfun(@(p) string(p.role) == "Fit", state.parameters)) == 1, ...
        'Exactly one parameter must have role Fit.');

    data = guiFitParameterStateToTable(state);
    assert(height(data) == numel(family.parameters), ...
        'FitTool table must expose every registered parameter.');

    fixedIndex = find(string(data.Role) == "Fixed", 1, 'first');
    data.Value(fixedIndex) = data.Value(fixedIndex) + 1;
    state = guiApplyFitParameterTable(state, data);
    config = guiBuildFitParameterRequest(state);

    fixedRow = state.parameters(fixedIndex);
    expected = fixedRow.valueDisplay * fixedRow.displayScale;
    destination = fixedRow.fixedDestination;
    if destination == "controls"
        assert(isfield(config.controls, char(fixedRow.fieldName)), ...
            'Control-destination parameter was not routed to controls.');
        actual = config.controls.(char(fixedRow.fieldName));
    else
        assert(isfield(config.fixedParams, char(fixedRow.fieldName)), ...
            'Fixed parameter was not routed to fixedParams.');
        actual = config.fixedParams.(char(fixedRow.fieldName));
    end
    assert(actual == expected, ...
        'Edited fixed parameter value was not preserved in the request.');

    assert(numel(config.freeParams) == 1 && config.freeParams == fitIds(1), ...
        'FitTool request must contain exactly one free parameter.');
end

mrlfeState = guiBuildFitParameterState("mrlfe", "mu");
mrlfeConfig = guiBuildFitParameterRequest(mrlfeState);
assert(isfield(mrlfeConfig.controls, 'etaS'), ...
    'Fixed mRLFE etaS must be routed through controls.');
assert(isfield(mrlfeConfig.controls, 'fluidDensity'), ...
    'mRLFE fluidDensity must be routed through controls.');
assert(isfield(mrlfeConfig.controls, 'fluidSoundSpeed'), ...
    'mRLFE fluidSoundSpeed must be routed through controls.');

fprintf('test_fit_parameter_state_contract passed. FitTool exposes and routes all registered parameters.\n');
