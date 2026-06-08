function sweepResults = runParametricSweep(baseParams, baseOptions, sweepSpec)
% Run a one-parameter sweep using computeFundamentalLambModes.
% sweepSpec.parameter can target params fields or mRLFE fields.

if ~isfield(sweepSpec,'parameter') || ~isfield(sweepSpec,'values')
    error('sweepSpec must contain parameter and values.');
end

parameter = string(sweepSpec.parameter);
values = sweepSpec.values(:).';
if isempty(values) || ~isnumeric(values)
    error('sweepSpec.values must be a non-empty numeric vector.');
end

if ~isfield(sweepSpec,'label'), sweepSpec.label = char(parameter); end
if ~isfield(sweepSpec,'units'), sweepSpec.units = ''; end
if ~isfield(sweepSpec,'scale'), sweepSpec.scale = 1; end
if ~isfield(sweepSpec,'verbose'), sweepSpec.verbose = true; end

nCases = numel(values);
caseResults = cell(1,nCases);
caseParams = cell(1,nCases);
