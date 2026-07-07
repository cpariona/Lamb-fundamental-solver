function request = mrlfeBuildFitSolveRequest(params, frequency_Hz, branchName, solverOptions)
%MRLFEBUILDFITSOLVEREQUEST Map fitting inputs to the public mRLFE request.
%
% This helper performs only parameter and option translation. It does not run
% a solver, inspect GUI state, or participate in optimizer logic.

if nargin < 3 || isempty(branchName)
    branchName = "A0Like";
end
if nargin < 4 || isempty(solverOptions)
    solverOptions = struct();
end
if nargin < 1 || ~isstruct(params)
    error('mrlfe:InvalidFitParameters', 'mRLFE fit parameters must be a struct.');
end

branchName = string(branchName);
if ~(branchName == "A0Like" || branchName == "S0Like")
    error('mrlfe:InvalidBranch', 'Unsupported mRLFE fitting branch "%s".', branchName);
end

frequency_Hz = frequency_Hz(:);
if isempty(frequency_Hz) || any(~isfinite(frequency_Hz)) || any(frequency_Hz <= 0)
    error('mrlfe:InvalidFrequency', 'frequency_Hz must contain positive finite values.');
end
if any(diff(frequency_Hz) <= 0)
    error('mrlfe:InvalidFrequencyOrder', 'frequency_Hz must be strictly ascending.');
end

defaults = mrlfeDefaultParameters();
fitParams = normalizeFitParameters(params, solverOptions, defaults);

request = struct();
request.branch = branchName;
request.frequency_Hz = frequency_Hz;
request.material = struct( ...
    'mu_Pa', fitParams.mu_Pa, ...
    'etaS_Pas', fitParams.etaS_Pas, ...
    'rho_kgm3', fitParams.rho_kgm3, ...
    'nu', fitParams.nu);
request.geometry = struct('thickness_m', fitParams.thickness_m);
request.fluid = struct( ...
    'density_kgm3', fitParams.fluidDensity_kgm3, ...
    'soundSpeed_mps', fitParams.fluidSoundSpeed_mps);
request.numerics = struct('preset', resolveFitPreset(solverOptions));
request.selection = struct('strategy', "adaptive");
request.termination = struct('policy', terminationPolicyForBranch(branchName));
request.fallback = struct('policy', "none");
end

function out = normalizeFitParameters(params, options, defaults)
out = struct();
out.mu_Pa = getScalarAlias(params, ["mu_Pa", "mu"], defaults.mu_Pa, 'mrlfe:InvalidMaterial', 'mu');
out.etaS_Pas = getEtaS(params, options, defaults.etaS_Pas);
out.rho_kgm3 = getScalarAlias(params, ["rho_kgm3", "rho"], defaults.rho_kgm3, 'mrlfe:InvalidMaterial', 'rho');
out.nu = getScalarAlias(params, "nu", defaults.nu, 'mrlfe:InvalidMaterial', 'nu');
out.thickness_m = getScalarAlias(params, ["thickness_m", "thickness"], defaults.thickness_m, 'mrlfe:InvalidGeometry', 'thickness');
out.fluidDensity_kgm3 = getFluidScalar(params, options, ["fluidDensity_kgm3", "fluidDensity", "density_kgm3"], ...
    "fluidDensity", defaults.fluidDensity_kgm3, 'fluid density');
out.fluidSoundSpeed_mps = getFluidScalar(params, options, ["fluidSoundSpeed_mps", "fluidSoundSpeed", "soundSpeed_mps"], ...
    "fluidSoundSpeed", defaults.fluidSoundSpeed_mps, 'fluid sound speed');

validatePositive(out.mu_Pa, 'mrlfe:InvalidMaterial', 'mu');
validateNonnegative(out.etaS_Pas, 'mrlfe:InvalidMaterial', 'etaS');
validatePositive(out.rho_kgm3, 'mrlfe:InvalidMaterial', 'rho');
if ~(isfinite(out.nu) && out.nu > -1 && out.nu < 0.5)
    error('mrlfe:InvalidMaterial', 'nu must be finite and satisfy -1 < nu < 0.5.');
