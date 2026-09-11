function [S, sensitivityInfo] = estimateLocalSensitivity(evaluateFcn, baseParams, freeParams, experimental, options)
%ESTIMATELOCALSENSITIVITY Estimate local Cp sensitivity to free parameters.
%
% evaluateFcn must accept a parameter structure and return Cp values on the
% same frequency grid as experimental.frequency_Hz. The sensitivity uses the
% same fixed experimental objective mask as the fit; central-difference
% perturbations are not allowed to lose required model points.

if nargin < 5 || isempty(options)
    options = struct();
end
if ~isfield(options, 'relativeStep') || isempty(options.relativeStep)
    options.relativeStep = 1e-6;
end
if ~isfield(options, 'absoluteStep') || isempty(options.absoluteStep)
    options.absoluteStep = 1e-9;
end

if ~isa(evaluateFcn, 'function_handle')
    error('evaluateFcn must be a function handle.');
end
if ~isstruct(baseParams) || ~isscalar(baseParams)
    error('baseParams must be a scalar structure.');
end

experimental = lamb.fitting.validateExperimentalDispersionData(experimental, 1);
freeParams = string(freeParams(:));
if isempty(freeParams)
    error('freeParams must contain at least one parameter name.');
end

baseCp = evaluateFcn(baseParams);
baseCp = baseCp(:);
[baseCoverage, experimental] = lamb.fitting.validateDispersionFitCoverage(baseCp, experimental);
objectiveMask = baseCoverage.objectiveMask;

S = nan(nnz(objectiveMask), numel(freeParams));
steps = nan(numel(freeParams), 1);

for j = 1:numel(freeParams)
    name = char(freeParams(j));
    if ~isfield(baseParams, name)
        error('baseParams is missing free parameter field: %s.', name);
    end

    theta0 = baseParams.(name);
    if ~isnumeric(theta0) || ~isscalar(theta0) || ~isfinite(theta0)
        error('Free parameter %s must be a finite scalar numeric value.', name);
    end

    step = max(abs(theta0) * options.relativeStep, options.absoluteStep);
    steps(j) = step;

    paramsPlus = baseParams;
    paramsMinus = baseParams;
    paramsPlus.(name) = theta0 + step;
    paramsMinus.(name) = theta0 - step;

    CpPlus = evaluateFcn(paramsPlus);
    CpMinus = evaluateFcn(paramsMinus);
    CpPlus = CpPlus(:);
    CpMinus = CpMinus(:);

    assertPerturbationCoverage(CpPlus, experimental, name, "positive");
    assertPerturbationCoverage(CpMinus, experimental, name, "negative");

    S(:, j) = (CpPlus(objectiveMask) - CpMinus(objectiveMask)) ./ (2 * step);
end

sensitivityInfo = struct();
sensitivityInfo.freeParams = freeParams;
sensitivityInfo.steps = steps;
sensitivityInfo.validMask = objectiveMask;
sensitivityInfo.objectiveMask = objectiveMask;
sensitivityInfo.numValidPoints = nnz(objectiveMask);
sensitivityInfo.expectedPointCount = baseCoverage.expectedPointCount;
sensitivityInfo.coverageAccepted = true;
sensitivityInfo.baseCp_mps = baseCp;
sensitivityInfo.baseCpValid_mps = baseCp(objectiveMask);
end

function assertPerturbationCoverage(Cp_mps, experimental, parameterName, direction)
try
    lamb.fitting.validateDispersionFitCoverage(Cp_mps, experimental);
catch ME
    if strcmp(ME.identifier, 'lamb:fitting:IncompleteModelCoverage')
        error('lamb:fitting:SensitivityIncompleteModelCoverage', ...
            'Sensitivity %s perturbation for %s lost objective coverage. %s', ...
            direction, parameterName, ME.message);
    end
    rethrow(ME);
end
end
