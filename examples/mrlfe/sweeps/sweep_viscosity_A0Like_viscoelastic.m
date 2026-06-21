clear; clc; close all;
startup

% Sweep example:
% Effect of shear viscosity etaS on the viscoelastic A0-like mRLFE branch.

[sweepResults, sweepSummary] = mrlfeRunSweepExample( ...
    "viscosity", ...
    "A0Like", ...
    "AssignToBase", true);
