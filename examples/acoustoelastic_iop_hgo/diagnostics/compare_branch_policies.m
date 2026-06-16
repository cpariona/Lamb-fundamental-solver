clear; clc; close all;

%COMPARE_BRANCH_POLICIES Short AE IOP/HGO branch-policy comparison entrypoint.

thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
scriptPath = fullfile(thisFolder, 'compare_acoustoelastic_iop_hgo_branch_policies.m');
aeRunLegacyScript(scriptPath);
