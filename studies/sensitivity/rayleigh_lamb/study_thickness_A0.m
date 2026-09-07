clear; clc; close all;
launchFolder = pwd;
scriptFile = mfilename('fullpath');
repoRoot = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
addpath(repoRoot);
addpath(fullfile(repoRoot, 'studies'));
configureStudyPath(repoRoot);

%RL_SWEEP_THICKNESS_A0 Maintained full-thickness sweep for Rayleigh-Lamb A0.
%
% Tables/workspace are written to:
%   Results/rayleigh_lamb/thickness_sweep
%
% Figures are written next to this script under:
%   figures/thickness_sweep

[sweepResults, sweepSummary, fig, outputFolder, figureFolder] = runRayleighLambSensitivity( ...
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
