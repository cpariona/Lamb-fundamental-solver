clear; clc; close all;

%DIAGNOSE_IDA0_PLAUSIBILITY Concise entrypoint for identityA0 plausibility diagnostic.

thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
legacyScript = fullfile(thisFolder, 'diagnose_idA0_plausibility_impl.m');
aeRunLegacyScript(legacyScript);
