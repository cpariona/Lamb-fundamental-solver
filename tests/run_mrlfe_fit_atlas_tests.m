clear; clc;
repoRoot = fileparts(fileparts(mfilename('fullpath')));
run(fullfile(repoRoot, 'tests', 'runners', 'run_mrlfe_fit_atlas_tests.m'));
