clear; clc; close all;
startup

[sweepResults, sweepSummary] = mrlfeRunSweepExample('thickness', 'A0Like', 'AssignToBase', true);
