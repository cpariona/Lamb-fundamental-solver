clear; clc;
startup

fprintf('\nRunning mRLFE FitTool public-solver migration tests...\n');
fprintf('-----------------------------------------------------\n');

test_mrlfe_fit_frequency_grid_contract;
test_fit_display_curve_no_solver_contract;
test_mrlfe_fit_uses_public_solver;
test_mrlfe_fit_public_solver_characterization;
test_mrlfe_fit_public_solver_parameter_regression;

fprintf('\nmRLFE FitTool public-solver migration tests passed.\n');
