clear; clc; close all;
launchFolder = pwd;
scriptFile = mfilename('fullpath');
startup

%SWEEP_MRLFE_SHEAR_VISCOSITY_PHASE_VELOCITY Compatibility wrapper.
%
% This legacy entrypoint is retained temporarily, but it now delegates to the
% maintained mRLFE full-thickness sweep workflow. The active sweep is:
%
%   2h = [0.3, 0.4, 0.5, 0.6, 0.7] mm
%
% with fixed:
%
%   mu = 75 kPa
%   etaS = 0.05 Pa*s
%
% Tables/workspace are written to:
%   Results/mrlfe/thickness_sweep
%
% Figures are written next to this script under:
%   figures/thickness_sweep

[a0SweepResults, a0SweepSummary, a0Fig, outputFolder, a0FigureFolder] = mrlfeRunSweepExample( ...
    'thickness', 'A0Like', ...
    'AssignToBase', true, ...
    'WriteOutputs', true, ...
    'LaunchFolder', launchFolder, ...
    'ScriptFile', scriptFile);

[s0SweepResults, s0SweepSummary, s0Fig, ~, s0FigureFolder] = mrlfeRunSweepExample( ...
    'thickness', 'S0Like', ...
    'AssignToBase', true, ...
    'WriteOutputs', true, ...
    'LaunchFolder', launchFolder, ...
    'ScriptFile', scriptFile);

fprintf('\nA0-like branch summary\n');
disp(a0SweepSummary);
fprintf('\nS0-like branch summary\n');
disp(s0SweepSummary);
fprintf('\nData files written to:\n%s\n', outputFolder);
fprintf('A0-like figure files written to:\n%s\n', a0FigureFolder);
fprintf('S0-like figure files written to:\n%s\n', s0FigureFolder);

assignin('base', 'MRLFEThicknessSweepA0LikeResults', a0SweepResults);
assignin('base', 'MRLFEThicknessSweepA0LikeSummary', a0SweepSummary);
assignin('base', 'MRLFEThicknessSweepS0LikeResults', s0SweepResults);
assignin('base', 'MRLFEThicknessSweepS0LikeSummary', s0SweepSummary);
assignin('base', 'MRLFEThicknessSweepA0LikeFigure', a0Fig);
assignin('base', 'MRLFEThicknessSweepS0LikeFigure', s0Fig);
assignin('base', 'MRLFEThicknessSweepOutputFolder', outputFolder);
