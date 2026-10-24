function problem = rlBuildFitProblem(experimental, fitConfig)
%RLBUILDFITPROBLEM Build a Rayleigh-Lamb dispersion fitting problem.
%
% Required fitConfig fields:
%   freeParams
%
% Optional fitConfig fields:
%   branchName      default "A0"
%   fixedParams     fields overriding lamb.models.rayleigh_lamb.rlDefaultParams
%   initialGuess    fields for free-parameter initial guesses
%   bounds          fields with [lower upper] bounds
%   solverOptions   lamb.models.rayleigh_lamb.rlDefaultOptions-compatible options
%   fitOptions      residual options
%
% An explicit validMask is fixed: normalization may not deselect invalid data.
% Explicitly excluded nonpositive/nonfinite frequencies stay in the request
% but are not evaluated. Their predictions retain the original row positions.

if nargin < 2 || ~isstruct(fitConfig)
    error('fitConfig must be provided as a structure.');
end
if ~isfield(fitConfig, 'freeParams') || isempty(fitConfig.freeParams)
    error('fitConfig.freeParams is required.');
end
suppliedMask = [];
if isfield(experimental, 'validMask') && ~isempty(experimental.validMask)
    suppliedMask = logical(experimental.validMask(:));
end
experimental = lamb.fitting.validateExperimentalDispersionData(experimental, 1);
if ~isempty(suppliedMask) && ~isequal(suppliedMask, experimental.validMask)
    error('lamb:rl:InvalidSelectedObservation', ...
        'Selected observations require positive finite Hz and finite Cp; validMask cannot be repaired.');
end

branchName = lamb.fitting.getFitConfigValue(fitConfig, 'branchName', "A0");
branchName = string(branchName);

baseParams = lamb.models.rayleigh_lamb.rlDefaultParams();
baseParams = lamb.fitting.applyParameterOverrides(baseParams, ...
    lamb.fitting.getFitConfigValue(fitConfig, 'fixedParams', struct()));
baseParams = lamb.fitting.applyParameterOverrides(baseParams, ...
    lamb.fitting.getFitConfigValue(fitConfig, 'initialGuess', struct()));

freeParams = string(fitConfig.freeParams(:));
[x0, parameterInfo] = lamb.fitting.buildParameterVector(baseParams, freeParams);

bounds = lamb.fitting.getFitConfigValue(fitConfig, 'bounds', struct());
[lowerBounds, upperBounds] = lamb.fitting.buildParameterBounds(bounds, freeParams);
lamb.models.rayleigh_lamb.rlValidateParams(baseParams);
nuIndex = freeParams == "nu";
if any(lowerBounds(nuIndex) < 0.49 | upperBounds(nuIndex) >= 0.5 | ...
        ~isfinite(lowerBounds(nuIndex)) | ~isfinite(upperBounds(nuIndex)))
    error('lamb:rl:UnsupportedPoissonRatio', ...
        'Free nu bounds must lie entirely inside 0.49 <= nu < 0.5.');
end

solverOptions = lamb.fitting.getFitConfigValue(fitConfig, 'solverOptions', lamb.models.rayleigh_lamb.rlDefaultOptions("Fast"));
fitOptions = lamb.fitting.getFitConfigValue(fitConfig, 'fitOptions', struct());
if ~isfield(fitOptions, 'useStandardErrorWeights')
    fitOptions.useStandardErrorWeights = false;
end
if isfield(fitOptions, 'minValidFraction') && ~isempty(fitOptions.minValidFraction)
    if ~isscalar(fitOptions.minValidFraction) || ~isfinite(fitOptions.minValidFraction) || fitOptions.minValidFraction ~= 1
        error('lamb:fitting:PartialCoverageNotSupported', ...
            ['Rayleigh-Lamb fitting no longer permits partial objective coverage. ' ...
             'Remove fitOptions.minValidFraction or set it to 1.']);
    end
    fitOptions = rmfield(fitOptions, 'minValidFraction');
end

problem = struct();
problem.modelFamily = "rayleigh_lamb";
problem.branchName = branchName;
problem.experimental = experimental;
problem.baseParams = baseParams;
problem.freeParams = freeParams;
problem.x0 = x0;
problem.lowerBounds = lowerBounds;
problem.upperBounds = upperBounds;
problem.parameterInfo = parameterInfo;
problem.solverOptions = solverOptions;
problem.fitOptions = fitOptions;
problem.optimizerOptions = struct( ...
    'fminbnd', optimset('Display', 'off', 'MaxIter', 80, ...
        'MaxFunEvals', 160, 'TolX', 1e-6), ...
    'fminsearch', optimset('Display', 'off', 'MaxIter', 80, ...
        'MaxFunEvals', 220, 'TolX', 1e-6, 'TolFun', 1e-8));
frequency = experimental.frequency_Hz;
admissible = isfinite(frequency) & frequency > 0;
if ~all(admissible) && isempty(suppliedMask)
    error('lamb:rl:InvalidSelectedObservation', ...
        'Nonpositive/nonfinite Hz require explicit validMask=false; exclusions are not inferred.');
end
if all(admissible)
    problem.evaluateModel = @(params) lamb.fitting.rayleigh_lamb.rlEvaluateFitModel(params, frequency, branchName, solverOptions);
else
    problem.evaluateModel = @(params) localEvaluateExcludedRows(params, frequency, admissible, branchName, solverOptions);
end
problem.residualFunction = @(x) localResidualFunction(x, problem);
problem.objectiveFunction = @(x) lamb.fitting.evaluateBoundedObjective(x, problem);
end

function [Cp_mps, rawResult] = localEvaluateExcludedRows(params, frequency, admissible, branchName, options)
[values, rawResult] = lamb.fitting.rayleigh_lamb.rlEvaluateFitModel( ...
    params, frequency(admissible), branchName, options);
Cp_mps = nan(size(frequency));
Cp_mps(admissible) = values;
% Only observation-aligned arrays are expanded. Official modelResult and
% diagnostics retain the canonical solver's own positive, unique grid.
for name = ["Cp_mps", "k", "kThickness", "residual"]
    expanded = nan(size(frequency));
    expanded(admissible) = rawResult.(name);
    rawResult.(name) = expanded;
end
available = false(size(admissible));
available(admissible) = rawResult.validMask;
rawResult.frequency_Hz = frequency;
rawResult.omega = 2*pi*frequency;
rawResult.validMask = available;
rawResult.evaluatedObservationMask = admissible;
% These counts describe prediction availability on the full original axis,
% including unevaluated exclusions; objective coverage is reported separately.
rawResult.reliability.ValidFraction = mean(available);
rawResult.reliability.ValidPoints = nnz(available);
rawResult.reliability.MissingPoints = nnz(~available);
end

function residuals = localResidualFunction(x, problem)
params = lamb.fitting.unpackParameterVector(x, problem.baseParams, problem.freeParams);
CpModel_mps = problem.evaluateModel(params);
residuals = lamb.fitting.computeDispersionFitResiduals(CpModel_mps, problem.experimental, problem.fitOptions);
end
