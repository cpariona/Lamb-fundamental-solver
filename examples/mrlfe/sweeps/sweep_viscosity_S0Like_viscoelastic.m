clear; clc; close all;
startup

[sweepResults, sweepSummary] = mrlfeRunSweepExample('viscosity', 'S0Like', 'AssignToBase', true);
