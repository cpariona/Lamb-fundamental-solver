clear; clc;
startup

% Run the mixed mRLFE production-core validation set. Membership deliberately
% includes contracts and grid checks together with characterization and
% performance evidence; it is not a lightweight smoke runner.

fprintf('\nRunning mRLFE production core tests...\n');
fprintf('------------------------------------\n');

test_mrlfe_production_core_contract;
test_mrlfe_production_core_presets;
test_mrlfe_numerical_preset_grids;
test_mrlfe_solve_frequency_override;
test_mrlfe_robust_start_contract;
test_mrlfe_termination_policy;
test_mrlfe_production_core_characterization;
test_mrlfe_production_core_performance;

fprintf('\nmRLFE production core tests passed.\n');
