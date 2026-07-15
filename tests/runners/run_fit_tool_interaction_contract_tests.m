clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

% FitTool editing and axis helper behavior without requested-curve solves.
fprintf('\nRunning FitTool interaction helper contract...\n');
fprintf('----------------------------------------------\n');

test_fit_tool_interaction_helpers;

fprintf('\nFitTool interaction helper contract passed.\n');
