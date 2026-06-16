clear; clc; close all;

%DIAGNOSE_IDA0_SCORE Short AE IOP/HGO branch-identity score diagnostic entrypoint.

thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
scriptPath = fullfile(thisFolder, 'diagnose_acoustoelastic_iop_hgo_branch_identity_score.m');
aeRunLegacyScript(scriptPath);
