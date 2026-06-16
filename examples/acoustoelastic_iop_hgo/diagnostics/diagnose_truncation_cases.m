clear; clc; close all;

%DIAGNOSE_TRUNCATION_CASES Short AE IOP/HGO truncation-cases diagnostic entrypoint.

thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
scriptPath = fullfile(thisFolder, 'diagnose_acoustoelastic_iop_hgo_truncation_cases.m');
aeRunLegacyScript(scriptPath);
