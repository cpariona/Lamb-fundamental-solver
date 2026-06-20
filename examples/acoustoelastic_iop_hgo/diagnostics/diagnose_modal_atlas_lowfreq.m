clear; clc; close all;

%DIAGNOSE_MODAL_ATLAS_LOWFREQ Short AE IOP/HGO low-frequency modal-atlas diagnostic entrypoint.
%
% Delegates to the descriptive low-frequency modal-atlas implementation. The
% implementation writes to Results/ae_iop_hgo/modal_atlas_lowfreq relative to
% the MATLAB launch folder.

launchFolder = pwd;
originalPath = path;
originalFolder = pwd;
thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);

pathCleanup = onCleanup(@() path(originalPath));
folderCleanup = onCleanup(@() cd(originalFolder)); %#ok<NASGU>
addpath(thisFolder);
cd(launchFolder);

diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas;
