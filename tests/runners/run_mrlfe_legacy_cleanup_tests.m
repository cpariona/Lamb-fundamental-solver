clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

fprintf('\nRunning mRLFE legacy route cleanup tests...\n');
fprintf('-----------------------------------------\n');

test_mrlfe_no_legacy_routes;
test_mrlfe_no_legacy_route_flags;
test_mrlfe_legacy_cleanup_characterization;

fprintf('\nmRLFE legacy route cleanup tests passed.\n');
