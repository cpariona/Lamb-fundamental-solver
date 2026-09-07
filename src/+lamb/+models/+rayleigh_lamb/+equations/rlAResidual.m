function residual = rlAResidual(Cp, frequency, CL, CT, halfThickness)
% Normalized residual for antisymmetric Rayleigh-Lamb equation (A branch).

if Cp <= 0 || frequency <= 0
    residual = inf;
    return;
end

omega = 2 * pi * frequency;
k = omega / Cp;

if abs(k) < eps
    residual = inf;
    return;
end

p = sqrt(complex((omega / CL)^2 - k^2));
q = sqrt(complex((omega / CT)^2 - k^2));

if abs(p) < 1e-12 || abs(q) < 1e-12
    residual = inf;
    return;
end

F = 4 * k^2 * p * q * tan(q * halfThickness) + ...
    (q^2 - k^2)^2 * tan(p * halfThickness);

scale = abs(4 * k^2 * p * q) + abs((q^2 - k^2)^2) + eps;
residual = abs(F) / scale;

if ~isfinite(residual) || isnan(residual)
    residual = inf;
end
end
