clear; clc; close all;

%DIAGNOSE_MODAL_ATLAS_LOWFREQ Short AE IOP/HGO low-frequency modal-atlas diagnostic entrypoint.
% Suppresses a benign MATLAB graphics layout warning emitted by colorbar
% rendering on log-scaled imagesc axes in the legacy plotting helper.

launchFolder = pwd;
thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
scriptPath = fullfile(thisFolder, 'diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas.m');
warningState = warning('query', 'MATLAB:Axes:NegativeLimitsIgnored');
warning('off', 'MATLAB:Axes:NegativeLimitsIgnored');
cleanupObj = onCleanup(@() warning(warningState.state, 'MATLAB:Axes:NegativeLimitsIgnored'));
aeRunLegacyScript(scriptPath);
clear cleanupObj

aeCopyLegacyResultFolder(launchFolder, ...
    'acoustoelastic_iop_hgo_low_frequency_modal_atlas', ...
    'modal_atlas_lowfreq', ...
    'acoustoelastic_iop_hgo_low_frequency_modal_atlas', ...
    'modal_atlas_lowfreq');
