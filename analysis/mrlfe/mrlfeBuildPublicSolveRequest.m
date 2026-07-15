function request = mrlfeBuildPublicSolveRequest(source, frequency_Hz, branchName, policy)
%MRLFEBUILDPUBLICSOLVEREQUEST Build one validated public mRLFE request.
%
% source contains physical parameters using maintained public/app aliases.
% policy.parameterOptions may contain mrlfeParams and numerical-preset input.
% This helper is independent of GUI handles, sweeps, fitting, and plotting.

if nargin < 4 || isempty(policy)
    policy = struct();
end
if nargin < 3 || isempty(branchName)
    branchName = "A0Like";
end
if nargin < 1 || ~isstruct(source)
    error('mrlfe:InvalidParameters', 'mRLFE source parameters must be a struct.');
end
if ~isstruct(policy)
    error('mrlfe:InvalidPolicy', 'mRLFE request policy must be a struct.');
end

branchName = string(branchName);
if ~(branchName == "A0Like" || branchName == "S0Like")
    error('mrlfe:InvalidBranch', 'Unsupported mRLFE branch "%s".', branchName);
end

frequency_Hz = frequency_Hz(:);
if isempty(frequency_Hz) || any(~isfinite(frequency_Hz)) || any(frequency_Hz <= 0)
    error('mrlfe:InvalidFrequency', 'frequency_Hz must contain positive finite values.');
end
if any(diff(frequency_Hz) <= 0)
    error('mrlfe:InvalidFrequencyOrder', 'frequency_Hz must be strictly ascending.');
end

defaults = mrlfeDefaultParameters();
options = policyOptions(policy);

request = struct();
request.branch = branchName;
request.frequency_Hz = frequency_Hz;
request.material = struct( ...
    'mu_Pa', scalarAlias(source, ["mu_Pa", "mu"], defaults.mu_Pa, 'mrlfe:InvalidMaterial', 'mu'), ...
    'etaS_Pas', etaSValue(source, options, defaults.etaS_Pas), ...
    'rho_kgm3', scalarAlias(source, ["rho_kgm3", "rho"], defaults.rho_kgm3, 'mrlfe:InvalidMaterial', 'rho'), ...
    'nu', scalarAlias(source, "nu", defaults.nu, 'mrlfe:InvalidMaterial', 'nu'));
request.geometry = struct( ...
    'thickness_m', scalarAlias(source, ["thickness_m", "thickness"], defaults.thickness_m, 'mrlfe:InvalidGeometry', 'thickness'));
request.fluid = struct( ...
    'density_kgm3', fluidValue(source, options, ["fluidDensity_kgm3", "fluidDensity", "density_kgm3"], ...
        "fluidDensity", defaults.fluidDensity_kgm3, 'fluid density'), ...
    'soundSpeed_mps', fluidValue(source, options, ["fluidSoundSpeed_mps", "fluidSoundSpeed", "soundSpeed_mps"], ...
        "fluidSoundSpeed", defaults.fluidSoundSpeed_mps, 'fluid sound speed'));
request.numerics = struct('preset', numericalPreset(options));
request.selection = struct('strategy', "adaptive");
request.termination = struct('policy', terminationPolicy(branchName));
request.fallback = struct('policy', "none");

validatePhysicalScalars(request);
end

function options = policyOptions(policy)
if isfield(policy, 'parameterOptions') && ~isempty(policy.parameterOptions)
    options = policy.parameterOptions;
    if ~isstruct(options)
        error('mrlfe:InvalidPolicy', 'policy.parameterOptions must be a struct.');
    end
else
    options = struct();
end
end

function value = etaSValue(source, options, defaultValue)
value = scalarAlias(source, ["etaS_Pas", "etaS"], [], 'mrlfe:InvalidMaterial', 'etaS');
if isempty(value)
    value = nestedOption(options, 'etaS');
end
if isempty(value)
    value = defaultValue;
end
end

function value = fluidValue(source, options, aliases, optionField, defaultValue, label)
value = scalarAlias(source, aliases, [], 'mrlfe:InvalidFluid', label);
if isempty(value)
    value = nestedOption(options, optionField);
end
if isempty(value)
    value = defaultValue;
end
end

function value = nestedOption(options, fieldName)
value = [];
if isstruct(options) && isfield(options, 'mrlfeParams') && ...
        isstruct(options.mrlfeParams) && isfield(options.mrlfeParams, fieldName) && ...
        ~isempty(options.mrlfeParams.(fieldName))
    value = options.mrlfeParams.(fieldName);
end
end

function value = scalarAlias(source, names, defaultValue, errorId, label)
value = defaultValue;
for i = 1:numel(names)
    name = char(names(i));
    if isfield(source, name) && ~isempty(source.(name))
        candidate = source.(name);
        if ~isnumeric(candidate) || ~isscalar(candidate) || ~isfinite(candidate)
            error(errorId, '%s must be a finite scalar.', label);
        end
        value = candidate;
        return;
    end
end
end

function preset = numericalPreset(options)
if isfield(options, 'numerics') && isstruct(options.numerics) && ...
        isfield(options.numerics, 'preset') && ~isempty(options.numerics.preset)
    preset = lower(string(options.numerics.preset));
elseif isfield(options, 'mrlfeNumericalPreset') && ~isempty(options.mrlfeNumericalPreset)
    preset = lower(string(options.mrlfeNumericalPreset));
else
    preset = presetFromProfile(options);
end

if ~isscalar(preset) || ~any(preset == ["fast", "balanced", "robust", "dense"])
    error('mrlfe:InvalidNumericalPreset', ...
        ['Unsupported mRLFE numerical preset "%s". ' ...
         'Use "fast", "balanced", "robust", or "dense".'], join(preset, ", "));
end
end

function preset = presetFromProfile(options)
if isfield(options, 'effectiveExecutionProfile') && ~isempty(options.effectiveExecutionProfile)
    profile = string(options.effectiveExecutionProfile);
elseif isfield(options, 'executionProfile') && ~isempty(options.executionProfile)
    profile = string(options.executionProfile);
elseif isfield(options, 'robustness') && ~isempty(options.robustness)
    profile = string(options.robustness);
else
    profile = "Fast";
end
profiles = ["Fast", "Balanced", "Robust"];
presets = ["fast", "balanced", "robust"];
idx = find(profile == profiles, 1);
if isempty(idx)
    error('mrlfe:InvalidExecutionProfile', ...
        'Unsupported mRLFE execution profile "%s".', profile);
end
preset = presets(idx);
end

function policy = terminationPolicy(branchName)
if branchName == "A0Like"
    policy = "physicalTail";
else
    policy = "none";
end
end

function validatePhysicalScalars(request)
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
