clear; clc;
startup

fprintf('\nRunning mRLFE Main GUI public-solver migration tests...\n');
fprintf('------------------------------------------------------\n');

test_mrlfe_main_gui_uses_public_solver;
test_mrlfe_main_gui_characterization;
test_mrlfe_main_gui_consumer_equivalence;
test_mrlfe_main_gui_result_contract;

fprintf('\nmRLFE Main GUI public-solver migration tests passed.\n');
