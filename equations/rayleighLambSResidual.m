function residual = rayleighLambSResidual(Cp, frequency, CL, CT, halfThickness)
% Normalized residual for symmetric Rayleigh-Lamb equation (S branch).

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

F = 4 * k^2 * p * q * tan(p * halfThickness) + ...
    (q^2 - k^2)^2 * tan(q * halfThickness);

scale = abs(4 * k^2 * p * q) + abs((q^2 - k^2)^2) + eps;
residual = abs(F) / scale;

if ~isfinite(residual) || isnan(residual)
    residual = inf;
end
end
