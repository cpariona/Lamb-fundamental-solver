function test_fit_parameter_state_contract()
%TEST_FIT_PARAMETER_STATE_CONTRACT Registry-driven one-parameter state contract.

registry = guiGetFitModelConfiguration();
for iFamily = 1:numel(registry.modelFamilies)
    family = registry.modelFamilies(iFamily);
    fitIds = string({family.parameters([family.parameters.canFit]).id});

    for iFit = 1:numel(fitIds)
        state = guiBuildFitParameterState(family.id, fitIds(iFit));

        assert(numel(state.parameters) == numel(family.parameters), ...
            'Every registered parameter must appear in FitTool state.');
        assert(nnz(arrayfun(@(p) string(p.role) == "Fit", state.parameters)) == 1, ...
            'Exactly one parameter must have role Fit.');

        data = guiFitParameterStateToTable(state);
        assert(height(data) == numel(family.parameters), ...
            'FitTool table must expose every registered parameter.');

        fitIndex = find(string(data.Role) == "Fit", 1, 'first');
        fixedIndex = find(string(data.Role) == "Fixed", 1, 'first');
        assert(isempty(data.Value{fitIndex}), ...
            'The fitted row must not display a fixed Value.');
        assert(~isempty(data.Initial{fitIndex}) && ~isempty(data.Lower{fitIndex}) && ~isempty(data.Upper{fitIndex}), ...
            'The fitted row must display Initial, Lower, and Upper values.');
        assert(~isempty(data.Value{fixedIndex}), ...
            'Fixed rows must display a fixed Value.');
        assert(isempty(data.Initial{fixedIndex}) && isempty(data.Lower{fixedIndex}) && isempty(data.Upper{fixedIndex}), ...
            'Fixed rows must not display Initial, Lower, or Upper values.');

        data.Value{fixedIndex} = data.Value{fixedIndex} + 1;
        originalFitValue = state.parameters(fitIndex).valueDisplay;
        state = guiApplyFitParameterTable(state, data);
        guiValidateFitParameterState(state);
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
        assert(state.parameters(fitIndex).valueDisplay == originalFitValue, ...
            'The hidden fixed value of the fitted row must be preserved.');

        assert(numel(config.freeParams) == 1 && config.freeParams == fitIds(iFit), ...
            'FitTool request must contain exactly the selected free parameter.');
        freeField = char(state.parameters(fitIndex).fieldName);
        assert(isfield(config.initialGuess, freeField), ...
            'Initial guess must contain the selected free parameter.');
        assert(isfield(config.bounds, freeField), ...
            'Bounds must contain the selected free parameter.');
    end
end

mrlfeState = guiBuildFitParameterState("mrlfe", "mu");
mrlfeConfig = guiBuildFitParameterRequest(mrlfeState);
assert(isfield(mrlfeConfig.controls, 'etaS'), ...
    'Fixed mRLFE etaS must be routed through controls.');
assert(isfield(mrlfeConfig.controls, 'fluidDensity'), ...
    'mRLFE fluidDensity must be routed through controls.');
assert(isfield(mrlfeConfig.controls, 'fluidSoundSpeed'), ...
    'mRLFE fluidSoundSpeed must be routed through controls.');

invalidBounds = guiBuildFitParameterState("rayleigh_lamb", "mu");
fitIndex = find(arrayfun(@(p) string(p.role) == "Fit", invalidBounds.parameters), 1);
invalidBounds.parameters(fitIndex).lowerDisplay = invalidBounds.parameters(fitIndex).upperDisplay;
assertErrorIdentifier(@() guiValidateFitParameterState(invalidBounds), ...
    'guiValidateFitParameterState:InvalidBounds');

outsideBounds = guiBuildFitParameterState("rayleigh_lamb", "mu");
fitIndex = find(arrayfun(@(p) string(p.role) == "Fit", outsideBounds.parameters), 1);
outsideBounds.parameters(fitIndex).initialDisplay = outsideBounds.parameters(fitIndex).upperDisplay + 1;
assertErrorIdentifier(@() guiValidateFitParameterState(outsideBounds), ...
    'guiValidateFitParameterState:InitialOutsideBounds');

invalidFixed = guiBuildFitParameterState("acoustoelastic_iop_hgo", "mu");
fixedIndex = find(arrayfun(@(p) string(p.role) == "Fixed", invalidFixed.parameters), 1);
invalidFixed.parameters(fixedIndex).valueDisplay = NaN;
assertErrorIdentifier(@() guiValidateFitParameterState(invalidFixed), ...
    'guiValidateFitParameterState:InvalidNumericValue');

fprintf('test_fit_parameter_state_contract passed. FitTool state, routing, and validation contracts are preserved.\n');
end

function assertErrorIdentifier(action, expectedIdentifier)
didThrow = false;
try
    action();
catch ME
    didThrow = true;
    assert(strcmp(ME.identifier, expectedIdentifier), ...
        'Expected error identifier %s but received %s.', expectedIdentifier, ME.identifier);
end
assert(didThrow, 'Expected action to throw %s.', expectedIdentifier);
end
