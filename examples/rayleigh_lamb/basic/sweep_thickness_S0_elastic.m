clear; clc; close all;
launchFolder = pwd;
scriptFile = mfilename('fullpath');
startup

[sweepResults, sweepSummary, fig, outputFolder, figureFolder] = rlRunSweepExample( ...
    'thickness', 'S0', ...
    'AssignToBase', true, ...
    'WriteOutputs', true, ...
    'LaunchFolder', launchFolder, ...
    'ScriptFile', scriptFile);

disp(sweepSummary);
fprintf('\nData files written to:\n%s\n', outputFolder);
fprintf('Figure files written to:\n%s\n', figureFolder);

assignin('base', 'RayleighLambThicknessSweepS0Figure', fig);
