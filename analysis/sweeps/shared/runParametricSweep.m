function sweepResults = runParametricSweep(baseParams, baseOptions, sweepSpec, evaluateCondition)
%RUNPARAMETRICSWEEP Evaluate one canonical model result per parameter value.
%
% sweepSpec requires parameter, parameterPath, and values. parameterPath is
% rooted at either "params" or "options". The supplied evaluator receives
% the completed params/options pair and owns translation to a model request.

validateInputs(sweepSpec, evaluateCondition);
values = sweepSpec.values(:).';
displayValues = resolveDisplayValues(sweepSpec, values);
n = numel(values);

sweepResults = struct( ...
    'spec', normalizeSpec(sweepSpec), ...
    'parameter', string(sweepSpec.parameter), ...
    'values', values, ...
    'displayValues', displayValues, ...
    'results', {cell(1, n)}, ...
    'params', {cell(1, n)}, ...
    'options', {cell(1, n)}, ...
    'elapsedSeconds', nan(1, n), ...
    'points', {cell(1, n)}, ...
    'requests', {cell(1, n)});

continueOnError = logical(specValue(sweepSpec, 'continueOnError', false));
for i = 1:n
    [params, options] = applySweepValue( ...
        baseParams, baseOptions, sweepSpec.parameterPath, values(i));
    point = newPoint(sweepSpec, values(i), displayValues(i));
    timerStart = tic;
    try
        modelResult = evaluateCondition(params, options);
        validateModelResult(modelResult);
        point = completePoint(point, modelResult);
        sweepResults.results{i} = modelResult;
        sweepResults.requests{i} = requestedConfiguration(modelResult);
    catch err
        if ~continueOnError
            rethrow(err);
        end
        point.status = "failed";
        point.errorIdentifier = string(err.identifier);
        point.errorMessage = string(err.message);
        sweepResults.results{i} = struct();
    end
    point.elapsedSeconds = toc(timerStart);
    sweepResults.params{i} = params;
    sweepResults.options{i} = options;
    sweepResults.elapsedSeconds(i) = point.elapsedSeconds;
    sweepResults.points{i} = point;
    fprintf('Sweep %s = %.6g complete in %.2f s (%d/%d).\n', ...
        string(sweepSpec.parameter), values(i), point.elapsedSeconds, i, n);
end
end

function validateInputs(spec, evaluator)
required = {'parameter', 'parameterPath', 'values'};
for i = 1:numel(required)
    if ~isstruct(spec) || ~isfield(spec, required{i}) || isempty(spec.(required{i}))
        error('runParametricSweep:InvalidSpec', ...
            'sweepSpec.%s is required.', required{i});
    end
end
if ~isa(evaluator, 'function_handle')
    error('runParametricSweep:InvalidEvaluator', ...
        'evaluateCondition must be a function handle.');
end
path = string(spec.parameterPath);
if ~isscalar(path) || ~(startsWith(path, "params.") || startsWith(path, "options."))
    error('runParametricSweep:InvalidParameterPath', ...
        'parameterPath must start with "params." or "options.".');
end
end

function spec = normalizeSpec(spec)
if ~isfield(spec, 'label') || strlength(string(spec.label)) == 0
    spec.label = string(spec.parameter);
end
if ~isfield(spec, 'units')
    spec.units = "";
end
if ~isfield(spec, 'displayScale') || isempty(spec.displayScale)
    spec.displayScale = 1;
end
end

function displayValues = resolveDisplayValues(spec, values)
scale = specValue(spec, 'displayScale', 1);
if isfield(spec, 'displayValues') && ~isempty(spec.displayValues)
    displayValues = spec.displayValues(:).';
    if numel(displayValues) ~= numel(values)
        error('runParametricSweep:InvalidDisplayValues', ...
            'displayValues must match values in length.');
    end
else
    displayValues = values ./ scale;
end
end

function [params, options] = applySweepValue(baseParams, baseOptions, path, value)
params = baseParams;
options = baseOptions;
parts = split(string(path), '.');
root = parts(1);
fieldParts = cellstr(parts(2:end));
if root == "params"
    params = setNestedField(params, fieldParts, value);
else
    options = setNestedField(options, fieldParts, value);
end
end

function s = setNestedField(s, parts, value)
name = parts{1};
if numel(parts) == 1
    s.(name) = value;
    return;
end
if ~isfield(s, name) || ~isstruct(s.(name))
    s.(name) = struct();
end
s.(name) = setNestedField(s.(name), parts(2:end), value);
end

function point = newPoint(spec, value, displayValue)
point = struct( ...
    'parameterName', string(spec.parameter), ...
    'parameterValue', value, ...
    'parameterValueDisplay', displayValue, ...
    'parameterUnits', string(specValue(spec, 'units', "")), ...
    'modelResult', [], 'quality', struct(), 'termination', struct(), ...
    'fallback', struct(), 'execution', struct(), 'configuration', struct(), ...
    'status', "notRun", 'errorIdentifier', "", 'errorMessage', "", ...
    'elapsedSeconds', nan);
end

function point = completePoint(point, result)
point.modelResult = result;
point.quality = resultField(result, 'quality', struct());
point.termination = resultField(result, 'termination', struct());
point.fallback = resultField(result, 'fallback', struct());
point.execution = resultField(result, 'execution', struct());
point.configuration = resultField(result, 'configuration', struct());
point.status = "ok";
end

function validateModelResult(result)
if ~isstruct(result) || ~isfield(result, 'model')
    error('runParametricSweep:InvalidModelResult', ...
        'The evaluator must return a canonical model result.');
end
end

function request = requestedConfiguration(result)
request = [];
if isfield(result, 'configuration') && isstruct(result.configuration) && ...
        isfield(result.configuration, 'requested')
    request = result.configuration.requested;
end
end

function value = resultField(result, name, defaultValue)
value = defaultValue;
if isfield(result, name)
    value = result.(name);
end
end

function value = specValue(spec, name, defaultValue)
value = defaultValue;
if isstruct(spec) && isfield(spec, name) && ~isempty(spec.(name))
    value = spec.(name);
end
end
