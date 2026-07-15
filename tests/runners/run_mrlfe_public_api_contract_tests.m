clear; clc;
startup

% Public defaults and validation contracts without a numerical solve.
fprintf('\nRunning mRLFE public API contract tests...\n');
fprintf('------------------------------------------\n');

test_mrlfe_public_contract_defaults;
test_mrlfe_public_contract_validation;
fprintf('\nmRLFE public API contract tests passed.\n');
