function experimental = normalizeExperimentalDispersionData(experimental)
%NORMALIZEEXPERIMENTALDISPERSIONDATA Normalize experimental dispersion data.
%
% Required input fields:
%   frequency_Hz
%   Cp_mps
%
% Optional input fields:
%   standardError_Cp_mps
%   validMask
%
% Output vectors are column vectors. Missing optional fields are filled with
% NaN standard errors and a finite-data valid mask.

if nargin < 1 || ~isstruct(experimental)
    error('Experimental data must be provided as a structure.');
end

requiredFields = {'frequency_Hz', 'Cp_mps'};
for i = 1:numel(requiredFields)
    fieldName = requiredFields{i};
    if ~isfield(experimental, fieldName)
        error('Experimental data is missing required field: %s.', fieldName);
    end
end

frequency_Hz = experimental.frequency_Hz(:);
Cp_mps = experimental.Cp_mps(:);

if numel(frequency_Hz) ~= numel(Cp_mps)
    error('frequency_Hz and Cp_mps must have the same number of elements.');
end

if isfield(experimental, 'standardError_Cp_mps') && ~isempty(experimental.standardError_Cp_mps)
    standardError_Cp_mps = experimental.standardError_Cp_mps(:);
    if numel(standardError_Cp_mps) ~= numel(Cp_mps)
        error('standardError_Cp_mps must match the size of Cp_mps.');
    end
else
    standardError_Cp_mps = nan(size(Cp_mps));
end

finiteMask = isfinite(frequency_Hz) & isfinite(Cp_mps) & frequency_Hz > 0;

if isfield(experimental, 'validMask') && ~isempty(experimental.validMask)
    validMask = logical(experimental.validMask(:));
    if numel(validMask) ~= numel(Cp_mps)
        error('validMask must match the size of Cp_mps.');
    end
    validMask = validMask & finiteMask;
else
    validMask = finiteMask;
end

experimental.frequency_Hz = frequency_Hz;
experimental.Cp_mps = Cp_mps;
experimental.standardError_Cp_mps = standardError_Cp_mps;
experimental.validMask = validMask;
experimental.numPoints = numel(Cp_mps);
experimental.numValidPoints = nnz(validMask);
end
