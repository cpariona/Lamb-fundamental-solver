function mrlfeValidateRequest(request)
%MRLFEVALIDATEREQUEST Validate a resolved public mRLFE request structure.

if nargin < 1 || ~isstruct(request)
    error('mrlfe:InvalidRequest', 'mRLFE request must be a struct.');
end

frequency_Hz = getRequired(request, 'frequency_Hz', 'mrlfe:InvalidFrequency');
if isempty(frequency_Hz)
    error('mrlfe:InvalidFrequency', 'frequency_Hz must not be empty.');
end
frequency_Hz = frequency_Hz(:);
if any(~isfinite(frequency_Hz))
    error('mrlfe:InvalidFrequency', 'frequency_Hz must contain finite values.');
end
if any(frequency_Hz <= 0)
    error('mrlfe:InvalidFrequency', 'frequency_Hz must contain positive values.');
end
if any(diff(frequency_Hz) <= 0)
    error('mrlfe:InvalidFrequencyOrder', 'frequency_Hz must be strictly ascending.');
end

branch = string(getRequired(request, 'branch', 'mrlfe:InvalidBranch'));
if ~(branch == "A0Like" || branch == "S0Like")
    error('mrlfe:InvalidBranch', 'Unsupported mRLFE branch "%s".', branch);
end

material = getRequired(request, 'material', 'mrlfe:InvalidMaterial');
geometry = getRequired(request, 'geometry', 'mrlfe:InvalidGeometry');
fluid = getRequired(request, 'fluid', 'mrlfe:InvalidFluid');
numerics = getRequired(request, 'numerics', 'mrlfe:InvalidNumericalPreset');
selection = getRequired(request, 'selection', 'mrlfe:InvalidSelectionStrategy');
termination = getRequired(request, 'termination', 'mrlfe:InvalidTerminationPolicy');
fallback = getRequired(request, 'fallback', 'mrlfe:InvalidFallbackPolicy');

validatePositive(material, 'mu_Pa', 'mrlfe:InvalidMaterial');
validateNonnegative(material, 'etaS_Pas', 'mrlfe:InvalidMaterial');
validatePositive(material, 'rho_kgm3', 'mrlfe:InvalidMaterial');
nu = getRequired(material, 'nu', 'mrlfe:InvalidMaterial');
if ~isnumeric(nu) || ~isscalar(nu) || ~isfinite(nu) || nu <= -1 || nu >= 0.5
    error('mrlfe:InvalidMaterial', 'material.nu must be finite and satisfy -1 < nu < 0.5.');
end

validatePositive(geometry, 'thickness_m', 'mrlfe:InvalidGeometry');
validatePositive(fluid, 'density_kgm3', 'mrlfe:InvalidFluid');
validatePositive(fluid, 'soundSpeed_mps', 'mrlfe:InvalidFluid');

mrlfeGetNumericalPreset(getRequired(numerics, 'preset', 'mrlfe:InvalidNumericalPreset'));

strategy = string(getRequired(selection, 'strategy', 'mrlfe:InvalidSelectionStrategy'));
if strategy ~= "adaptive"
    error('mrlfe:InvalidSelectionStrategy', 'Unsupported mRLFE selection strategy "%s".', strategy);
end

policy = string(getRequired(termination, 'policy', 'mrlfe:InvalidTerminationPolicy'));
if ~(policy == "physicalTail" || policy == "none" || policy == "continuity")
    error('mrlfe:InvalidTerminationPolicy', 'Unsupported mRLFE termination policy "%s".', policy);
end

fallbackPolicy = string(getRequired(fallback, 'policy', 'mrlfe:InvalidFallbackPolicy'));
if fallbackPolicy ~= "none"
    error('mrlfe:InvalidFallbackPolicy', 'Unsupported mRLFE fallback policy "%s".', fallbackPolicy);
end
end

function value = getRequired(s, fieldName, errorId)
if ~isstruct(s) || ~isfield(s, fieldName) || isempty(s.(fieldName))
    error(errorId, 'Missing required mRLFE request field "%s".', fieldName);
end
value = s.(fieldName);
end

function validatePositive(s, fieldName, errorId)
value = getRequired(s, fieldName, errorId);
if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value) || value <= 0
    error(errorId, 'Field "%s" must be a positive finite scalar.', fieldName);
end
end

function validateNonnegative(s, fieldName, errorId)
value = getRequired(s, fieldName, errorId);
if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value) || value < 0
    error(errorId, 'Field "%s" must be a nonnegative finite scalar.', fieldName);
end
end
