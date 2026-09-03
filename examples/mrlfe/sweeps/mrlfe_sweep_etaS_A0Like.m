clear; clc; close all;
launchFolder = pwd;
scriptFile = mfilename('fullpath');
addpath(fileparts(fileparts(fileparts(fileparts(mfilename('fullpath'))))));
startup;

%MRLFE_SWEEP_ETAS_A0LIKE Maintained shear-viscosity sweep for mRLFE A0-like.
%
% Tables/workspace are written to:
%   Results/mrlfe/etaS_sweep
%
% Figures are written next to this script under:
%   figures/etaS_sweep

[sweepResults, sweepSummary, fig, outputFolder, figureFolder] = mrlfeRunSweep( ...
    'viscosity', 'A0Like', ...
    'AssignToBase', true, ...
    'WriteOutputs', true, ...
    'LaunchFolder', launchFolder, ...
    'ScriptFile', scriptFile);

fprintf('\nBranch summary\n');
disp(sweepSummary);
fprintf('\nData files written to:\n%s\n', outputFolder);
fprintf('Figure files written to:\n%s\n', figureFolder);
