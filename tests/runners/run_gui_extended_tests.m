clear; clc;
startup

% Numerical mRLFE FitTool contracts kept outside routine quick validation.
fprintf('\nRunning extended GUI fitting tests...\n');
fprintf('-------------------------------------\n');

test_gui_mrlfe_fixed_etaS_fit_contract;
test_gui_mrlfe_fit_route_policy_contract;
test_gui_mrlfe_fit_full_curve_fast_contract;

fprintf('\nExtended GUI fitting tests passed.\n');
