clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

%TEST_MRLFE_DIAGNOSTIC_MATERIAL_SWEEP_CONTRACT
% Protect diagnostic E-equivalent sweeps under the maintained ShearPoisson
% material contract. Changing E alone is not sufficient; mu must be updated.

nu = 0.4999;
rho = 1070;
EValues = [50e3, 100e3, 300e3];
muValues = zeros(size(EValues));
ctValues = zeros(size(EValues));

for i = 1:numel(EValues)
    params = rlDefaultParams();
    params.nu = nu;
    params.rho = rho;
    params = mrlfeSetYoungModulusForShearPoisson(params, EValues(i));
    material = rlComputeMaterial(params);
    muValues(i) = material.mu;
    ctValues(i) = material.CT;
    expectedE = 2 * material.mu * (1 + params.nu);
    assert(abs(expectedE - EValues(i)) / EValues(i) < 1e-12, ...
        'Diagnostic E-equivalent sweep did not map consistently to mu.');
end

assert(numel(unique(round(muValues, 9))) == numel(EValues), ...
    'Diagnostic stiffness sweep must change mu for each E-equivalent value.');
assert(all(diff(muValues) > 0), ...
    'Diagnostic stiffness sweep mu values must increase monotonically.');
assert(all(diff(ctValues) > 0), ...
    'Diagnostic stiffness sweep CT values must increase monotonically.');

fprintf('test_mrlfe_diagnostic_material_sweep_contract passed. E-equivalent diagnostics update mu.\n');
