function results = rlComputeFundamentalLambModes(params, options)
%RLCOMPUTEFUNDAMENTALLAMBMODES Public Rayleigh-Lamb solver entrypoint.
%   RESULTS = RLCOMPUTEFUNDAMENTALLAMBMODES(PARAMS, OPTIONS) solves the
%   enabled fundamental A0/S0 branches of an isotropic elastic plate.
%   PARAMS uses SI units and full physical thickness; obtain defaults with
%   rlDefaultParams. OPTIONS controls branches and numerical effort; obtain
%   a Fast, Balanced, or Robust configuration with rlDefaultOptions.
%   Production support is 0.49 <= effective nu < 0.5, also for Lamé input.
%   Material values are never clipped. Requested frequencies do not select
%   branch identity; local corrections consume model-owned continuation.
%
%   Enabled result modes expose column vectors frequency_Hz,
%   phaseVelocity_mps, wavenumber_radpm, and validMask. Invalid phase speed
%   is NaN. The result also records material, geometry, quality, diagnostics,
%   execution evidence, and requested/effective configuration.

timerStart = tic;
lamb.models.rayleigh_lamb.rlValidateParams(params);
rlValidateOptions(options);

material = lamb.models.rayleigh_lamb.rlComputeMaterial(params);
geometry = lamb.models.rayleigh_lamb.rlComputeGeometry(params);
frequency = lamb.grids.buildFrequencyVector(params);
omega = 2 * pi * frequency;

modes = struct();
publicGeometry = rmfield(geometry, 'halfThickness');
approximations = lamb.models.rayleigh_lamb.approximations.rlComputeAnalyticalApproximations(frequency, material, publicGeometry);

if options.computeA0
    branchSpecA = lamb.models.rayleigh_lamb.rlMakeBranchSpec("A0", material, geometry);

    [CpA0, residualA0] = lamb.models.rayleigh_lamb.rlSolveFundamentalBranch(frequency, branchSpecA, options);
    kA0 = omega ./ CpA0;

    modes.A0 = packModeResults("A0", branchSpecA.family, frequency, omega, CpA0, kA0, geometry.thickness, residualA0);
end
if options.computeS0
    branchSpecS = lamb.models.rayleigh_lamb.rlMakeBranchSpec("S0", material, geometry);

    [CpS0, residualS0] = lamb.models.rayleigh_lamb.rlSolveFundamentalBranch(frequency, branchSpecS, options);
    kS0 = omega ./ CpS0;

    modes.S0 = packModeResults("S0", branchSpecS.family, frequency, omega, CpS0, kS0, geometry.thickness, residualS0);
end
elapsedSeconds = toc(timerStart);
results = rlBuildResult(params, options, material, geometry, frequency, modes, approximations, elapsedSeconds);
end

function mode = packModeResults(name, family, frequency, omega, Cp, k, thickness, residual)
mode = struct( ...
    'name', name, ...
    'family', family, ...
    'frequency_Hz', frequency(:), ...
    'phaseVelocity_mps', Cp(:), ...
    'wavenumber_radpm', k(:), ...
    'validMask', isfinite(Cp(:)), ...
    'angularFrequency_radps', omega(:), ...
    'wavenumberThickness', k(:) * thickness, ...
    'diagnostics', struct('residual', residual(:)));
mode.diagnostics.residualMeaning = "relativeNewtonCorrection";
reason = repmat("rootNotEstablished", numel(Cp), 1);
reason(isfinite(Cp)) = "regularRootEstablished";
mode.diagnostics.reason = reason;
end


function result = rlBuildResult(params, options, material, geometry, frequency_Hz, modes, approximations, elapsedSeconds)
%RLBUILDRESULT Construct the canonical Rayleigh-Lamb scientific result.

result = struct();
result.model = "rayleigh_lamb";
result.modes = modes;
result.approximations = approximations;
result.quality = rlEvaluateModeQuality(modes);
result.material = material;
result.geometry = rmfield(geometry, 'halfThickness');

effectiveParameters = params;
effectiveParameters.frequency_Hz = frequency_Hz(:);
result.configuration = struct( ...
    'requested', struct('parameters', params, 'options', options), ...
    'effective', struct( ...
        'parameters', effectiveParameters, ...
        'options', options));
result.execution = struct( ...
    'engine', "independent_continuation", ...
    'elapsedSeconds', elapsedSeconds, ...
    'computedBranches', string(fieldnames(modes)).');
result.diagnostics = struct( ...
    'angularFrequency_radps', 2*pi*frequency_Hz(:));
end

function quality = rlEvaluateModeQuality(modes)
%RLEVALUATEMODEQUALITY Assess canonical Rayleigh-Lamb branch quality.

quality = struct();
names = fieldnames(modes);
for i = 1:numel(names)
    branch = modes.(names{i});
    valid = logical(branch.validMask(:)) & isfinite(branch.phaseVelocity_mps(:));
    pointCount = numel(valid);
    validCount = nnz(valid);
    accepted = all(valid);
    if accepted
        reason = "accepted";
    elseif validCount == 0
        reason = "no_valid_points";
    else
        reason = "incomplete_branch";
    end
    quality.(names{i}) = struct( ...
        'pointCount', pointCount, ...
        'validCount', validCount, ...
        'validFraction', validCount / max(pointCount, 1), ...
        'accepted', accepted, ...
        'reason', reason);
end
end

function rlValidateOptions(options)
% Validate numerical and mode-selection options before running the solver.

requiredFields = {'computeA0', 'computeS0', 'gridPointsInitial', ...
    'gridPointsTracking', 'jumpTol', 'residualTolerance'};
for i = 1:numel(requiredFields)
    if ~isfield(options, requiredFields{i})
        error('Missing required option field: %s.', requiredFields{i});
    end
end

if ~logical(options.computeA0) && ~logical(options.computeS0)
    error('At least one mode must be selected: computeA0 or computeS0.');
end

if options.gridPointsInitial < 100
    error('gridPointsInitial must be at least 100.');
end

if options.gridPointsTracking < 100
    error('gridPointsTracking must be at least 100.');
end

if options.jumpTol <= 0
    error('jumpTol must be positive.');
end

if options.residualTolerance <= 0
    error('residualTolerance must be positive.');
end

if isfield(options, 'searchFactors')
    if size(options.searchFactors, 2) ~= 2 || any(options.searchFactors(:) <= 0)
        error('searchFactors must be an n-by-2 matrix with positive values.');
    end
    if any(options.searchFactors(:, 2) <= options.searchFactors(:, 1))
        error('Each searchFactors upper bound must be larger than the lower bound.');
    end
end

if isfield(options, 'minCpAbsolute') && options.minCpAbsolute <= 0
    error('minCpAbsolute must be positive.');
end

if isfield(options, 'minCpRelativeToCT') && options.minCpRelativeToCT <= 0
    error('minCpRelativeToCT must be positive.');
end

if isfield(options, 'maxCpFactorCT') && options.maxCpFactorCT <= 0
    error('maxCpFactorCT must be positive.');
end

if isfield(options, 'minCpGlobalMax') && options.minCpGlobalMax <= 0
    error('minCpGlobalMax must be positive.');
end
end
