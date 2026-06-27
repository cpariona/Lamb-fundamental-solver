clear; clc;
startup

% Run maintained mRLFE smoke and contract tests.

fprintf('\nRunning mRLFE smoke tests...\n');
fprintf('----------------------------\n');

fprintf('\nChecking maintained mRLFE API and tests...\n');
assertFunctionsOnPath({ ...
    'computeMRLFE', ...
    'objectiveMRLFEResidual', ...
    'mrlfeModelCandidateNames', ...
    'mrlfeSetYoungModulusForShearPoisson', ...
    'mrlfeSelectRealKBranches', ...
    'summarizeMRLFETrackingQuality', ...
    'compareMRLFETrackingStrategies', ...
    'solveMRLFEBranchModalAtlas', ...
    'compareMRLFEAtlasPolicy', ...
    'test_mrlfe_smoke', ...
    'test_mrlfe_etaS_zero_limit', ...
    'test_mrlfe_elastic_reference_buffer', ...
    'test_mrlfe_residual_objective_contract', ...
    'test_mrlfe_internal_tracking_grid', ...
    'test_mrlfe_internal_tracking_grid_with_buffer', ...
    'test_mrlfe_viscous_default_internal_tracking_grid', ...
    'test_mrlfe_tracking_quality_summary', ...
    'test_mrlfe_tracking_strategy_comparison', ...
    'test_mrlfe_internal_grid_quality_guard', ...
    'test_mrlfe_maintained_entrypoints_naming', ...
    'test_mrlfe_model_candidate_names', ...
    'test_mrlfe_diagnostic_material_sweep_contract', ...
    'test_mrlfe_etaS_zero_diagnostic_selection', ...
    'test_mrlfe_direct_visco_atlas_option_alias_contract', ...
    'test_mrlfe_modal_atlas_ambiguity_contract', ...
    'test_mrlfe_modal_atlas_s0_contract', ...
    'test_mrlfe_atlas_policy_matrix_contract'}, ...
    'mRLFE maintained API/test');

fprintf('\n[mRLFE 1/18] mRLFE smoke test\n');
test_mrlfe_smoke;

fprintf('\n[mRLFE 2/18] mRLFE etaS zero-limit contract test\n');
test_mrlfe_etaS_zero_limit;

fprintf('\n[mRLFE 3/18] mRLFE elastic-reference buffer contract test\n');
test_mrlfe_elastic_reference_buffer;

fprintf('\n[mRLFE 4/18] mRLFE residual objective contract test\n');
test_mrlfe_residual_objective_contract;

fprintf('\n[mRLFE 5/18] mRLFE internal tracking grid contract test\n');
test_mrlfe_internal_tracking_grid;

fprintf('\n[mRLFE 6/18] mRLFE internal tracking grid with buffer contract test\n');
test_mrlfe_internal_tracking_grid_with_buffer;

fprintf('\n[mRLFE 7/18] mRLFE viscous default internal tracking grid contract test\n');
test_mrlfe_viscous_default_internal_tracking_grid;

fprintf('\n[mRLFE 8/18] mRLFE tracking quality summary contract test\n');
test_mrlfe_tracking_quality_summary;

fprintf('\n[mRLFE 9/18] mRLFE tracking strategy comparison contract test\n');
test_mrlfe_tracking_strategy_comparison;

fprintf('\n[mRLFE 10/18] mRLFE internal-grid quality guard test\n');
test_mrlfe_internal_grid_quality_guard;

fprintf('\n[mRLFE 11/18] mRLFE maintained entrypoints naming guard test\n');
test_mrlfe_maintained_entrypoints_naming;

fprintf('\n[mRLFE 12/18] mRLFE model candidate names contract test\n');
test_mrlfe_model_candidate_names;

fprintf('\n[mRLFE 13/18] mRLFE diagnostic material sweep contract test\n');
test_mrlfe_diagnostic_material_sweep_contract;

fprintf('\n[mRLFE 14/18] mRLFE etaS zero diagnostic selection contract test\n');
test_mrlfe_etaS_zero_diagnostic_selection;

fprintf('\n[mRLFE 15/18] mRLFE direct atlas option alias contract test\n');
test_mrlfe_direct_visco_atlas_option_alias_contract;

fprintf('\n[mRLFE 16/18] mRLFE modal atlas ambiguity contract test\n');
test_mrlfe_modal_atlas_ambiguity_contract;

fprintf('\n[mRLFE 17/18] mRLFE S0 modal atlas contract test\n');
test_mrlfe_modal_atlas_s0_contract;

fprintf('\n[mRLFE 18/18] mRLFE atlas policy matrix contract test\n');
test_mrlfe_atlas_policy_matrix_contract;

fprintf('\nmRLFE smoke tests passed.\n');

function assertFunctionsOnPath(functionNames, label)
for i = 1:numel(functionNames)
    functionName = functionNames{i};
    assert(~isempty(which(functionName)), ...
        'Missing %s on MATLAB path: %s.', label, functionName);
end
end
