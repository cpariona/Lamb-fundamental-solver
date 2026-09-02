function test_parametric_sweep_workflow()
%TEST_PARAMETRIC_SWEEP_WORKFLOW Protect the shared one-dimensional loop.

baseParams = struct('value', 1);
baseOptions = struct('scale', 2);
spec = struct( ...
    'parameter', "value", ...
    'parameterPath', "params.value", ...
    'values', [1 2 3], ...
    'displayScale', 1, ...
    'label', "Value", ...
    'units', "unit");

sweep = runParametricSweep(baseParams, baseOptions, spec, @evaluateCondition);
assert(numel(sweep.results) == 3);
assert(numel(sweep.points) == 3);
assert(all(cellfun(@(p)p.status == "ok", sweep.points)));
for i = 1:3
    result = sweep.results{i};
    assert(result.phaseVelocity_mps == 2 * i);
    assert(sweep.params{i}.value == i);
    assert(sweep.requests{i}.value == i);
end

nestedSpec = spec;
nestedSpec.parameter = "scale";
nestedSpec.parameterPath = "options.nested.scale";
nestedSpec.values = [4 5];
nestedOptions = struct('nested', struct('scale', 1));
nested = runParametricSweep(baseParams, nestedOptions, nestedSpec, @evaluateNested);
assert(nested.results{1}.phaseVelocity_mps == 4);
assert(nested.results{2}.phaseVelocity_mps == 5);

fprintf('Shared parametric-sweep workflow contract passed.\n');
end

function result = evaluateCondition(params, options)
result = canonicalResult(params.value * options.scale, params.value);
end

function result = evaluateNested(params, options)
result = canonicalResult(params.value * options.nested.scale, options.nested.scale);
end

function result = canonicalResult(value, requestedValue)
result = struct( ...
    'model', "synthetic", ...
    'frequency_Hz', 1, ...
    'phaseVelocity_mps', value, ...
    'wavenumber_radpm', 2*pi/value, ...
    'validMask', true, ...
    'quality', struct('accepted', true), ...
    'configuration', struct('requested', struct('value', requestedValue), ...
        'effective', struct('value', requestedValue)), ...
    'execution', struct('engine', "synthetic"));
end
