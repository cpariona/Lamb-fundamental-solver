clear; clc;
repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
run(fullfile(repoRoot, 'tests', 'runners', 'run_fit_validation_tests.m'));
