clear; clc;
startup

fprintf('\nRunning mRLFE atlas fitting tests...\n');
fprintf('----------------------------------\n');

test_gui_mrlfe_fit_zero_eta_atlas_contract;
test_gui_mrlfe_fit_route_policy_contract;
test_gui_mrlfe_fixed_etaS_fit_contract;
test_gui_mrlfe_unified_atlas_policy_contract;
test_gui_mrlfe_fit_full_curve_fast_contract;

fprintf('\nmRLFE atlas fitting tests passed.\n');
