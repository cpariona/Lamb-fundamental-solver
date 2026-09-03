function run_numerical_regression_tests()
% Explicit validation scope: restore the caller path on success or failure.
callerPath = path;
restorePath = onCleanup(@() path(callerPath)); %#ok<NASGU>
projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(projectRoot, 'tests', 'tooling'));
configureTestPath();
runTests();
end

function runTests()
fprintf('\nRunning numerical regression tests...\n');
fprintf('-------------------------------------\n');

% Rayleigh-Lamb and mRLFE numerical contracts.
test_rl_fit_evaluator_branch_consistency;
test_rl_fit_synthetic_A0;
test_mrlfe_fit_synthetic_A0Like;
test_mrlfe_numerical_preset_grids;
test_mrlfe_production_core_contract;
test_mrlfe_solve_frequency_override;
test_mrlfe_robust_start_contract;
test_mrlfe_termination_policy;
test_mrlfe_public_contract_result_schema;

% AE atlas, tracking, result, and synthetic fitting contracts.
test_ae_result_schema_characterization;
test_ae_tracking_policy_characterization;
test_ae_tracking_policy_ownership;
test_acoustoelastic_iop_hgo_fallback_invalidation;
test_acoustoelastic_iop_hgo_internal_tracking_grid;
test_acoustoelastic_iop_hgo_atlasA0_smoke;
test_ae_fit_synthetic_atlasA0;

% Snapshot follows independent objective, tracking, and recovery evidence.
test_lightweight_numerical_regression;

fprintf('\nNumerical regression tests passed.\n');
end
