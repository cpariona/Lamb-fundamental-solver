function sweepResults = runParametricSweep(baseParams, baseOptions, sweepSpec)
% Run a one-parameter sweep using computeFundamentalLambModes.
% The swept parameter may be a field in params or in options.mrlfeParams.

if ~isfield(sweepSpec,'parameter') || ~isfield(sweepSpec,'values')
    error('sweepSpec must contain parameter and values.');
end

parameter = string(sweepSpec.parameter);