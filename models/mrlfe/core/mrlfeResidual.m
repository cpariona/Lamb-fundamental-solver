function residual = mrlfeResidual(k, omega, material, geometry, mrlfeParams, options)
%MRLFERESIDUAL Adapt tracker options to the maintained mRLFE objective.
%
% residual = mrlfeResidual(k, omega, material, geometry, mrlfeParams)
% returns the maintained scale-normalized singular-value objective:
%
%   sigma_min(M) / sigma_max(M)
%
% residual = mrlfeResidual(..., options) can select the objective through
% options.mrlfeResidualMethod. The maintained default is
% "minSingularValueRatio".

if nargin < 6 || isempty(options)
    options = struct();
end
method = getFieldOrDefault(options, 'mrlfeResidualMethod', "minSingularValueRatio");
residual = mrlfeObjectiveResidual(k, omega, material, geometry, mrlfeParams, 'Method', method);
end

function value = getFieldOrDefault(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
