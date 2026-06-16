clear; clc; close all;

%DIAGNOSE_IDENTITYA0_PLAUSIBILITY Short MATLAB-compatible entrypoint.
%
% MATLAB only recognizes function/script names up to namelengthmax characters.
% The descriptive identityA0 plausibility diagnostic filename is longer than
% that limit, so this wrapper executes it by explicit file path.

thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
longScript = fullfile(thisFolder, 'diagnose_acoustoelastic_iop_hgo_identityA0_physical_plausibility.m');

if ~exist(longScript, 'file')
    error('Expected diagnostic script not found: %s', longScript);
end

run(longScript);
