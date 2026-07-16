clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

fprintf('\nRunning mRLFE route-integrity tests...\n');
fprintf('--------------------------------------\n');

test_mrlfe_removed_routes_absent;
test_mrlfe_removed_route_flags_absent;
test_mrlfe_maintained_route_characterization;

fprintf('\nmRLFE route-integrity tests passed.\n');
