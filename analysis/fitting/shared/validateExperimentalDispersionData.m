function experimental = validateExperimentalDispersionData(experimental, minValidPoints)
%VALIDATEEXPERIMENTALDISPERSIONDATA Validate normalized experimental dispersion data.
%
% experimental = validateExperimentalDispersionData(experimental)
% experimental = validateExperimentalDispersionData(experimental, minValidPoints)
%
% The function returns the normalized structure so callers can use validation
% and normalization as a single step.

if nargin < 2 || isempty(minValidPoints)
    minValidPoints = 1;
end

if ~isscalar(minValidPoints) || ~isfinite(minValidPoints) || minValidPoints < 1
    error('minValidPoints must be a positive finite scalar.');
end

experimental = normalizeExperimentalDispersionData(experimental);

if experimental.numValidPoints < minValidPoints
    error('Experimental data has %d valid point(s), but at least %d are required.', ...
        experimental.numValidPoints, minValidPoints);
end

if any(experimental.Cp_mps(experimental.validMask) <= 0)
    error('Valid experimental Cp_mps values must be positive.');
end

standardError = experimental.standardError_Cp_mps(experimental.validMask);
providedStandardError = isfinite(standardError);
if any(providedStandardError & standardError <= 0)
    error('Provided standardError_Cp_mps values must be positive where finite.');
end
end
