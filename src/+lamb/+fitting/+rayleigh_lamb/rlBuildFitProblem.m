function problem = rlBuildFitProblem(experimental, fitConfig)
%RLBUILDFITPROBLEM Build a Rayleigh-Lamb dispersion fitting problem.
%
% Required fitConfig fields:
%   freeParams
%
% Optional fitConfig fields:
%   branchName      default "A0"
%   fixedParams     density_kgpm3 (kg/m^3), thickness_m (full current m),
%                   poisson_ratio (dimensionless); legacy solver names remain
%                   accepted for existing callers, but cannot be mixed.
%   initialGuess    fields for free-parameter initial guesses
%   bounds          fields with [lower upper] bounds
%   solverOptions   lamb.models.rayleigh_lamb.rlDefaultOptions-compatible options
%   fitOptions      residual options
% EXPERIMENTAL may carry observationThickness_m: positive current full thickness
% per original observation, in m. Same-thickness rows share one canonical solve;
% no thickness interpolation, averaging, rounding or fitted thickness is used.
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
fixed = lamb.fitting.getFitConfigValue(fitConfig, 'fixedParams', struct());
% Public fitting requests use unit-qualified SI names. Preserve the existing
% model's rho/thickness/nu mathematics and legacy solver configurations.
siNames = ["density_kgpm3", "thickness_m", "poisson_ratio"];
modelNames = ["rho", "thickness", "nu"];
for j = 1:numel(siNames)
    publicName = char(siNames(j)); modelName = char(modelNames(j));
    if isfield(fixed, publicName)
        assert(~isfield(fixed, modelName), 'lamb:rl:AmbiguousPhysicalInput', ...
            'Do not mix unit-qualified and legacy names for the same physical input.');
        fixed.(modelName) = fixed.(publicName);
        fixed = rmfield(fixed, publicName);
    end
end
baseParams = lamb.fitting.applyParameterOverrides(baseParams, fixed);
baseParams = lamb.fitting.applyParameterOverrides(baseParams, ...
    lamb.fitting.getFitConfigValue(fitConfig, 'initialGuess', struct()));

observationThickness = [];
if isfield(experimental, 'observationThickness_m')
    observationThickness = experimental.observationThickness_m;
    if ~isa(observationThickness, 'double') || ~isvector(observationThickness) || ...
            numel(observationThickness) ~= numel(experimental.frequency_Hz)
        error('lamb:rl:ObservationThickness', ...
            'Observation thickness must be one double in meters per original row.');
    end
    observationThickness = observationThickness(:);
    experimental.observationThickness_m = observationThickness;
    admissibleThickness = isfinite(experimental.frequency_Hz) & experimental.frequency_Hz > 0;
    if any(~isfinite(observationThickness(admissibleThickness)) | ...
            observationThickness(admissibleThickness) <= 0)
        error('lamb:rl:ObservationThickness', ...
            'Every positive-frequency observation requires its recorded positive finite thickness.');
    end
    % The scalar parameter remains a non-operative reference for existing
    % material validation/reporting; evaluation uses each observation's h.
    baseParams.thickness = observationThickness(find(admissibleThickness, 1));
end

freeParams = string(fitConfig.freeParams(:));
if ~isempty(observationThickness) && any(freeParams == "thickness")
    error('lamb:rl:ThicknessConflict', ...
        'Cannot fit a single scalar thickness while using measured per-observation thickness.');
end
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
if ~isempty(observationThickness)
    problem.evaluateModel = @(params) localEvaluateObservationThickness( ...
        params, frequency, observationThickness, admissible, branchName, solverOptions);
elseif all(admissible)
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

function [Cp_mps, rawResult] = localEvaluateObservationThickness(params, frequency, thickness, admissible, branch, options)
% Evaluate exact recorded thickness groups with the same canonical solver.
% Each group uses its complete original positive-frequency grid and branch.
n = numel(frequency);
Cp_mps = nan(n,1); k = Cp_mps; kThickness = Cp_mps; residual = Cp_mps;
available = false(n,1);
groupThickness = unique(thickness(admissible),'stable');
groupResults = repmat(struct('thickness_m',NaN,'observationRows',[], ...
    'modelResult',[],'diagnostics',[]),numel(groupThickness),1);
for j = 1:numel(groupThickness)
    rows = find(admissible & thickness == groupThickness(j));
    current = params;
    current.thickness = groupThickness(j);
    [predicted, native] = lamb.fitting.rayleigh_lamb.rlEvaluateFitModel( ...
        current, frequency(rows), branch, options);
    Cp_mps(rows) = predicted;
    k(rows) = native.k;
    kThickness(rows) = native.kThickness;
    residual(rows) = native.residual;
    available(rows) = native.validMask;
    groupResults(j) = struct('thickness_m',groupThickness(j), ...
        'observationRows',rows,'modelResult',native.modelResult, ...
        'diagnostics',native.diagnostics);
    if j == 1
        rawResult = native;
    end
end
rawResult.frequency_Hz = frequency;
rawResult.Cp_mps = Cp_mps;
rawResult.omega = 2*pi*frequency;
rawResult.k = k;
rawResult.kThickness = kThickness;
rawResult.residual = residual;
rawResult.validMask = available;
rawResult.evaluatedObservationMask = admissible;
rawResult.observationThickness_m = thickness;
rawResult.trackingMode = "canonical_public_solver_by_thickness";
rawResult.geometry = []; % No single geometric thickness describes these solves.
rawResult.modelResult = []; % Official solver products are retained per group.
rawResult.modelResultsByThickness = groupResults;
rawResult.diagnostics = struct('thicknessPolicy',"per_observation_current_thickness", ...
    'groupCount',numel(groupResults), ...
    'groupThickness_m',groupThickness);
rawResult.reliability.ValidFraction = mean(available);
rawResult.reliability.ValidPoints = nnz(available);
rawResult.reliability.MissingPoints = nnz(~available);
end

function residuals = localResidualFunction(x, problem)
params = lamb.fitting.unpackParameterVector(x, problem.baseParams, problem.freeParams);
CpModel_mps = problem.evaluateModel(params);
residuals = lamb.fitting.computeDispersionFitResiduals(CpModel_mps, problem.experimental, problem.fitOptions);
end
