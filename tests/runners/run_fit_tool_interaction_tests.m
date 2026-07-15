clear; clc;
startup

fprintf('\nRunning FitTool interaction tests...\n');
fprintf('-----------------------------------\n');

% Compatibility aggregate over the quick helper and extended curve owners.
run_fit_tool_interaction_contract_tests;
run_fit_tool_requested_curve_tests;

fprintf('\nFitTool interaction tests passed.\n');
