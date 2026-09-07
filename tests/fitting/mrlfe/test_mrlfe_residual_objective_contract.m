function test_mrlfe_residual_objective_contract()
%TEST_MRLFE_RESIDUAL_OBJECTIVE_CONTRACT Contract test for mRLFE residual objective.
%
% The maintained mRLFE tracker objective is sigma_min(M)/sigma_max(M). The
% determinant objective is available only for diagnostics/comparison.

params = lamb.models.rayleigh_lamb.rlDefaultParams();
params.fmin = 1000;
params.fmax = 1000;
params.numFrequencyPoints = 10;
params.frequencySpacing = "linspace";

material = lamb.models.rayleigh_lamb.core.rlComputeMaterial(params);
geometry = lamb.models.rayleigh_lamb.core.rlComputeGeometry(params);
geometry = rmfield(geometry, 'halfThickness');
frequency = lamb.grids.buildFrequencyVector(params);
omega = 2*pi*frequency(1);

mrlfeParams = lamb.models.mrlfe.configuration.mrlfeDefaultInternalParameters();
mrlfeParams.etaS = 0.05;
mrlfeParams.etaL = 0;
mrlfeParams.useComplexLambda = false;
mrlfeParams.solveComplexK = false;

k = omega / 4.0;

defaultResidual = lamb.models.mrlfe.core.mrlfeResidual(k, omega, material, geometry, mrlfeParams);
explicitDefault = lamb.models.mrlfe.core.mrlfeObjectiveResidual(k, omega, material, geometry, mrlfeParams, ...
    'Method', "minSingularValueRatio");
determinantResidual = lamb.models.mrlfe.core.mrlfeObjectiveResidual(k, omega, material, geometry, mrlfeParams, ...
    'Method', "determinant");

assert(isfinite(defaultResidual) && defaultResidual >= 0, ...
    'Default mRLFE residual must be finite and non-negative for this test point.');
assert(isfinite(explicitDefault) && explicitDefault >= 0, ...
    'Explicit default mRLFE residual must be finite and non-negative for this test point.');
assert(isfinite(determinantResidual) && determinantResidual >= 0, ...
    'Determinant mRLFE residual must be finite and non-negative for this test point.');
assert(abs(defaultResidual - explicitDefault) <= 10*eps(max(1, abs(explicitDefault))), ...
    'lamb.models.mrlfe.core.mrlfeResidual wrapper must preserve the minSingularValueRatio default.');

fprintf('test_mrlfe_residual_objective_contract passed. Default objective is singular-value ratio.\n');
end
