clear; clc; close all;

%VALIDATE_IDA0_SCORE_GRID Short entrypoint for branch-identity score grid validation.

thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
scriptPath = fullfile(thisFolder, 'validate_acoustoelastic_iop_hgo_branch_identity_score_grid.m');
aeRunLegacyScript(scriptPath);
