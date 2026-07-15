clear; clc;
startup

% Multi-minute public-route characterization, excluded from quick tiers.
fprintf('\nRunning mRLFE public contract characterization...\n');
fprintf('-----------------------------------------------\n');

test_mrlfe_public_contract_characterization;

fprintf('\nmRLFE public contract characterization passed.\n');
