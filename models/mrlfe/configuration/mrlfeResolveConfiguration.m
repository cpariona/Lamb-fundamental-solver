function configuration = mrlfeResolveConfiguration(request)
%MRLFERESOLVECONFIGURATION Merge, validate, and resolve an mRLFE request.

if nargin < 1 || isempty(request)
    request = struct();
end
if ~isstruct(request)
    error('mrlfe:InvalidRequest', 'mRLFE request must be a struct.');
end

resolvedRequest = mergeRequestWithDefaults(request);
mrlfeValidateRequest(resolvedRequest);

defaultOptions = mrlfeDefaultOptions();
preset = mrlfeGetNumericalPreset(resolvedRequest.numerics.preset);
etaS = resolvedRequest.material.etaS_Pas;

configuration = struct();
configuration.model = "mrlfe";
configuration.branch = string(resolvedRequest.branch);
configuration.materialRegime = ternary(etaS > 0, "viscoelastic", "elasticZeroViscosity");
configuration.requestedPreset = string(resolvedRequest.numerics.preset);
configuration.effectivePreset = preset.name;
configuration.numericalPreset = preset;
configuration.selectionStrategy = string(resolvedRequest.selection.strategy);
configuration.terminationPolicy = string(resolvedRequest.termination.policy);
configuration.fallbackPolicy = string(resolvedRequest.fallback.policy);
configuration.internalEngine = ternary(etaS > 0, "viscoelastic_adaptive", "elastic_adaptive");
configuration.request = resolvedRequest;
configuration.parameters = publicParametersFromRequest(resolvedRequest);
configuration.solverParams = buildSolverParams(resolvedRequest);
configuration.internalOptions = buildInternalOptions(resolvedRequest, preset);
configuration.qualityOptions = defaultOptions.quality;
configuration.public = struct( ...
    'requested', request, ...
    'effective', struct( ...
        'branch', configuration.branch, ...
        'materialRegime', configuration.materialRegime, ...
        'parameters', configuration.parameters, ...
        'frequency_Hz', resolvedRequest.frequency_Hz(:), ...
        'numerics', resolvedRequest.numerics, ...
        'selection', resolvedRequest.selection, ...
        'termination', resolvedRequest.termination, ...
        'fallback', resolvedRequest.fallback, ...
        'numericalPreset', preset, ...
        'internalEngine', configuration.internalEngine));
end

function requestOut = mergeRequestWithDefaults(requestIn)
defaults = mrlfeDefaultParameters();
defaultOptions = mrlfeDefaultOptions();

requestOut = requestIn;
if ~isfield(requestOut, 'branch') || isempty(requestOut.branch)
    requestOut.branch = "A0Like";
end

if ~isfield(requestOut, 'material') || ~isstruct(requestOut.material)
    requestOut.material = struct();
end
requestOut.material = setDefault(requestOut.material, 'mu_Pa', defaults.mu_Pa);
requestOut.material = setDefault(requestOut.material, 'etaS_Pas', defaults.etaS_Pas);
requestOut.material = setDefault(requestOut.material, 'rho_kgm3', defaults.rho_kgm3);
requestOut.material = setDefault(requestOut.material, 'nu', defaults.nu);

if ~isfield(requestOut, 'geometry') || ~isstruct(requestOut.geometry)
    requestOut.geometry = struct();
end
requestOut.geometry = setDefault(requestOut.geometry, 'thickness_m', defaults.thickness_m);

if ~isfield(requestOut, 'fluid') || ~isstruct(requestOut.fluid)
    requestOut.fluid = struct();
end
requestOut.fluid = setDefault(requestOut.fluid, 'density_kgm3', defaults.fluidDensity_kgm3);
requestOut.fluid = setDefault(requestOut.fluid, 'soundSpeed_mps', defaults.fluidSoundSpeed_mps);

requestOut.numerics = mergeStructField(requestOut, 'numerics', defaultOptions.numerics);
requestOut.selection = mergeStructField(requestOut, 'selection', defaultOptions.selection);
requestOut.fallback = mergeStructField(requestOut, 'fallback', defaultOptions.fallback);

if ~isfield(requestOut, 'termination') || ~isstruct(requestOut.termination)
    requestOut.termination = struct();
end
if ~isfield(requestOut.termination, 'policy') || isempty(requestOut.termination.policy)
    branch = string(requestOut.branch);
    if branch == "A0Like"
        requestOut.termination.policy = defaultOptions.termination.A0Like;
    else
        requestOut.termination.policy = defaultOptions.termination.S0Like;
    end
end
end

function s = setDefault(s, fieldName, defaultValue)
if ~isfield(s, fieldName) || isempty(s.(fieldName))
    s.(fieldName) = defaultValue;
end
end

function out = mergeStructField(parent, fieldName, defaults)
if isfield(parent, fieldName) && isstruct(parent.(fieldName))
    out = parent.(fieldName);
else
    out = struct();
end
names = fieldnames(defaults);
for i = 1:numel(names)
    out = setDefault(out, names{i}, defaults.(names{i}));
end
end

function params = publicParametersFromRequest(request)
params = mrlfeDefaultParameters();
params.mu_Pa = request.material.mu_Pa;
params.etaS_Pas = request.material.etaS_Pas;
params.rho_kgm3 = request.material.rho_kgm3;
params.nu = request.material.nu;
params.thickness_m = request.geometry.thickness_m;
params.fluidDensity_kgm3 = request.fluid.density_kgm3;
params.fluidSoundSpeed_mps = request.fluid.soundSpeed_mps;
end

function params = buildSolverParams(request)
params = struct( ...
    'modelType', "ShearPoisson", ...
    'mu', request.material.mu_Pa, ...
    'etaS', request.material.etaS_Pas, ...
    'rho', request.material.rho_kgm3, ...
    'nu', request.material.nu, ...
    'thickness', request.geometry.thickness_m, ...
    'fmin', request.frequency_Hz(1), ...
    'fmax', request.frequency_Hz(end), ...
    'numFrequencyPoints', numel(request.frequency_Hz), ...
    'frequencySpacing', "linspace");
end

function options = buildInternalOptions(request, preset)
branch = string(request.branch);
etaS = request.material.etaS_Pas;
options = struct( ...
    'residualTolerance', 1e-4, ...
    'residualMethod', "minSingularValueRatio", ...
    'residualFloor', 1e-14, ...
    'trackerEdgeGuardPoints', 8);
options.mrlfeParams = mrlfeDefaultInternalParameters();
options.mrlfeParams.fluidDensity = request.fluid.density_kgm3;
options.mrlfeParams.fluidSoundSpeed = request.fluid.soundSpeed_mps;
options.mrlfeParams.etaS = etaS;
options.mrlfeParams.etaL = 0;
options.mrlfeParams.useComplexLambda = false;
options.mrlfeParams.solveComplexK = false;
options.trackerCpScanPoints = preset.scanPoints;
options.trackerCandidateCount = preset.candidateCount;
options.trackerRefineCandidates = preset.refineCandidates;
options.trackerWindows = preset.adaptiveWindows;
options.robustStartEnabled = branch == "A0Like";
options.robustStartCandidateFrequencies_Hz = [75 100 150 200 300 500 750 1000];
options.robustStartMinValidRun = 8;
options.robustStartMaxCandidates = 8;

end

function out = ternary(condition, a, b)
if condition
    out = a;
else
    out = b;
end
end
