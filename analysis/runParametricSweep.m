function sweepResults = runParametricSweep(baseParams, baseOptions, sweepSpec)
% Run a compact one-parameter sweep using computeFundamentalLambModes.
% Supported parameters: any field in params, or any field in options.mrlfeParams.

if ~isfield(sweepSpec,'parameter') || ~isfield(sweepSpec,'values')
    error('sweepSpec must contain parameter and values.');
end

pname = char(sweepSpec.parameter);
values = sweepSpec.values(:).';
if ~isfield(sweepSpec,'label'), sweepSpec.label = pname; end
if ~isfield(sweepSpec,'units'), sweepSpec.units = ''; end
if ~isfield(sweepSpec,'scale'), sweepSpec