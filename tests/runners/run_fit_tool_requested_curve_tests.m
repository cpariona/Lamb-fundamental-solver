clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

% Requested-curve model execution is extended surface integration.
fprintf('\nRunning FitTool requested-curve tests...\n');
fprintf('----------------------------------------\n');

test_fit_tool_requested_curve_models;

fprintf('\nFitTool requested-curve tests passed.\n');
