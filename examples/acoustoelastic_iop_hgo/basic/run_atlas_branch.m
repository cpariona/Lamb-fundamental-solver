clear; clc; close all;

%RUN_ATLAS_BRANCH Short AE IOP/HGO atlas branch example entrypoint.

thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
scriptPath = fullfile(thisFolder, 'run_acoustoelastic_iop_hgo_atlas_branch.m');
aeRunLegacyScript(scriptPath);
