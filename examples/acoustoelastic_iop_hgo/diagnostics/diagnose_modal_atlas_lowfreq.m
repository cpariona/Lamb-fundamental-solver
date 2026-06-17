clear; clc; close all;

%DIAGNOSE_MODAL_ATLAS_LOWFREQ Short AE IOP/HGO low-frequency modal-atlas diagnostic entrypoint.

launchFolder = pwd;
thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
scriptPath = fullfile(thisFolder, 'diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas.m');
aeRunLegacyScript(scriptPath);
aeCopyLegacyResultFolder(launchFolder, ...
    'acoustoelastic_iop_hgo_low_frequency_modal_atlas', ...
    'modal_atlas_lowfreq', ...
    'acoustoelastic_iop_hgo_low_frequency_modal_atlas', ...
    'modal_atlas_lowfreq');
