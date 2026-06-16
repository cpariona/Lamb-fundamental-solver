clear; clc; close all;

%DIAGNOSE_ATLAS_TRUNCATION Short AE IOP/HGO atlasA0 truncation-cause diagnostic entrypoint.

thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
scriptPath = fullfile(thisFolder, 'diagnose_acoustoelastic_iop_hgo_atlasA0_truncation_cause.m');
aeRunLegacyScript(scriptPath);
