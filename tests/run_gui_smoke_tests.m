clear; clc;
repoRoot = fileparts(fileparts(mfilename('fullpath')));
run(fullfile(repoRoot, 'tests', 'runners', 'run_gui_smoke_tests.m'));
