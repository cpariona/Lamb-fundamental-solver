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
    'mrlfeMakeDirectViscoAtlasBranchOptions', ...
    'mrlfeApplyDelayedViscoModalCut', ...
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
    'test_mrlfe_atlas_policy_matrix_contract', ...
    'test_mrlfe_direct_visco_branch_policy_contract', ...
    'test_mrlfe_delayed_visco_modal_cut_contract', ...
    'test_mrlfe_a0_delayed_direct_visco_opt_in_contract', ...
    'test_mrlfe_a0_delayed_direct_visco_s0_guard_contract'}, ...
    'mRLFE maintained API/test');

fprintf('\n[mRLFE 1/22] mRLFE smoke test\n');
test_mrlfe_smoke;

fprintf('\n[mRLFE 2/22] mRLFE etaS zero-limit contract test\n');
test_mrlfe_etaS_zero_limit;

fprintf('\n[mRLFE 3/22] mRLFE elastic-reference buffer contract test\n');
test_mrlfe_elastic_reference_buffer;

fprintf('\n[mRLFE 4/22] mRLFE residual objective contract test\n');
test_mrlfe_residual_objective_contract;

fprintf('\n[mRLFE 5/22] mRLFE internal tracking grid contract test\n');
test_mrlfe_internal_tracking_grid;

fprintf('\n[mRLFE 6/22] mRLFE internal tracking grid with buffer contract test\n');
test_mrlfe_internal_tracking_grid_with_buffer;

fprintf('\n[mRLFE 7/22] mRLFE viscous default internal tracking grid contract test\n');
test_mrlfe_viscous_default_internal_tracking_grid;

fprintf('\n[mRLFE 8/22] mRLFE tracking quality summary contract test\n');
test_mrlfe_tracking_quality_summary;

fprintf('\n[mRLFE 9/22] mRLFE tracking strategy comparison contract test\n');
test_mrlfe_tracking_strategy_comparison;

fprintf('\n[mRLFE 10/22] mRLFE internal-grid quality guard test\n');
test_mrlfe_internal_grid_quality_guard;

fprintf('\n[mRLFE 11/22] mRLFE maintained entrypoints naming guard test\n');
test_mrlfe_maintained_entrypoints_naming;

fprintf('\n[mRLFE 12/22] mRLFE model candidate names contract test\n');
test_mrlfe_model_candidate_names;

fprintf('\n[mRLFE 13/22] mRLFE diagnostic material sweep contract test\n');
test_mrlfe_diagnostic_material_sweep_contract;

fprintf('\n[mRLFE 14/22] mRLFE etaS zero diagnostic selection contract test\n');
test_mrlfe_etaS_zero_diagnostic_selection;

fprintf('\n[mRLFE 15/22] mRLFE direct atlas option alias contract test\n');
test_mrlfe_direct_visco_atlas_option_alias_contract;

fprintf('\n[mRLFE 16/22] mRLFE modal atlas ambiguity contract test\n');
test_mrlfe_modal_atlas_ambiguity_contract;

fprintf('\n[mRLFE 17/22] mRLFE S0 modal atlas contract test\n');
test_mrlfe_modal_atlas_s0_contract;

fprintf('\n[mRLFE 18/22] mRLFE atlas policy matrix contract test\n');
test_mrlfe_atlas_policy_matrix_contract;

fprintf('\n[mRLFE 19/22] mRLFE direct-visco branch policy contract test\n');
test_mrlfe_direct_visco_branch_policy_contract;

fprintf('\n[mRLFE 20/22] mRLFE delayed-visco modal cut contract test\n');
test_mrlfe_delayed_visco_modal_cut_contract;

fprintf('\n[mRLFE 21/22] mRLFE A0 delayed direct-visco opt-in contract test\n');
test_mrlfe_a0_delayed_direct_visco_opt_in_contract;

fprintf('\n[mRLFE 22/22] mRLFE A0 delayed direct-visco S0 guard contract test\n');
test_mrlfe_a0_delayed_direct_visco_s0_guard_contract;

fprintf('\nmRLFE smoke tests passed.\n');

function assertFunctionsOnPath(functionNames, label)
for i = 1:numel(functionNames)
    functionName = functionNames{i};
    assert(~isempty(which(functionName)), ...
        'Missing %s on MATLAB path: %s.', label, functionName);
end
end
