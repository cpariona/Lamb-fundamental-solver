clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

% Descriptive performance evidence; no hardware-dependent pass threshold.
fprintf('\nRunning mRLFE production-core performance tests...\n');
fprintf('--------------------------------------------------\n');

test_mrlfe_production_core_performance;

fprintf('\nmRLFE production-core performance tests passed.\n');
