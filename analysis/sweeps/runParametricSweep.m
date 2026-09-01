function sweepResults = runParametricSweep(baseParams, baseOptions, sweepSpec)
%RUNPARAMETRICSWEEP Run a one-parameter sweep using the current solver.
%
% Required sweepSpec fields:
%   parameter : field name in params or options.mrlfeParams
%   values    : numeric vector of values in solver units
%
% Optional sweepSpec fields:
%   label, units, displayScale, displayValues

paramName = char(sweepSpec.parameter);
values = sweepSpec.values(:).';
n = numel(values);

if ~isfield(sweepSpec, 'label') || strlength(string(sweepSpec.label)) == 0
    sweepSpec.label = string(paramName);
end
if ~isfield(sweepSpec, 'units')
    sweepSpec.units = "";
end
if ~isfield(sweepSpec, 'displayScale') || isempty(sweepSpec.displayScale)
    sweepSpec.displayScale = 1;
end
if isfield(sweepSpec, 'displayValues') && ~isempty(sweepSpec.displayValues)
    displayValues = sweepSpec.displayValues(:).';
    if numel(displayValues) ~= n
        error('sweepSpec.displayValues must have the same number of entries as sweepSpec.values.');
    end
else
    displayValues = values ./ sweepSpec.displayScale;
end

sweepResults = struct();
sweepResults.spec = sweepSpec;
sweepResults.parameter = string(paramName);
sweepResults.values = values;
sweepResults.displayValues = displayValues;
sweepResults.results = cell(1, n);
sweepResults.params = cell(1, n);
sweepResults.options = cell(1, n);
sweepResults.elapsedSeconds = nan(1, n);

for i = 1:n
    params = baseParams;
    options = baseOptions;
    [params, options] = setSweepValue(params, options, paramName, values(i));

    t = tic;
    if isfield(options, 'modelFamily') && string(options.modelFamily) == "mrlfe"
        frequency_Hz = rlBuildFrequencyVector(params);
        branchName = string(options.branchName);
        request = mrlfeBuildPublicSolveRequest(params, frequency_Hz, branchName, ...
            struct('parameterOptions', options));
        result = mrlfeSolve(request);
    else
        result = rlComputeFundamentalLambModes(params, options);
    end

    sweepResults.results{i} = result;
    sweepResults.params{i} = params;
    sweepResults.options{i} = options;
    sweepResults.elapsedSeconds(i) = toc(t);

    fprintf('Sweep %s = %.6g complete in %.2f s (%d/%d).\n', ...
        paramName, values(i), sweepResults.elapsedSeconds(i), i, n);
end
end

function [params, options] = setSweepValue(params, options, paramName, value)
if isfield(params, paramName)
    params.(paramName) = value;
    return;
end

if ~isfield(options, 'mrlfeParams') || isempty(options.mrlfeParams)
    options.mrlfeParams = mrlfeDefaultInternalParameters();
end

if isfield(options.mrlfeParams, paramName)
    options.mrlfeParams.(paramName) = value;
    return;
end

error('Sweep parameter "%s" was not found in params or options.mrlfeParams.', paramName);
end
