clear; clc; close all;

%SWEEP_MU Short AE IOP/HGO shear-modulus sweep entrypoint.

thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
scriptPath = fullfile(thisFolder, 'sweep_acoustoelastic_iop_hgo_mu.m');
aeRunLegacyScript(scriptPath);
