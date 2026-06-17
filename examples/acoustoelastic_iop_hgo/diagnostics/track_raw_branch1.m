clear; clc; close all;

%TRACK_RAW_BRANCH1 Short AE IOP/HGO raw branch-1 tracking diagnostic entrypoint.

thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
scriptPath = fullfile(thisFolder, 'track_acoustoelastic_iop_hgo_raw_branch1_candidate.m');
aeRunLegacyScript(scriptPath);
