function guiResult = guiBuildModelResultView(modelResult, adapterName)
%GUIBUILDMODELRESULTVIEW Build a shallow display view from a canonical result.
%
% This adapter copies canonical scientific arrays into the long-lived GUI
% presentation shape, including dimensionless plot coordinates derived from
% canonical geometry. It does not inspect solver internals or run a solver.

if nargin < 2 || strlength(string(adapterName)) == 0
    adapterName = "guiBuildModelResultView";
end
if nargin < 1 || ~isstruct(modelResult) || ~isfield(modelResult, 'model')
    error('guiBuildModelResultView:InvalidInput', 'Expected a canonical model result struct.');
end

switch string(modelResult.model)
    case "rayleigh_lamb"
        branches = normalizeRLBranches(modelResult);
        modelName = "RayleighLamb";
    case "mrlfe"
        branches = normalizeBranch(modelResult, "mRLFERealK", modelResult.branch);
        modelName = "mRLFE";
    case "acoustoelastic_iop_hgo"
        branches = normalizeBranch(modelResult, "AcoustoelasticIOPHGO", modelResult.branch);
        modelName = "AcoustoelasticIOPHGO";
    otherwise
        error('guiBuildModelResultView:UnsupportedModel', ...
            'Unsupported canonical model result "%s".', string(modelResult.model));
end

guiResult = struct();
guiResult.modelName = modelName;
if numel(branches) == 1
    guiResult.branchName = branches.branchName;
    guiResult.frequency = branches.frequency;
    guiResult.phaseVelocity = branches.phaseVelocity;
    guiResult.wavenumber = branches.wavenumber;
    guiResult.kThickness = branches.kThickness;
else
    guiResult.branchName = "";
    guiResult.frequency = firstBranchFrequency(branches);
    guiResult.phaseVelocity = [];
    guiResult.wavenumber = [];
    guiResult.kThickness = [];
end
guiResult.branches = branches;
guiResult.metadata = struct('modelResult', modelResult, 'adapter', string(adapterName));
guiResult.diagnostics = struct('branchCount', numel(branches));
end

function branches = normalizeRLBranches(result)
branches = repmat(emptyBranch(), 0, 1);
names = string(fieldnames(result.modes));
for i = 1:numel(names)
    name = names(i);
    branches(end+1, 1) = normalizeBranch(result.modes.(char(name)), ...
        "RayleighLamb", name); %#ok<AGROW>
end
end

function branch = normalizeBranch(source, modelName, branchName)
branch = emptyBranch();
branch.modelName = string(modelName);
branch.rawModelName = string(modelName);
branch.branchName = string(branchName);
branch.frequency = source.frequency_Hz(:);
branch.phaseVelocity = source.phaseVelocity_mps(:);
branch.wavenumber = source.wavenumber_radpm(:);
if isfield(source, 'wavenumberThickness')
    branch.kThickness = source.wavenumberThickness(:);
else
    branch.kThickness = branch.wavenumber * resolveThickness(source);
end
branch.metadata = struct('modelResult', source, 'units', defaultUnits());
branch.diagnostics = struct('valid', logical(source.validMask(:)));
if isfield(source, 'diagnostics')
    branch.diagnostics.model = source.diagnostics;
end
end

function thickness = resolveThickness(source)
thickness = nan;
if ~isfield(source, 'configuration') || ~isstruct(source.configuration) || ...
        ~isfield(source.configuration, 'effective') || ...
        ~isstruct(source.configuration.effective) || ...
        ~isfield(source.configuration.effective, 'parameters') || ...
        ~isstruct(source.configuration.effective.parameters)
    return;
end
parameters = source.configuration.effective.parameters;
if isfield(parameters, 'thickness_m') && ~isempty(parameters.thickness_m)
    thickness = parameters.thickness_m;
elseif isfield(parameters, 'thickness') && ~isempty(parameters.thickness)
    thickness = parameters.thickness;
end
end

function branch = emptyBranch()
branch = struct('modelName', "", 'rawModelName', "", 'branchName', "", ...
    'frequency', [], 'phaseVelocity', [], 'wavenumber', [], 'kThickness', [], ...
    'metadata', struct(), 'diagnostics', struct());
end

function frequency = firstBranchFrequency(branches)
if isempty(branches)
    frequency = [];
else
    frequency = branches(1).frequency;
end
end

function units = defaultUnits()
units = struct('frequency', 'Hz', 'phaseVelocity', 'm/s', ...
    'wavenumber', 'rad/m', 'kThickness', 'dimensionless');
end
