clear; clc;
startup

fprintf('\nRunning FitTool interaction tests...\n');
fprintf('-----------------------------------\n');

test_fit_tool_interaction_helpers;
test_fit_tool_requested_curve_models;

fprintf('\nFitTool interaction tests passed.\n');
