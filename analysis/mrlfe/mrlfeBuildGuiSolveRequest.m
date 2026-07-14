function request = mrlfeBuildGuiSolveRequest(params, frequency_Hz, branchName, guiOptions)
%MRLFEBUILDGUISOLVEREQUEST Map Main GUI mRLFE state to the public request.
%
% This helper translates normalized adapter inputs only. It does not run a
% solver, inspect GUI handles, evaluate quality, or choose fallback behavior.

if nargin < 4 || isempty(guiOptions)
    guiOptions = struct();
end
if nargin < 3 || isempty(branchName)
    branchName = "A0Like";
end
if nargin < 1 || ~isstruct(params)
    error('mrlfe:InvalidGuiParameters', 'mRLFE GUI params must be a struct.');
end

branchName = string(branchName);
if ~(branchName == "A0Like" || branchName == "S0Like")
    error('mrlfe:InvalidBranch', 'Unsupported mRLFE GUI branch "%s".', branchName);
end

frequency_Hz = frequency_Hz(:);
if isempty(frequency_Hz) || any(~isfinite(frequency_Hz)) || any(frequency_Hz <= 0)
    error('mrlfe:InvalidFrequency', 'frequency_Hz must contain positive finite values.');
end
if any(diff(frequency_Hz) <= 0)
    error('mrlfe:InvalidFrequencyOrder', 'frequency_Hz must be strictly ascending.');
end

defaults = mrlfeDefaultParameters();

request = struct();
request.branch = branchName;
request.frequency_Hz = frequency_Hz;
request.material = struct( ...
    'mu_Pa', getScalarAlias(params, ["mu_Pa", "mu"], defaults.mu_Pa, 'mrlfe:InvalidMaterial', 'mu'), ...
    'etaS_Pas', getEtaS(params, guiOptions, defaults.etaS_Pas), ...
    'rho_kgm3', getScalarAlias(params, ["rho_kgm3", "rho"], defaults.rho_kgm3, 'mrlfe:InvalidMaterial', 'rho'), ...
    'nu', getScalarAlias(params, "nu", defaults.nu, 'mrlfe:InvalidMaterial', 'nu'));
request.geometry = struct( ...
    'thickness_m', getScalarAlias(params, ["thickness_m", "thickness"], defaults.thickness_m, 'mrlfe:InvalidGeometry', 'thickness'));
request.fluid = struct( ...
    'density_kgm3', getFluidScalar(params, guiOptions, ["fluidDensity_kgm3", "fluidDensity", "density_kgm3"], ...
    "fluidDensity", defaults.fluidDensity_kgm3, 'fluid density'), ...
    'soundSpeed_mps', getFluidScalar(params, guiOptions, ["fluidSoundSpeed_mps", "fluidSoundSpeed", "soundSpeed_mps"], ...
    "fluidSoundSpeed", defaults.fluidSoundSpeed_mps, 'fluid sound speed'));
request.numerics = struct('preset', "fast");
request.selection = struct('strategy', "adaptive");
request.termination = struct('policy', terminationPolicyForBranch(branchName));
request.fallback = struct('policy', "none");

validateRequestScalars(request);
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

function policy = terminationPolicyForBranch(branchName)
if string(branchName) == "A0Like"
    policy = "physicalTail";
else
    policy = "none";
end
end

function validateRequestScalars(request)
validatePositive(request.material.mu_Pa, 'mrlfe:InvalidMaterial', 'mu');
validateNonnegative(request.material.etaS_Pas, 'mrlfe:InvalidMaterial', 'etaS');
validatePositive(request.material.rho_kgm3, 'mrlfe:InvalidMaterial', 'rho');
if ~(isfinite(request.material.nu) && request.material.nu > -1 && request.material.nu < 0.5)
    error('mrlfe:InvalidMaterial', 'nu must be finite and satisfy -1 < nu < 0.5.');
end
validatePositive(request.geometry.thickness_m, 'mrlfe:InvalidGeometry', 'thickness');
validatePositive(request.fluid.density_kgm3, 'mrlfe:InvalidFluid', 'fluid density');
validatePositive(request.fluid.soundSpeed_mps, 'mrlfe:InvalidFluid', 'fluid sound speed');
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
