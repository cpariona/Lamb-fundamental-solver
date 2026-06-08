function sweepResults = runParametricSweep(baseParams, baseOptions, sweepSpec)
% Run a compact one-parameter sweep using computeFundamentalLambModes.
% The swept parameter may be a params field or an options.mrlfeParams field.

if ~isfield(sweepSpec,'parameter') || ~isfield(sweepSpec,'values')
    error('sweepSpec must contain parameter and values.');
end

pname = char(sweepSpec.parameter);
values = sweepSpec.values(:).';
if isempty(values) || ~isnumeric(values)
    error('sweepSpec.values must be a non-empty numeric vector.');
end
if ~isfield(sweepSpec,'label'), sweep