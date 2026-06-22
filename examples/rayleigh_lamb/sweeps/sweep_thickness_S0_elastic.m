clear; clc; close all;
launchFolder = pwd;
scriptFile = mfilename('fullpath');
startup

%SWEEP_THICKNESS_S0_ELASTIC Maintained full-thickness sweep for Rayleigh-Lamb S0.
%
% Tables/workspace are written to:
%   Results/rayleigh_lamb/thickness_sweep
%
% Figures are written next to this script under:
%   figures/thickness_sweep

[sweepResults, sweepSummary, fig, outputFolder, figureFolder] = rlRunSweepExample( ...
    'thickness', 'S0', ...
    'AssignToBase', true, ...
    'WriteOutputs', true, ...
    'LaunchFolder', launchFolder, ...
    'ScriptFile', scriptFile);

fprintf('\nS0 branch summary\n');
disp(sweepSummary);
fprintf('\nData files written to:\n%s\n', outputFolder);
fprintf('Figure files written to:\n%s\n', figureFolder);

assignin('base', 'RayleighLambThicknessSweepS0Figure', fig);
