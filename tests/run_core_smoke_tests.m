clear; clc;
repoRoot = fileparts(fileparts(mfilename('fullpath')));
run(fullfile(repoRoot, 'tests', 'runners', 'run_core_smoke_tests.m'));
