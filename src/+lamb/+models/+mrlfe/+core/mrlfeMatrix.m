function M = mrlfeMatrix(k, omega, material, geometry, mrlfeParams)
% Build the 5-by-5 modified Rayleigh-Lamb fluid-loaded matrix.
%
% Unknowns are [A, B, C, D, AF]. The input k can be real or complex.
% geometry.thickness is the total layer thickness and d is half-thickness.
% The shear modulus can be complex: muStar = mu + 1i*omega*etaS.

rhoS = material.rho;
rhoF = mrlfeParams.fluidDensity;
cF = mrlfeParams.fluidSoundSpeed;
d = geometry.thickness / 2;

useComplexLambda = getFieldOrDefault(mrlfeParams, 'useComplexLambda', false);
if useComplexLambda
    lambdaValue = material.lambda + 1i * omega * getFieldOrDefault(mrlfeParams, 'etaL', 0);
else
    lambdaValue = material.lambda;
end
muStar = material.mu + 1i * omega * getFieldOrDefault(mrlfeParams, 'etaS', 0);

alphaF = stableSqrt(k.^2 - (omega / cF).^2);
alpha = stableSqrt(k.^2 - rhoS * omega.^2 ./ (lambdaValue + 2 * muStar));
beta = stableSqrt(k.^2 - rhoS * omega.^2 ./ muStar);

k2 = k.^2;
beta2 = beta.^2;
common = k2 + beta2;

M = zeros(5, 5);

% Surface exposed to air, z = +d: sigma_zz = 0.
M(1,1) = common * sinh(alpha * d);
M(1,2) = 2 * k * beta * sinh(beta * d);
M(1,3) = common * cosh(alpha * d);
M(1,4) = 2 * k * beta * cosh(beta * d);
M(1,5) = 0;

% Surface exposed to air, z = +d: sigma_zr = 0.
M(2,1) = 2 * k * alpha * cosh(alpha * d);
M(2,2) = common * cosh(beta * d);
M(2,3) = 2 * k * alpha * sinh(alpha * d);
M(2,4) = common * sinh(beta * d);
M(2,5) = 0;

% Fluid interface, z = -d: normal stress continuity.
M(3,1) = -common * sinh(alpha * d);
M(3,2) = -2 * k * beta * sinh(beta * d);
M(3,3) = common * cosh(alpha * d);
M(3,4) = 2 * k * beta * cosh(beta * d);
M(3,5) = rhoF * omega^2 / muStar;

% Fluid interface, z = -d: sigma_zr = 0.
M(4,1) = 2 * k * alpha * cosh(alpha * d);
M(4,2) = common * cosh(beta * d);
M(4,3) = -2 * k * alpha * sinh(alpha * d);
M(4,4) = -common * sinh(beta * d);
M(4,5) = 0;

% Fluid interface, z = -d: normal displacement continuity.
M(5,1) = alpha * cosh(alpha * d);
M(5,2) = k * cosh(beta * d);
M(5,3) = -alpha * sinh(alpha * d);
M(5,4) = -k * sinh(beta * d);
M(5,5) = -alphaF;
end

function y = stableSqrt(x)
y = sqrt(x);
if imag(y) < 0
    y = -y;
end
end

function value = getFieldOrDefault(s, name, defaultValue)
if isfield(s, name)
    value = s.(name);
else
    value = defaultValue;
end
end
