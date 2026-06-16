clear; clc; close all;

%DIAGNOSE_SWEEP_RELIABILITY Short AE IOP/HGO sweep-reliability diagnostic entrypoint.

thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
scriptPath = fullfile(thisFolder, 'diagnose_acoustoelastic_iop_hgo_sweep_reliability.m');
aeRunLegacyScript(scriptPath);
