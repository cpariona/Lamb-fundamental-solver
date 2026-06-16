clear; clc; close all;

%DIAGNOSE_BRANCH_POLICY Short AE IOP/HGO branch-policy diagnostic entrypoint.

thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
scriptPath = fullfile(thisFolder, 'diagnose_acoustoelastic_iop_hgo_branch_policy.m');
aeRunLegacyScript(scriptPath);
