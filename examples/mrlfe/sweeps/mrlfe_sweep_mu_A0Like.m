clear; clc; close all;
launchFolder = pwd;
scriptFile = mfilename('fullpath');
startup

%MRLFE_SWEEP_MU_A0LIKE Maintained shear-modulus sweep for mRLFE A0-like.
%
% Tables/workspace are written to:
%   Results/mrlfe/mu_sweep
%
% Figures are written next to this script under:
%   figures/mu_sweep

[sweepResults, sweepSummary, fig, outputFolder, figureFolder] = mrlfeRunSweep( ...
    'mu', 'A0Like', ...
    'AssignToBase', true, ...
    'WriteOutputs', true, ...
    'LaunchFolder', launchFolder, ...
    'ScriptFile', scriptFile);

fprintf('\nBranch summary\n');
disp(sweepSummary);
fprintf('\nData files written to:\n%s\n', outputFolder);
fprintf('Figure files written to:\n%s\n', figureFolder);
