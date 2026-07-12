clear; clc;
startup

fprintf('\nRunning mRLFE production core tests...\n');
fprintf('------------------------------------\n');

test_mrlfe_production_core_contract;
test_mrlfe_production_core_presets;
test_mrlfe_solve_frequency_override;
test_mrlfe_termination_policy;
test_mrlfe_production_core_characterization;
test_mrlfe_production_core_performance;

fprintf('\nmRLFE production core tests passed.\n');
