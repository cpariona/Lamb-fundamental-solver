clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

% Preserve the historical broad command by aggregating canonical contract,
% characterization, and performance owners.

fprintf('\nRunning mRLFE production core tests...\n');
fprintf('------------------------------------\n');

run_mrlfe_production_core_contract_tests;
run_mrlfe_production_core_extended_tests;
run_mrlfe_production_core_performance_tests;

fprintf('\nmRLFE production core tests passed.\n');
