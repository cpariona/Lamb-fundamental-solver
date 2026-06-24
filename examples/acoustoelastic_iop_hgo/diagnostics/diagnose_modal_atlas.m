clear; clc; close all;

%DIAGNOSE_MODAL_ATLAS Short AE IOP/HGO modal-atlas diagnostic entrypoint.
%
% Delegates to the descriptive modal-atlas implementation. The implementation
% writes to Results/ae_iop_hgo/modal_atlas relative to the MATLAB launch folder.

thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
scriptPath = fullfile(thisFolder, 'diagnose_acoustoelastic_iop_hgo_modal_atlas.m');
aeRunLegacyScript(scriptPath);
