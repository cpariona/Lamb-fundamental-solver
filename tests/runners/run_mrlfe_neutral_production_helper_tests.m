clear; clc;
startup

fprintf('\nRunning mRLFE neutral production-helper tests...\n');
fprintf('-----------------------------------------------\n');

test_mrlfe_no_historical_production_dependencies;
test_mrlfe_neutral_seed_contract;
test_mrlfe_neutral_tracker_termination_contract;
run_mrlfe_production_core_extended_tests;

fprintf('\nmRLFE neutral production-helper tests passed.\n');
