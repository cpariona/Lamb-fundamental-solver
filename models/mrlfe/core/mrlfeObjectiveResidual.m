function residual = mrlfeObjectiveResidual(k, omega, material, geometry, mrlfeParams, varargin)
%MRLFEOBJECTIVERESIDUAL Evaluate the scalar objective used by mRLFE tracking.
%
% residual = mrlfeObjectiveResidual(k, omega, material, geometry, mrlfeParams)
% evaluates the maintained robust objective:
%
%   residual = sigma_min(M) / sigma_max(M)
%
% where M is the 5-by-5 mRLFE matrix. This objective is scale-normalized and
% more stable than using det(M) directly.
%
% residual = mrlfeObjectiveResidual(..., 'Method', method) supports:
%
%   "minSingularValueRatio"  maintained default, sigma_min/sigma_max
%   "determinant"            normalized determinant, for diagnostics/comparison
%
% The determinant method is not the recommended tracker default.

p = inputParser;
addParameter(p, 'Method', "minSingularValueRatio", @(x)ischar(x) || isstring(x));
parse(p, varargin{:});
method = string(p.Results.Method);

M = mrlfeMatrix(k, omega, material, geometry, mrlfeParams);
if any(~isfinite(M(:)))
    residual = inf;
    return;
end

switch method
    case "minSingularValueRatio"
        residual = singularValueRatioObjective(M);
    case "determinant"
        residual = normalizedDeterminantObjective(M);
    otherwise
        error('mrlfeObjectiveResidual:UnknownMethod', ...
            'Unknown mRLFE residual method "%s". Use "minSingularValueRatio" or "determinant".', method);
end
end

function residual = singularValueRatioObjective(M)
s = svd(M);
if isempty(s) || s(1) == 0 || ~isfinite(s(1))
    residual = inf;
else
    residual = s(end) / s(1);
end
end

function residual = normalizedDeterminantObjective(M)
scale = norm(M, 'fro');
if ~isfinite(scale) || scale <= 0
    residual = inf;
    return;
end
n = size(M, 1);
residual = abs(det(M)) / scale^n;
if ~isfinite(residual)
    residual = inf;
end
end
