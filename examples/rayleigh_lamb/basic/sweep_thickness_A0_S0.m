clear; clc; close all;
launchFolder = pwd;
scriptFile = mfilename('fullpath');
startup

%SWEEP_THICKNESS_A0_S0 Maintained full-thickness sweep for Rayleigh-Lamb A0/S0.
%
% Tables/workspace are written to:
%   Results/rayleigh_lamb/thickness_sweep
%
% Figures are written next to this script under:
%   figures/thickness_sweep

[sweepResults, a0Summary, s0Summary, a0Fig, s0Fig, outputFolder, figureFolder] = rlRunThicknessSweepExample( ...
    'AssignToBase', true, ...
    'WriteOutputs', true, ...
    'LaunchFolder', launchFolder, ...
    'ScriptFile', scriptFile);

fprintf('\nA0 branch summary\n');
disp(a0Summary);
fprintf('\nS0 branch summary\n');
disp(s0Summary);
fprintf('\nData files written to:\n%s\n', outputFolder);
fprintf('Figure files written to:\n%s\n', figureFolder);

assignin('base', 'RayleighLambThicknessSweepA0Figure', a0Fig);
assignin('base', 'RayleighLambThicknessSweepS0Figure', s0Fig);
