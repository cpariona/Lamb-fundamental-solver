function sweepResult = runAcoustoelasticSensitivity(baseParams, sweepField, sweepValues, options, sweepConfig)
%AERUNSWEEP Run a maintained AE IOP/HGO one-dimensional parameter sweep.
%
% The returned structure is the canonical runParametricSweep result. AE-only
% summaries and plotting are derived from this result by analysis helpers.

if nargin < 4 || isempty(options)
    options = lamb.models.acoustoelastic_iop_hgo.defaultAcoustoelasticIOPHGOOptions();
end
if nargin < 5 || isempty(sweepConfig)
    sweepConfig = struct();
end

sweepField = string(sweepField);
sweepValues = sweepValues(:).';
sweepConfig = fillSweepConfigDefaults(sweepConfig, sweepField);

spec = struct( ...
    'parameter', sweepField, ...
    'parameterPath', "params." + sweepField, ...
    'values', sweepValues, ...
    'name', string(sweepConfig.Name), ...
    'label', string(sweepConfig.Label), ...
    'units', string(sweepConfig.Unit), ...
    'displayScale', sweepConfig.ValueScale, ...
    'valueFormatter', string(sweepConfig.ValueFormatter));

sweepResult = lamb.sweeps.runParametricSweep(baseParams, options, spec, ...
    @(params, pointOptions)lamb.models.acoustoelastic_iop_hgo.solveAcoustoelasticIOPHGOBranch(params, pointOptions));
end

function sweepConfig = fillSweepConfigDefaults(sweepConfig, sweepField)
if ~isfield(sweepConfig, 'Name') || isempty(sweepConfig.Name)
    sweepConfig.Name = char(sweepField);
end
if ~isfield(sweepConfig, 'Label') || isempty(sweepConfig.Label)
    sweepConfig.Label = char(sweepField);
end
if ~isfield(sweepConfig, 'Unit') || isempty(sweepConfig.Unit)
    sweepConfig.Unit = '';
end
if ~isfield(sweepConfig, 'ValueScale') || isempty(sweepConfig.ValueScale)
    sweepConfig.ValueScale = 1;
end
if ~isfield(sweepConfig, 'ValueFormatter') || isempty(sweepConfig.ValueFormatter)
    sweepConfig.ValueFormatter = '%.6g';
end
end
