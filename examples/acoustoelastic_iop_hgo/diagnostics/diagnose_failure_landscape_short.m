clear; clc; close all;

%DIAGNOSE_FAILURE_LANDSCAPE_SHORT Short AE IOP/HGO failure-landscape diagnostic entrypoint.

thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
scriptPath = fullfile(thisFolder, 'diagnose_acoustoelastic_iop_hgo_failure_landscape.m');
aeRunLegacyScript(scriptPath);
