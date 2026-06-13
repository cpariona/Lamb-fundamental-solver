function residual = mrlfeResidual(k, omega, material, geometry, mrlfeParams)
% Return a scale-normalized singular-value residual for the mRLFE matrix.
%
% residual = sigma_min(M) / sigma_max(M)
%
% This is numerically more stable than using det(M) directly.

M = mrlfeMatrix(k, omega, material, geometry, mrlfeParams);
if any(~isfinite(M(:)))
    residual = inf;
    return;
end

s = svd(M);
if isempty(s) || s(1) == 0 || ~isfinite(s(1))
    residual = inf;
else
    residual = s(end) / s(1);
end
end
