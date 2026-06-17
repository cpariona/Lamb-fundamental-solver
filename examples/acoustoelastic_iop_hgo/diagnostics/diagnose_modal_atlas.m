clear; clc; close all;

%DIAGNOSE_MODAL_ATLAS Short AE IOP/HGO modal-atlas diagnostic entrypoint.

launchFolder = pwd;
thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
scriptPath = fullfile(thisFolder, 'diagnose_acoustoelastic_iop_hgo_modal_atlas.m');
aeRunLegacyScript(scriptPath);
aeCopyLegacyResultFolder(launchFolder, ...
    'acoustoelastic_iop_hgo_modal_atlas', ...
    'modal_atlas', ...
    'acoustoelastic_iop_hgo_modal_atlas', ...
    'modal_atlas');
