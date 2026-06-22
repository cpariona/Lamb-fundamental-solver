clear; clc; close all;
launchFolder = pwd;
scriptFile = mfilename('fullpath');
startup

%SWEEP_THICKNESS_A0_ELASTIC Maintained full-thickness sweep for Rayleigh-Lamb A0.
%
% Tables/workspace are written to:
%   Results/rayleigh_lamb/thickness_sweep
%
% Figures are written next to this script under:
%   figures/thickness_sweep

[sweepResults, sweepSummary, fig, outputFolder, figureFolder] = rlRunSweepExample( ...
    'thickness', 'A0', ...
    'AssignToBase', true, ...
    'WriteOutputs', true, ...
    'LaunchFolder', launchFolder, ...
    'ScriptFile', scriptFile);

fprintf('\nA0 branch summary\n');
disp(sweepSummary);
fprintf('\nData files written to:\n%s\n', outputFolder);
fprintf('Figure files written to:\n%s\n', figureFolder);

assignin('base', 'RayleighLambThicknessSweepA0Figure', fig);
