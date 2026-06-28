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
    'test_mrlfe_direct_visco_atlas_option_alias_contract', ...
    'test_mrlfe_modal_atlas_ambiguity_contract', ...
    'test_mrlfe_modal_atlas_s0_contract', ...
    'test_mrlfe_atlas_policy_matrix_contract', ...
    'test_mrlfe_direct_visco_branch_policy_contract', ...
    'test_mrlfe_delayed_visco_modal_cut_contract', ...
    'test_mrlfe_a0_delayed_direct_visco_opt_in_contract', ...
    'test_mrlfe_a0_delayed_direct_visco_s0_guard_contract', ...
    'test_mrlfe_unified_atlas_route_contract', ...
    'test_mrlfe_s0_adaptive_atlas_tracker_contract'}, ...
    'mRLFE atlas API/test');

fprintf('\n[mRLFE atlas 1/10] direct atlas option alias contract test\n');
test_mrlfe_direct_visco_atlas_option_alias_contract;

fprintf('\n[mRLFE atlas 2/10] modal atlas ambiguity contract test\n');
test_mrlfe_modal_atlas_ambiguity_contract;

fprintf('\n[mRLFE atlas 3/10] S0 modal atlas contract test\n');
test_mrlfe_modal_atlas_s0_contract;

fprintf('\n[mRLFE atlas 4/10] atlas policy matrix contract test\n');
test_mrlfe_atlas_policy_matrix_contract;

fprintf('\n[mRLFE atlas 5/10] direct-visco branch policy contract test\n');
test_mrlfe_direct_visco_branch_policy_contract;

fprintf('\n[mRLFE atlas 6/10] delayed-visco modal cut contract test\n');
test_mrlfe_delayed_visco_modal_cut_contract;

fprintf('\n[mRLFE atlas 7/10] A0 delayed direct-visco opt-in contract test\n');
test_mrlfe_a0_delayed_direct_visco_opt_in_contract;

fprintf('\n[mRLFE atlas 8/10] A0 delayed direct-visco S0 guard contract test\n');
test_mrlfe_a0_delayed_direct_visco_s0_guard_contract;

fprintf('\n[mRLFE atlas 9/10] unified atlas route contract test\n');
test_mrlfe_unified_atlas_route_contract;

fprintf('\n[mRLFE atlas 10/10] S0 adaptive atlas tracker contract test\n');
test_mrlfe_s0_adaptive_atlas_tracker_contract;

fprintf('\nmRLFE atlas tests passed.\n');

function assertFunctionsOnPath(functionNames, label)
for i = 1:numel(functionNames)
    functionName = functionNames{i};
    assert(~isempty(which(functionName)), ...
        'Missing %s on MATLAB path: %s.', label, functionName);
end
end
