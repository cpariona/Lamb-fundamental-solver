clear; clc;
startup

% Recommended routine validation: contracts plus small model/surface executions.
fprintf('\nRunning quick smoke validation...\n');
fprintf('---------------------------------\n');

run_quick_contract_tests;
run_gui_quick_tests;
run_ae_quick_tests;
run_mrlfe_smoke_tests;

fprintf('\nQuick smoke validation passed.\n');
