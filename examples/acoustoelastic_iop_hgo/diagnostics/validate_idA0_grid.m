clear; clc; close all;

%VALIDATE_IDA0_GRID Short entrypoint for identityA0Diagnostic grid validation.

thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
legacyScript = fullfile(thisFolder, 'validate_acoustoelastic_iop_hgo_identityA0_diagnostic_grid.m');
aeRunLegacyScript(legacyScript);
