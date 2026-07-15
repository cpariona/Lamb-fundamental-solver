clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

% Multi-profile preset execution and production-core characterization evidence.
fprintf('\nRunning mRLFE production-core characterization...\n');
fprintf('--------------------------------------------------\n');

test_mrlfe_production_core_presets;
test_mrlfe_production_core_characterization;

fprintf('\nmRLFE production-core characterization passed.\n');
