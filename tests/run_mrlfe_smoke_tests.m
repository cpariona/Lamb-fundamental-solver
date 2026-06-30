clear; clc;
repoRoot = fileparts(fileparts(mfilename('fullpath')));
run(fullfile(repoRoot, 'tests', 'runners', 'run_mrlfe_smoke_tests.m'));
