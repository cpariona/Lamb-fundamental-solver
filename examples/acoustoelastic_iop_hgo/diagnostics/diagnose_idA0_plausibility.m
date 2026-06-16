clear; clc; close all;

%DIAGNOSE_IDA0_PLAUSIBILITY Concise entrypoint for identityA0 plausibility diagnostic.

thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
legacyScript = fullfile(thisFolder, 'diagnose_acoustoelastic_iop_hgo_identityA0_physical_plausibility.m');
aeRunLegacyScript(legacyScript);
