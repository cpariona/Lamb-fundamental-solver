clear; clc;
startup

% Solver-backed public result-schema validation is numerical, not structural.
fprintf('\nRunning mRLFE public result contract...\n');
fprintf('---------------------------------------\n');

test_mrlfe_public_contract_result_schema;

fprintf('\nmRLFE public result contract passed.\n');
