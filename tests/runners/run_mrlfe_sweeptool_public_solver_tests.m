clear; clc;
startup

fprintf('\nRunning mRLFE SweepTool public-solver migration tests...\n');
fprintf('-------------------------------------------------------\n');

test_mrlfe_sweep_uses_public_solver;
test_mrlfe_sweep_point_characterization;
test_mrlfe_sweep_metadata_and_mapping;

fprintf('\nmRLFE SweepTool public-solver migration tests passed.\n');
