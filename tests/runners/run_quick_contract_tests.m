clear; clc;
if isempty(which('mrlfeSolve')), startup; end

fprintf('\nRunning quick contract validation...\n');
fprintf('------------------------------------\n');

test_model_output_folder_helpers;
test_fitting_helpers_smoke;
test_shared_fit_optimizer_contract;
test_parametric_sweep_workflow;
test_rl_result_contract;
test_gui_execution_profile_normalization;
test_model_execution_profile_resolvers;
test_execution_profile_normalization_contract;
test_execution_profile_surface_metadata;
test_execution_profile_state_transition_contract;
test_fit_tool_interaction_helpers;
test_main_gui_export_contract;
test_mrlfe_public_contract_defaults;
test_mrlfe_public_contract_validation;

importResults = runtests({ ...
    which('test_gui_read_experimental_fit_file'), ...
    which('test_gui_prepare_experimental_fit_data')});
disp(table(importResults));
assertSuccess(importResults);

fprintf('\nQuick contract validation passed.\n');
