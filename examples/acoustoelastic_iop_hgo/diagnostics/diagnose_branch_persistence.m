clear; clc; close all;

%DIAGNOSE_BRANCH_PERSISTENCE Short AE IOP/HGO branch-persistence diagnostic entrypoint.

thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
scriptPath = fullfile(thisFolder, 'diagnose_acoustoelastic_iop_hgo_branch_persistence_refinement.m');
aeRunLegacyScript(scriptPath);
