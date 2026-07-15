clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

% Focused fitting-route and cache regressions measured at roughly 11-15 s.
fprintf('\nRunning mRLFE fitting regression tests...\n');
fprintf('-----------------------------------------\n');

test_mrlfe_etaS_fit_forward_cache;
test_mrlfe_fit_fast_options_quality;

fprintf('\nmRLFE fitting regression tests passed.\n');
