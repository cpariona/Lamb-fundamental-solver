% Sweep thickness and compute A0/S0 phase velocity curves.
% S0 is currently experimental and should be benchmarked before use.

startup();

[sweepResults, a0Summary, s0Summary] = rlRunThicknessSweepExample('AssignToBase', true);
