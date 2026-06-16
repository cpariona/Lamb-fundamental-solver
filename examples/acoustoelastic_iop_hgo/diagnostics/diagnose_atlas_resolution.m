clear; clc; close all;

%DIAGNOSE_ATLAS_RESOLUTION Short AE IOP/HGO atlasA0 resolution-sensitivity diagnostic entrypoint.

thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
scriptPath = fullfile(thisFolder, 'diagnose_acoustoelastic_iop_hgo_atlasA0_resolution_sensitivity.m');
aeRunLegacyScript(scriptPath);