end
validatePositive(out.thickness_m, 'mrlfe:InvalidGeometry', 'thickness');
validatePositive(out.fluidDensity_kgm3, 'mrlfe:InvalidFluid', 'fluid density');
validatePositive(out.fluidSoundSpeed_mps, 'mrlfe:InvalidFluid', 'fluid sound speed');
end

function etaS = getEtaS(params, options, defaultValue)
etaS = getScalarAlias(params, ["etaS_Pas", "etaS"], [], 'mrlfe:InvalidMaterial', 'etaS');
if isempty(etaS) && isstruct(options) && isfield(options, 'mrlfeParams') && ...
        isstruct(options.mrlfeParams) && isfield(options.mrlfeParams, 'etaS') && ...
        ~isempty(options.mrlfeParams.etaS)
    etaS = options.mrlfeParams.etaS;
end
if isempty(etaS)
    etaS = defaultValue;
end
end

function value = getFluidScalar(params, options, paramAliases, optionField, defaultValue, label)
value = getScalarAlias(params, paramAliases, [], 'mrlfe:InvalidFluid', label);
if isempty(value) && isstruct(options) && isfield(options, 'mrlfeParams') && ...
        isstruct(options.mrlfeParams) && isfield(options.mrlfeParams, char(optionField)) && ...
        ~isempty(options.mrlfeParams.(char(optionField)))
    value = options.mrlfeParams.(char(optionField));
end
if isempty(value)
    value = defaultValue;
end
end

function value = getScalarAlias(s, names, defaultValue, errorId, label)
value = defaultValue;
for i = 1:numel(names)
    name = char(names(i));
    if isfield(s, name) && ~isempty(s.(name))
        candidate = s.(name);
        if ~isnumeric(candidate) || ~isscalar(candidate) || ~isfinite(candidate)
            error(errorId, '%s must be a finite scalar.', label);
        end
        value = candidate;
        return;
    end
end
end

function preset = resolveFitPreset(options)
if ~isstruct(options)
    preset = "fast";
    return;
end

if isfield(options, 'mrlfeUseFitAtlasPreset') && ~isempty(options.mrlfeUseFitAtlasPreset) && ...
        ~logical(options.mrlfeUseFitAtlasPreset)
    preset = "dense";
    return;
end

legacyPreset = "fast_fit_atlas";
if isfield(options, 'mrlfeFitAtlasPreset') && ~isempty(options.mrlfeFitAtlasPreset)
    legacyPreset = lower(string(options.mrlfeFitAtlasPreset));
elseif isfield(options, 'mrlfeFitPerformancePreset') && ~isempty(options.mrlfeFitPerformancePreset)
    legacyPreset = lower(string(options.mrlfeFitPerformancePreset));
end

switch legacyPreset
    case {"fast", "fast_fit_atlas", "fast_elastic_a0like", "maintained_default"}
        preset = "fast";
    case {"dense", "off", "reference", "maintained_dense"}
        preset = "dense";
    otherwise
        error('mrlfe:InvalidNumericalPreset', ...
            'Unsupported mRLFE fitting numerical preset "%s".', legacyPreset);
end
end

function policy = terminationPolicyForBranch(branchName)
switch string(branchName)
    case "A0Like"
        policy = "physicalTail";
    case "S0Like"
        policy = "none";
end
end

function validatePositive(value, errorId, label)
if ~(isnumeric(value) && isscalar(value) && isfinite(value) && value > 0)
    error(errorId, '%s must be a positive finite scalar.', label);
end
end

function validateNonnegative(value, errorId, label)
if ~(isnumeric(value) && isscalar(value) && isfinite(value) && value >= 0)
    error(errorId, '%s must be a nonnegative finite scalar.', label);
end
end
