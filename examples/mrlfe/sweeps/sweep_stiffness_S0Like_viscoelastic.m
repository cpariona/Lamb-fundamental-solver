clear; clc; close all;
startup

% Sweep example:
% Effect of Young's modulus E on the viscoelastic S0-like mRLFE branch.

[sweepResults, sweepSummary] = mrlfeRunSweepExample('stiffness', 'S0Like', 'AssignToBase', true);
