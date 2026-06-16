clear; clc; close all;

%DIAGNOSE_IDENTITYA0_PLAUSIBILITY Short MATLAB-compatible entrypoint.
% Prefer diagnose_idA0_plausibility for new calls.

thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
legacyScript = fullfile(thisFolder, 'diagnose_acoustoelastic_iop_hgo_identityA0_physical_plausibility.m');
aeRunLegacyScript(legacyScript);
