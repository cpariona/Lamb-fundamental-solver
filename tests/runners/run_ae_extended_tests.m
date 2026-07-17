clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

% Solver-grid and synthetic fitting regressions are not quick smoke.
fprintf('\nRunning extended acoustoelastic IOP/HGO tests...\n');
fprintf('------------------------------------------------\n');

test_ae_result_schema_characterization;
test_ae_tracking_policy_characterization;
test_ae_tracking_policy_ownership;
test_acoustoelastic_iop_hgo_fallback_invalidation;
test_acoustoelastic_iop_hgo_internal_tracking_grid;
test_acoustoelastic_iop_hgo_atlasA0_smoke;
test_ae_fit_synthetic_atlasA0;

fprintf('\nExtended acoustoelastic IOP/HGO tests passed.\n');
