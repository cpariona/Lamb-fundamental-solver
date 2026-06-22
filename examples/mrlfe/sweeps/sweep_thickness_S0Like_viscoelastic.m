clear; clc; close all;
startup

[sweepResults, sweepSummary] = mrlfeRunSweepExample('thickness', 'S0Like', 'AssignToBase', true, 'WriteOutputs', true);
