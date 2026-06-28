clear; clc;
startup

fprintf('\nRunning mRLFE atlas tests...\n');
fprintf('--------------------------\n');

assertFunctionsOnPath({ ...
    'solveMRLFEBranchModalAtlas', ...
    'solveMRLFEAtlasUnified', ...
    'solveMRLFEBranchAdaptiveAtlas', ...
    'mrlfeMakePhysicalSeedMode', ...
    'compareMRLFEAtlasPolicy', ...
    'mrlfeMakeDirectViscoAtlasBranchOptions', ...
    'mrlfeApplyDelayedViscoModalCut', ...
    'mrlfeApplyPhysicalCorridorCut', ...
    'test_mrlfe_direct_visco_atlas_option_alias_contract', ...
    'test_mrlfe_modal_atlas_ambiguity_contract', ...
    'test_mrlfe_modal_atlas_s0_contract', ...
    'test_mrlfe_atlas_policy_matrix_contract', ...
    'test_mrlfe_direct_visco_branch_policy_contract', ...
    'test_mrlfe_delayed_visco_modal_cut_contract', ...
    'test_mrlfe_a0_delayed_direct_visco_opt_in_contract', ...
    'test_mrlfe_a0_delayed_direct_visco_s0_guard_contract', ...
    'test_mrlfe_unified_atlas_route_contract', ...
    'test_mrlfe_s0_adaptive_atlas_tracker_contract', ...
    'test_mrlfe_unified_atlas_mu_sweep_contract', ...
    'test_mrlfe_a0_adaptive_physical_tail_contract'}, ...
    'mRLFE atlas API/test');

fprintf('\n[mRLFE atlas 1/12] direct atlas option alias contract test\n');
test_mrlfe_direct_visco_atlas_option_alias_contract;

fprintf('\n[mRLFE atlas 2/12] modal atlas ambiguity contract test\n');
test_mrlfe_modal_atlas_ambiguity_contract;

fprintf('\n[mRLFE atlas 3/12] S0 modal atlas contract test\n');
test_mrlfe_modal_atlas_s0_contract;

fprintf('\n[mRLFE atlas 4/12] atlas policy matrix contract test\n');
test_mrlfe_atlas_policy_matrix_contract;

fprintf('\n[mRLFE atlas 5/12] direct-visco branch policy contract test\n');
test_mrlfe_direct_visco_branch_policy_contract;

fprintf('\n[mRLFE atlas 6/12] delayed-visco modal cut contract test\n');
test_mrlfe_delayed_visco_modal_cut_contract;

fprintf('\n[mRLFE atlas 7/12] A0 delayed direct-visco opt-in contract test\n');
test_mrlfe_a0_delayed_direct_visco_opt_in_contract;

fprintf('\n[mRLFE atlas 8/12] A0 delayed direct-visco S0 guard contract test\n');
test_mrlfe_a0_delayed_direct_visco_s0_guard_contract;

fprintf('\n[mRLFE atlas 9/12] unified atlas route contract test\n');
test_mrlfe_unified_atlas_route_contract;

fprintf('\n[mRLFE atlas 10/12] S0 adaptive atlas tracker contract test\n');
test_mrlfe_s0_adaptive_atlas_tracker_contract;

fprintf('\n[mRLFE atlas 11/12] unified atlas mu-sweep contract test\n');
test_mrlfe_unified_atlas_mu_sweep_contract;

fprintf('\n[mRLFE atlas 12/12] A0 adaptive physical tail contract test\n');
test_mrlfe_a0_adaptive_physical_tail_contract;

fprintf('\nmRLFE atlas tests passed.\n');

function assertFunctionsOnPath(functionNames, label)
for i = 1:numel(functionNames)
    functionName = functionNames{i};
    assert(~isempty(which(functionName)), ...
        'Missing %s on MATLAB path: %s.', label, functionName);
end
end
