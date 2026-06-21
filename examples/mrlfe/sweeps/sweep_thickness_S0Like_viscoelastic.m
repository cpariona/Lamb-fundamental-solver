clear; clc; close all;
startup

% Sweep example:
% Effect of layer thickness on the viscoelastic S0-like mRLFE branch.

[sweepResults, sweepSummary] = mrlfeRunSweepExample('thickness', 'S0Like', 'AssignToBase', true);
