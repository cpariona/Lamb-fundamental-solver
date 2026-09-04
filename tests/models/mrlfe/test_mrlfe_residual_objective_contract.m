clear; clc;
if isempty(which('mrlfeSolve'))
    configureTestPath;
end

%TEST_MRLFE_RESIDUAL_OBJECTIVE_CONTRACT Contract test for mRLFE residual objective.
%
% The maintained mRLFE tracker objective is sigma_min(M)/sigma_max(M). The
% determinant objective is available only for diagnostics/comparison.

params = rlDefaultParams();
params.fmin = 1000;
params.fmax = 1000;
params.numFrequencyPoints = 10;
params.frequencySpacing = "linspace";

material = rlComputeMaterial(params);
geometry = rlComputeGeometry(params);
geometry = rmfield(geometry, 'halfThickness');
frequency = rlBuildFrequencyVector(params);
omega = 2*pi*frequency(1);

mrlfeParams = mrlfeDefaultInternalParameters();
mrlfeParams.etaS = 0.05;
mrlfeParams.etaL = 0;
mrlfeParams.useComplexLambda = false;
mrlfeParams.solveComplexK = false;

k = omega / 4.0;

defaultResidual = mrlfeResidual(k, omega, material, geometry, mrlfeParams);
explicitDefault = mrlfeObjectiveResidual(k, omega, material, geometry, mrlfeParams, ...
    'Method', "minSingularValueRatio");
determinantResidual = mrlfeObjectiveResidual(k, omega, material, geometry, mrlfeParams, ...
    'Method', "determinant");

assert(isfinite(defaultResidual) && defaultResidual >= 0, ...
    'Default mRLFE residual must be finite and non-negative for this test point.');
assert(isfinite(explicitDefault) && explicitDefault >= 0, ...
    'Explicit default mRLFE residual must be finite and non-negative for this test point.');
assert(isfinite(determinantResidual) && determinantResidual >= 0, ...
    'Determinant mRLFE residual must be finite and non-negative for this test point.');
assert(abs(defaultResidual - explicitDefault) <= 10*eps(max(1, abs(explicitDefault))), ...
    'mrlfeResidual wrapper must preserve the minSingularValueRatio default.');

fprintf('test_mrlfe_residual_objective_contract passed. Default objective is singular-value ratio.\n');
