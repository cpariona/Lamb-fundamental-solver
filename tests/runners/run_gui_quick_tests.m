clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

% GUI helper/state contracts and representative adapter smoke checks only.
fprintf('\nRunning quick GUI tests...\n');
fprintf('--------------------------\n');

test_gui_struct_helpers_contract;
test_fit_parameter_state_contract;
test_fit_parameter_execution_contract;
test_gui_normalized_adapters_smoke;
run_main_gui_export_tests;
test_gui_sweep_adapters_smoke;
test_gui_sweep_model_configuration_smoke;
test_gui_acoustoelastic_iop_hgo_sweep_adapter_smoke;
test_gui_acoustoelastic_iop_hgo_main_adapter_smoke;
test_ae_workflow_route_ownership;
test_gui_fit_model_configuration_contract;
test_fit_tool_model_configuration_contract;

fprintf('\nQuick GUI tests passed.\n');
