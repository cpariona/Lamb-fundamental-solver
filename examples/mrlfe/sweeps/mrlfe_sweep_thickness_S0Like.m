clear; clc; close all;
launchFolder = pwd;
scriptFile = mfilename('fullpath');
startup

[sweepResults, sweepSummary, fig, outputFolder, figureFolder] = mrlfeRunSweep('thickness', 'S0Like', 'AssignToBase', true, 'WriteOutputs', true, 'LaunchFolder', launchFolder, 'ScriptFile', scriptFile);
