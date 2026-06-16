clear; clc; close all;

%SWEEP_IOP Short AE IOP/HGO IOP sweep entrypoint.

thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
scriptPath = fullfile(thisFolder, 'sweep_acoustoelastic_iop_hgo_iop.m');
aeRunLegacyScript(scriptPath);
