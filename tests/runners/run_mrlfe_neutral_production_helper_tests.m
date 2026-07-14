clear; clc;
startup

fprintf('\nRunning mRLFE neutral production-helper tests...\n');
fprintf('-----------------------------------------------\n');

test_mrlfe_no_historical_production_dependencies;
test_mrlfe_neutral_seed_contract;
test_mrlfe_neutral_tracker_termination_contract;
test_mrlfe_production_core_characterization;

fprintf('\nmRLFE neutral production-helper tests passed.\n');
