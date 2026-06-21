clear; clc; close all;
startup

[sweepResults, sweepSummary] = mrlfeRunSweepExample('stiffness', 'A0Like', 'AssignToBase', true);
