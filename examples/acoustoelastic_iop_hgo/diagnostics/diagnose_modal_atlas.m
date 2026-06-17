clear; clc; close all;

%DIAGNOSE_MODAL_ATLAS Short AE IOP/HGO modal-atlas diagnostic entrypoint.

thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
scriptPath = fullfile(thisFolder, 'diagnose_acoustoelastic_iop_hgo_modal_atlas.m');
aeRunLegacyScript(scriptPath);
