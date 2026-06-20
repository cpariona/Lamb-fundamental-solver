clear; clc; close all;

%DIAGNOSE_MODAL_ATLAS Short AE IOP/HGO modal-atlas diagnostic entrypoint.
%
% Delegates to the descriptive modal-atlas implementation. The implementation
% now writes directly to Results/ae_iop_hgo/modal_atlas.

thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
run(fullfile(thisFolder, 'diagnose_acoustoelastic_iop_hgo_modal_atlas.m'));
