clear; clc; close all;
launchFolder = pwd;
scriptFile = mfilename('fullpath');
startup

%MRLFE_SWEEP_THICKNESS_A0LIKE Maintained full-thickness sweep for mRLFE A0-like.
%
% Tables/workspace are written to:
%   Results/mrlfe/thickness_sweep
%
% Figures are written next to this script under:
%   figures/thickness_sweep

[sweepResults, sweepSummary, fig, outputFolder, figureFolder] = mrlfeRunSweepExample( ...
    'thickness', 'A0Like', ...
    'AssignToBase', true, ...
    'WriteOutputs', true, ...
    'LaunchFolder', launchFolder, ...
    'ScriptFile', scriptFile);

fprintf('\nBranch summary\n');
disp(sweepSummary);
fprintf('\nData files written to:\n%s\n', outputFolder);
fprintf('Figure files written to:\n%s\n', figureFolder);
